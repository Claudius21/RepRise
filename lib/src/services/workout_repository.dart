import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  final SupabaseClient _client;

  WorkoutRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Convert exercise ID string to valid UUID v5
  /// This ensures consistent UUIDs for the same exercise ID
  String _exerciseIdToUuid(String exerciseId) {
    // Use a fixed namespace UUID for consistency
    const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // DNS namespace
    final data = utf8.encode('$namespace:$exerciseId');
    final hash = base64Url.encode(data).substring(0, 36);
    // Format as UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    return '${hash.substring(0, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}-${hash.substring(16, 20)}-${hash.substring(20, 32)}';
  }

  // ─── Plans ───────────────────────────────────────────────────

  Future<List<WorkoutPlan>> fetchPlans() async {
    final data = await _client
        .from('workout_plans')
        .select('''
          *,
          workout_days (
            *,
            day_exercises (
              *,
              exercises (*)
            )
          )
        ''')
        .eq('user_id', _uid)
        .order('created_at');

    return (data as List).map((e) => _planFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setActivePlan(String planId) async {
    await _client
        .from('workout_plans')
        .update({'is_active': false})
        .eq('user_id', _uid);
    await _client
        .from('workout_plans')
        .update({'is_active': true})
        .eq('id', planId);
  }

  // ─── Sessions ────────────────────────────────────────────────

  Future<List<WorkoutSession>> fetchSessions({int limit = 20}) async {
    final data = await _client
        .from('workout_sessions')
        .select('*, session_sets(*)')
        .eq('user_id', _uid)
        .order('started_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => _sessionFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> saveSession(WorkoutSession session) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      print('ERROR: No user logged in - cannot save session');
      throw Exception('User not authenticated');
    }
    
    print('Saving session for user: ${user.id}');
    print('Session: ${session.dayName}, volume: ${session.totalVolumeKg}');
    
    final result = await _client.from('workout_sessions').insert({
      'user_id': user.id,
      'plan_id': session.planId,
      'day_id': session.dayId,
      'day_name': session.dayName,
      'started_at': session.startedAt.toIso8601String(),
      'finished_at': session.finishedAt?.toIso8601String(),
      'status': session.status.name,
      'total_volume_kg': session.totalVolumeKg,
    }).select().single();
    
    print('Session saved with ID: ${result['id']}');

    final sessionId = result['id'] as String;

    // Save all sets (including uncompleted) so exercises are preserved
    final sets = <Map<String, dynamic>>[];
    for (final exercise in session.exercises) {
      for (final s in exercise.sets) {
        sets.add({
          'session_id': sessionId,
          if (_isUuid(exercise.id)) 'exercise_id': exercise.id,
          'exercise_name': exercise.name,
          'set_number': s.setNumber,
          'reps': s.actualReps ?? 0,
          'weight_kg': s.actualWeight ?? 0.0,
          'is_completed': s.isCompleted,
        });
      }
    }
    if (sets.isNotEmpty) {
      await _client.from('session_sets').insert(sets);
    }

    // Update personal records
    await _updatePersonalRecords(session);

    return sessionId;
  }

  Future<void> _updatePersonalRecords(WorkoutSession session) async {
    for (final exercise in session.exercises) {
      double maxWeight = 0;
      int maxReps = 0;
      for (final s in exercise.sets) {
        if (s.isCompleted && (s.actualWeight ?? 0) >= maxWeight) {
          maxWeight = s.actualWeight ?? 0;
          maxReps = s.actualReps ?? 0;
        }
      }
      if (maxWeight <= 0 && maxReps <= 0) continue;

      await _client.from('personal_records').upsert({
        'user_id': _uid,
        'exercise_id': exercise.name, // use name as stable key (no UUID dependency)
        'exercise_name': exercise.name,
        'weight_kg': maxWeight,
        'reps': maxReps,
        'achieved_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,exercise_id');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.from('session_sets').delete().eq('session_id', sessionId);
    await _client.from('workout_sessions').delete().eq('id', sessionId);
  }

  bool _isUuid(String s) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(s);

  Future<void> updateSessionSets(WorkoutSession session) async {
    if (!_isUuid(session.id)) {
      throw Exception('Session has not been saved to the server yet. Please finish a new workout first.');
    }
    print('updateSessionSets: deleting old sets for session ${session.id}');
    await _client.from('session_sets').delete().eq('session_id', session.id);
    final sets = <Map<String, dynamic>>[];
    for (final exercise in session.exercises) {
      for (final s in exercise.sets) {
        sets.add({
          'session_id': session.id,
          if (_isUuid(exercise.id)) 'exercise_id': exercise.id,
          'exercise_name': exercise.name,
          'set_number': s.setNumber,
          'reps': s.actualReps ?? 0,
          'weight_kg': s.actualWeight ?? 0.0,
          'is_completed': true,
        });
      }
    }
    print('updateSessionSets: inserting ${sets.length} sets');
    if (sets.isNotEmpty) await _client.from('session_sets').insert(sets);
    final totalVolume = sets.fold<double>(
      0, (sum, s) => sum + ((s['reps'] as int) * (s['weight_kg'] as double)));
    await _client.from('workout_sessions').update({
      'total_volume_kg': totalVolume.round(),
    }).eq('id', session.id);
    print('updateSessionSets: done');
  }

  /// Retroactively compute PRs from all session_sets and upsert into personal_records.
  /// Safe to call multiple times – uses upsert so it only updates if better.
  Future<int> rebuildPersonalRecordsFromHistory() async {
    final data = await _client
        .from('session_sets')
        .select('exercise_name, reps, weight_kg, is_completed, session_id')
        .eq('is_completed', true)
        .inFilter('session_id', await _getOwnSessionIds());

    final Map<String, Map<String, dynamic>> bestPerExercise = {};
    for (final row in data as List) {
      final name = row['exercise_name'] as String;
      final weight = (row['weight_kg'] as num).toDouble();
      final reps = (row['reps'] as num).toInt();
      if (reps <= 0) continue;
      final new1rm = weight * (1 + reps / 30);
      final existing = bestPerExercise[name];
      final existing1rm = existing != null
          ? (existing['weight_kg'] as double) * (1 + (existing['reps'] as int) / 30)
          : 0.0;
      if (new1rm > existing1rm) {
        bestPerExercise[name] = {'exercise_name': name, 'weight_kg': weight, 'reps': reps};
      }
    }

    for (final entry in bestPerExercise.entries) {
      final name = entry.key;
      final weight = entry.value['weight_kg'] as double;
      final reps = entry.value['reps'] as int;
      await _client.from('personal_records').upsert(
        {
          'user_id': _uid,
          'exercise_id': name,
          'exercise_name': name,
          'weight_kg': weight,
          'reps': reps,
          'achieved_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,exercise_id',
      );
    }
    return bestPerExercise.length;
  }

  Future<List<String>> _getOwnSessionIds() async {
    final data = await _client
        .from('workout_sessions')
        .select('id')
        .eq('user_id', _uid);
    return (data as List).map((e) => e['id'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> fetchPersonalRecords() async {
    final data = await _client
        .from('personal_records')
        .select()
        .eq('user_id', _uid)
        .order('achieved_at', ascending: false);
    final records = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    // ignore: avoid_print
    print('[REPO DEBUG] Fetched ${records.length} records: ${records.map((r) => '${r['exercise_name']}: ${r['weight_kg']}kg x ${r['reps']}').toList()}');
    return records;
  }

  Future<void> savePersonalRecord({
    required String exerciseId,
    required String exerciseName,
    required double weightKg,
    required int reps,
  }) async {
    // Use upsert with the original exerciseId directly (no UUID conversion)
    await _client.from('personal_records').upsert(
      {
        'user_id': _uid,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'weight_kg': weightKg,
        'reps': reps,
        'achieved_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,exercise_id',
    );
  }

  /// Cleanup duplicate personal records - keeps only the best one per exercise
  Future<void> cleanupDuplicatePRs() async {
    // ignore: avoid_print
    print('[PR CLEANUP] Starting cleanup...');
    
    // Get all records
    final allRecords = await _client
        .from('personal_records')
        .select()
        .eq('user_id', _uid)
        .order('achieved_at', ascending: false);
    
    // Group by exercise_id
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final record in allRecords) {
      final exerciseId = record['exercise_id'] as String;
      grouped.putIfAbsent(exerciseId, () => []);
      grouped[exerciseId]!.add(record);
    }
    
    // For each exercise, keep only the best record
    for (final entry in grouped.entries) {
      final records = entry.value;
      if (records.length <= 1) continue;
      
      // Find best record (highest 1RM for weighted, highest reps for BW)
      Map<String, dynamic> bestRecord = records.first;
      double best1RM = _calculate1RM(
        (bestRecord['weight_kg'] as num).toDouble(),
        bestRecord['reps'] as int,
      );
      
      for (int i = 1; i < records.length; i++) {
        final record = records[i];
        final weight = (record['weight_kg'] as num).toDouble();
        final reps = record['reps'] as int;
        final current1RM = _calculate1RM(weight, reps);
        
        // For BW exercises (weight == 0), compare reps only
        final isBW = weight == 0;
        final bestIsBW = (bestRecord['weight_kg'] as num).toDouble() == 0;
        
        bool isBetter;
        if (isBW && bestIsBW) {
          isBetter = reps > (bestRecord['reps'] as int);
        } else if (!isBW && !bestIsBW) {
          isBetter = current1RM > best1RM;
        } else {
          // Mixed (shouldn't happen), prefer weighted
          isBetter = !isBW;
        }
        
        if (isBetter) {
          bestRecord = record;
          best1RM = current1RM;
        }
      }
      
      // Delete all except best
      for (final record in records) {
        if (record['id'] != bestRecord['id']) {
          await _client.from('personal_records').delete().eq('id', record['id']);
          // ignore: avoid_print
          print('[PR CLEANUP] Deleted duplicate: ${record['exercise_name']} ${record['weight_kg']}kg x ${record['reps']}');
        }
      }
      // ignore: avoid_print
      print('[PR CLEANUP] Kept best: ${bestRecord['exercise_name']} ${bestRecord['weight_kg']}kg x ${bestRecord['reps']} (1RM: ${best1RM.toStringAsFixed(1)})');
    }
    
    // ignore: avoid_print
    print('[PR CLEANUP] Done!');
  }
  
  double _calculate1RM(double weight, int reps) {
    if (weight <= 0) return reps.toDouble(); // For BW, just use reps
    return weight * (1 + reps / 30);
  }

  // ─── JSON Mappers ─────────────────────────────────────────────

  WorkoutPlan _planFromJson(Map<String, dynamic> json) {
    final days = (json['workout_days'] as List? ?? [])
        .map((d) => _dayFromJson(d as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      durationWeeks: json['duration_weeks'] as int? ?? 8,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      days: days,
    );
  }

  WorkoutDay _dayFromJson(Map<String, dynamic> json) {
    final exercises = (json['day_exercises'] as List? ?? [])
        .map((e) => _exerciseFromDayJson(e as Map<String, dynamic>))
        .toList();

    return WorkoutDay(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      exercises: exercises,
    );
  }

  Exercise _exerciseFromDayJson(Map<String, dynamic> json) {
    final ex = json['exercises'] as Map<String, dynamic>;
    final setCount = json['sets'] as int? ?? 3;
    final targetReps = json['target_reps'] as int? ?? 10;
    final targetWeight = (json['target_weight'] as num?)?.toDouble() ?? 0;
    final restSeconds = json['rest_seconds'] as int? ?? 90;

    return Exercise(
      id: ex['id'] as String,
      name: ex['name'] as String,
      muscleGroup: _parseMuscleGroup(ex['muscle_group'] as String?),
      description: ex['description'] as String?,
      restSeconds: restSeconds,
      sets: List.generate(
        setCount,
        (i) => ExerciseSet(
          id: '${ex['id']}-set-$i',
          setNumber: i + 1,
          targetReps: targetReps,
          targetWeight: targetWeight,
        ),
      ),
    );
  }

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    final rawSets = json['session_sets'] as List? ?? [];
    final exercises = _exercisesFromSets(rawSets);
    return WorkoutSession(
      id: json['id'] as String,
      planId: json['plan_id'] as String? ?? '',
      dayId: json['day_id'] as String? ?? '',
      dayName: json['day_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      status: SessionStatus.completed,
      exercises: exercises,
      totalVolumeKg: json['total_volume_kg'] as int? ?? 0,
    );
  }

  List<Exercise> _exercisesFromSets(List rawSets) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final s in rawSets) {
      final row = s as Map<String, dynamic>;
      final exId = row['exercise_id'] as String?;
      final exName = row['exercise_name'] as String? ?? '';
      final key = exId != null ? '$exId||$exName' : 'local||$exName';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    return grouped.entries.map((entry) {
      final parts = entry.key.split('||');
      final exId = parts[0] == 'local' ? entry.value.first['exercise_name'] as String : parts[0];
      final exName = parts[1];
      final sets = entry.value
        ..sort((a, b) => (a['set_number'] as int).compareTo(b['set_number'] as int));
      return Exercise(
        id: exId,
        name: exName,
        muscleGroup: MuscleGroup.fullBody,
        sets: sets.map((s) => ExerciseSet(
          id: s['id'] as String? ?? '${parts[0]}-${s['set_number']}',
          setNumber: s['set_number'] as int,
          targetReps: s['reps'] as int? ?? 0,
          targetWeight: (s['weight_kg'] as num?)?.toDouble() ?? 0,
          actualReps: s['reps'] as int?,
          actualWeight: (s['weight_kg'] as num?)?.toDouble(),
          isCompleted: s['is_completed'] as bool? ?? true,
        )).toList(),
      );
    }).toList();
  }

  DifficultyLevel _parseDifficulty(String? v) => switch (v) {
        'beginner' => DifficultyLevel.beginner,
        'advanced' => DifficultyLevel.advanced,
        _ => DifficultyLevel.intermediate,
      };

  MuscleGroup _parseMuscleGroup(String? v) => switch (v) {
        'chest' => MuscleGroup.chest,
        'back' => MuscleGroup.back,
        'shoulders' => MuscleGroup.shoulders,
        'arms' => MuscleGroup.arms,
        'legs' => MuscleGroup.legs,
        'core' => MuscleGroup.core,
        'cardio' => MuscleGroup.cardio,
        _ => MuscleGroup.fullBody,
      };
}
