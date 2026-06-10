import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/personal_record.dart';
import '../services/workout_repository.dart';
import 'supabase_providers.dart';

/// State for personal records
class PersonalRecordsState {
  final List<PersonalRecord> records;
  final PersonalRecordStats? stats;
  final bool isLoading;
  final String? error;
  final PersonalRecord? lastNewRecord;
  final bool showCelebration;

  const PersonalRecordsState({
    this.records = const [],
    this.stats,
    this.isLoading = false,
    this.error,
    this.lastNewRecord,
    this.showCelebration = false,
  });

  PersonalRecordsState copyWith({
    List<PersonalRecord>? records,
    PersonalRecordStats? stats,
    bool? isLoading,
    String? error,
    PersonalRecord? lastNewRecord,
    bool? showCelebration,
  }) {
    return PersonalRecordsState(
      records: records ?? this.records,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastNewRecord: lastNewRecord ?? this.lastNewRecord,
      showCelebration: showCelebration ?? this.showCelebration,
    );
  }

  /// Get records grouped by muscle group (requires exercise data)
  Map<String, List<PersonalRecord>> getRecordsByMuscleGroup(
    Map<String, String> exerciseMuscleGroups,
  ) {
    final Map<String, List<PersonalRecord>> grouped = {};
    for (final record in records) {
      final muscleGroup = exerciseMuscleGroups[record.exerciseId] ?? 'Other';
      grouped.putIfAbsent(muscleGroup, () => []);
      grouped[muscleGroup]!.add(record);
    }
    return grouped;
  }

  /// Get recent records (last 30 days)
  List<PersonalRecord> get recentRecords {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return records.where((r) => r.achievedAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
  }

  /// Get top records by estimated 1RM
  List<PersonalRecord> get topRecords {
    return List.from(records)
      ..sort((a, b) => b.estimatedOneRepMax.compareTo(a.estimatedOneRepMax));
  }
}

/// Notifier for managing personal records
class PersonalRecordsNotifier extends StateNotifier<PersonalRecordsState> {
  final WorkoutRepository _repository;
  static const _prefsKey = 'personal_records';

  PersonalRecordsNotifier(this._repository) : super(const PersonalRecordsState());

  /// Load records: DB is the source of truth, local cache is fallback.
  Future<void> fetchRecords() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // 1. Always fetch from DB first (cross-device sync)
      List<PersonalRecord> records = [];
      try {
        final recordsData = await _repository.fetchPersonalRecords();
        records = recordsData.map((data) => PersonalRecord.fromJson(data)).toList();
        // Overwrite local cache with authoritative DB data
        await _saveLocal(records);
      } catch (_) {
        // DB unavailable – fall back to local cache only
        final prefs = await SharedPreferences.getInstance();
        final localData = prefs.getString(_prefsKey);
        if (localData != null) {
          try {
            final List<dynamic> decoded = jsonDecode(localData);
            records = decoded
                .map((d) => PersonalRecord.fromJson(d as Map<String, dynamic>))
                .where((r) => r.id.length > 10) // skip temp timestamp IDs that were never synced
                .toList();
          } catch (_) {
            records = [];
          }
        }
      }
      
      final stats = _calculateStats(records);
      state = state.copyWith(records: records, stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load personal records: $e',
      );
    }
  }
  
  /// Save records to local SharedPreferences
  Future<void> _saveLocal(List<PersonalRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
    // ignore: avoid_print
    print('[PR DEBUG] Saved ${records.length} records to LOCAL storage');
  }
  
  /// Background sync: fetch from DB and merge with local
  Future<void> _syncFromDbInBackground() async {
    try {
      final recordsData = await _repository.fetchPersonalRecords();
      final dbRecords = recordsData.map((data) => PersonalRecord.fromJson(data)).toList();
      
      // Merge: keep the best PR for each exercise
      final merged = _mergeRecords(state.records, dbRecords);
      if (merged.length != state.records.length) {
        await _saveLocal(merged);
        final stats = _calculateStats(merged);
        state = state.copyWith(records: merged, stats: stats);
        // ignore: avoid_print
        print('[PR DEBUG] Background sync: merged ${dbRecords.length} DB records');
      }
    } catch (e) {
      // Silently fail - local data is primary
      // ignore: avoid_print
      print('[PR DEBUG] Background sync failed (non-critical): $e');
    }
  }
  
  /// Merge two record lists, keeping the best for each exercise
  List<PersonalRecord> _mergeRecords(List<PersonalRecord> local, List<PersonalRecord> db) {
    final Map<String, PersonalRecord> bestByExercise = {};
    
    for (final record in [...local, ...db]) {
      final existing = bestByExercise[record.exerciseId];
      if (existing == null) {
        bestByExercise[record.exerciseId] = record;
      } else {
        // Compare and keep best
        final existing1RM = existing.estimatedOneRepMax;
        final new1RM = record.estimatedOneRepMax;
        final existingIsBW = existing.weightKg == 0;
        final newIsBW = record.weightKg == 0;
        
        bool isBetter;
        if (existingIsBW && newIsBW) {
          isBetter = record.reps > existing.reps;
        } else if (!existingIsBW && !newIsBW) {
          isBetter = new1RM > existing1RM;
        } else {
          isBetter = !newIsBW; // Prefer weighted over BW
        }
        
        if (isBetter) {
          bestByExercise[record.exerciseId] = record;
        }
      }
    }
    
    return bestByExercise.values.toList();
  }

  /// Check if a specific weight/reps combo would be a PR (without saving)
  /// Only returns true if records are loaded AND this would actually be a new PR
  bool wouldBePersonalRecord({
    required String exerciseId,
    required double weightKg,
    required int reps,
  }) {
    // ignore: avoid_print
    print('[PR DEBUG] Checking: exercise=$exerciseId, weight=$weightKg, reps=$reps');
    // ignore: avoid_print
    print('[PR DEBUG] State: isLoading=${state.isLoading}, recordsCount=${state.records.length}');
    
    if (reps <= 0) {
      // ignore: avoid_print
      print('[PR DEBUG] Invalid reps, returning false');
      return false;
    }
    
    // For weighted exercises, weight must be > 0
    // For bodyweight exercises (weight == 0), only reps matter
    if (weightKg < 0) {
      // ignore: avoid_print
      print('[PR DEBUG] Invalid negative weight, returning false');
      return false;
    }
    
    // If still loading, don't show PR celebration yet
    if (state.isLoading) {
      // ignore: avoid_print
      print('[PR DEBUG] Still loading, returning false');
      return false;
    }
    
    final existingRecord = state.records.where((r) => r.exerciseId == exerciseId).firstOrNull;
    // ignore: avoid_print
    print('[PR DEBUG] Existing record: $existingRecord');
    
    // If no existing record, this would be the first PR
    if (existingRecord == null) {
      // ignore: avoid_print
      print('[PR DEBUG] No existing record, this is a first PR!');
      return true;
    }
    
    // For bodyweight exercises (weight <= 0), only reps matter
    if (weightKg <= 0) {
      final isPR = reps > existingRecord.reps;
      // ignore: avoid_print
      print('[PR DEBUG] BW exercise - New reps: $reps, Existing: ${existingRecord.reps}, Is PR: $isPR');
      return isPR;
    }
    
    final newEstimated1RM = weightKg * (1 + reps / 30);
    final existingEstimated1RM = existingRecord.estimatedOneRepMax;
    // ignore: avoid_print
    print('[PR DEBUG] New 1RM: $newEstimated1RM, Existing: $existingEstimated1RM');
    
    final isPR = newEstimated1RM > existingEstimated1RM;
    // ignore: avoid_print
    print('[PR DEBUG] Is PR: $isPR');
    return isPR;
  }

  /// Check if a set qualifies as a new personal record
  /// Returns the new record if it's a PR, null otherwise
  Future<PersonalRecord?> checkAndSavePotentialRecord({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int reps,
  }) async {
    if (reps <= 0 || weightKg < 0) return null;

    // Find existing PR for this exercise
    final existingRecord = state.records.where((r) => r.exerciseId == exerciseId).firstOrNull;
    
    bool isNewPR;
    if (weightKg == 0) {
      // For bodyweight exercises, only reps matter
      isNewPR = existingRecord == null || reps > existingRecord.reps;
    } else {
      // For weighted exercises, use 1RM calculation
      final newEstimated1RM = weightKg * (1 + reps / 30);
      final existingEstimated1RM = existingRecord?.estimatedOneRepMax ?? 0;
      isNewPR = newEstimated1RM > existingEstimated1RM;
    }
    
    if (isNewPR) {
      // This is a new PR!
      try {
        // Create new record locally first (so it's immediately available for next checks)
        final newRecord = PersonalRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          weightKg: weightKg,
          reps: reps,
          achievedAt: DateTime.now(),
        );
        
        // Update local state immediately
        final updatedRecords = [...state.records];
        final existingIndex = updatedRecords.indexWhere((r) => r.exerciseId == exerciseId);
        if (existingIndex >= 0) {
          updatedRecords[existingIndex] = newRecord;
        } else {
          updatedRecords.add(newRecord);
        }
        
        // Update local state immediately for responsive UI
        await _saveLocal(updatedRecords);
        
        state = state.copyWith(
          records: updatedRecords,
          lastNewRecord: newRecord,
          showCelebration: true,
        );
        
        // Save to DB (awaited so cross-device sync works)
        try {
          await _repository.savePersonalRecord(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            weightKg: weightKg,
            reps: reps,
          );
        } catch (_) {
          // DB save failed – local cache still has the record
        }
        
        return newRecord;
      } catch (e) {
        // Silently fail - PR saving is not critical
        return null;
      }
    }
    
    return null;
  }

  /// Dismiss the celebration overlay
  void dismissCelebration() {
    state = state.copyWith(showCelebration: false);
  }

  /// Calculate statistics from records
  PersonalRecordStats _calculateStats(List<PersonalRecord> records) {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    
    final newThisMonth = records.where((r) => r.achievedAt.isAfter(monthAgo)).length;
    final totalVolume = records.fold<double>(0, (sum, r) => sum + r.volume);
    
    // Find strongest exercise (by estimated 1RM)
    PersonalRecord? strongest;
    for (final record in records) {
      if (strongest == null || record.estimatedOneRepMax > strongest.estimatedOneRepMax) {
        strongest = record;
      }
    }
    
    // Calculate streak (consecutive weeks with at least one PR)
    final streak = _calculateStreak(records);
    
    return PersonalRecordStats(
      totalRecords: records.length,
      newRecordsThisMonth: newThisMonth,
      totalVolumeLifted: totalVolume,
      strongestExercise: strongest?.exerciseName,
      currentStreakWeeks: streak,
    );
  }

  int _calculateStreak(List<PersonalRecord> records) {
    if (records.isEmpty) return 0;
    
    // Sort by date descending
    final sorted = List<PersonalRecord>.from(records)
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));
    
    // Group by week
    final weeksWithPRs = <int>{};
    for (final record in sorted) {
      final weekNumber = _getWeekNumber(record.achievedAt);
      weeksWithPRs.add(weekNumber);
    }
    
    // Count consecutive weeks from most recent
    final currentWeek = _getWeekNumber(DateTime.now());
    int streak = 0;
    
    for (int i = 0; i <= 52; i++) {
      if (weeksWithPRs.contains(currentWeek - i)) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    return streak;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return daysSinceFirstDay ~/ 7;
  }
}

/// Provider for personal records
final personalRecordsProvider = StateNotifierProvider<PersonalRecordsNotifier, PersonalRecordsState>(
  (ref) => PersonalRecordsNotifier(ref.watch(workoutRepositoryProvider)),
);

/// Provider for recent records only
final recentPersonalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  return ref.watch(personalRecordsProvider).recentRecords;
});

/// Provider for top records only
final topPersonalRecordsProvider = Provider<List<PersonalRecord>>((ref) {
  return ref.watch(personalRecordsProvider).topRecords;
});
