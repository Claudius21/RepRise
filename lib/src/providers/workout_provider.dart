import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/mock_data.dart';
import 'supabase_providers.dart';

// ─── Plans Provider ───────────────────────────────────────────────────────────
class WorkoutPlansNotifier extends AsyncNotifier<List<WorkoutPlan>> {
  @override
  Future<List<WorkoutPlan>> build() async {
    try {
      final plans = await ref.read(workoutRepositoryProvider).fetchPlans();
      return plans.isNotEmpty ? plans : MockData.allPlans;
    } catch (_) {
      return MockData.allPlans;
    }
  }

  Future<void> setActive(String planId) async {
    try {
      await ref.read(workoutRepositoryProvider).setActivePlan(planId);
    } catch (_) {
      // offline: update locally
    }
    state = AsyncData(
      state.valueOrNull?.map((p) => p.copyWith(isActive: p.id == planId)).toList() ?? [],
    );
  }

  void updatePlan(WorkoutPlan updated) {
    final plans = state.valueOrNull ?? [];
    state = AsyncData(
      plans.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  Future<void> refresh() => ref.refresh(workoutPlansProvider.future);
}

final workoutPlansProvider = AsyncNotifierProvider<WorkoutPlansNotifier, List<WorkoutPlan>>(
  WorkoutPlansNotifier.new,
);

final activePlanProvider = Provider<WorkoutPlan?>((ref) {
  final plans = ref.watch(workoutPlansProvider).valueOrNull ?? [];
  try {
    return plans.firstWhere((p) => p.isActive);
  } catch (_) {
    return null;
  }
});

// ─── Session History Provider ─────────────────────────────────────────────────
class SessionHistoryNotifier extends AsyncNotifier<List<WorkoutSession>> {
  @override
  Future<List<WorkoutSession>> build() async {
    try {
      final sessions = await ref.read(workoutRepositoryProvider).fetchSessions();
      return sessions; // Return actual data or empty list, no mock fallback
    } catch (_) {
      return []; // Empty list on error, no mock data
    }
  }

  Future<void> addSession(WorkoutSession session) async {
    WorkoutSession saved = session;
    try {
      print('addSession: Saving to Supabase...');
      final realId = await ref.read(workoutRepositoryProvider).saveSession(session);
      print('addSession: Successfully saved with ID $realId');
      // Reload from Supabase so exercise IDs are real UUIDs
      final refreshed = await ref.read(workoutRepositoryProvider).fetchSessions(limit: 1);
      saved = refreshed.isNotEmpty ? refreshed.first : session.copyWith(id: realId);
    } catch (e, stack) {
      print('addSession: ERROR saving to Supabase: $e');
      print('Stack trace: $stack');
      saved = session; // keeps session-live-... id → shows "Not synced"
    }
    final existing = state.valueOrNull ?? [];
    state = AsyncData([saved, ...existing.where((s) => s.id != saved.id).toList()]);
  }

  Future<void> deleteSession(String sessionId) async {
    await ref.read(workoutRepositoryProvider).deleteSession(sessionId);
    state = AsyncData(
      (state.valueOrNull ?? []).where((s) => s.id != sessionId).toList(),
    );
  }

  Future<void> updateSession(WorkoutSession updated) async {
    await ref.read(workoutRepositoryProvider).updateSessionSets(updated);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((s) => s.id == updated.id ? updated : s)
          .toList(),
    );
  }
}

final sessionHistoryProvider = AsyncNotifierProvider<SessionHistoryNotifier, List<WorkoutSession>>(
  SessionHistoryNotifier.new,
);

// ─── Active Workout Session Provider ─────────────────────────────────────────
class ActiveSessionNotifier extends Notifier<WorkoutSession?> {
  @override
  WorkoutSession? build() => null;

  void startSession(WorkoutDay day, String planId) {
    state = WorkoutSession(
      id: 'session-live-${DateTime.now().millisecondsSinceEpoch}',
      planId: planId,
      dayId: day.id,
      dayName: day.name,
      startedAt: DateTime.now(),
      status: SessionStatus.inProgress,
      exercises: day.exercises.map((e) => e.copyWith(
        sets: e.sets.map((s) => s.copyWith(isCompleted: false)).toList(),
      )).toList(),
    );
  }

  void toggleSet(String exerciseId, String setId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.map((s) {
        if (s.id != setId) return s;
        final newCompleted = !s.isCompleted;
        return s.copyWith(
          isCompleted: newCompleted,
          // Only set actual values to target if not yet set by user
          actualReps: newCompleted
              ? (s.actualReps ?? s.targetReps)
              : null,
          actualWeight: newCompleted
              ? (s.actualWeight ?? s.targetWeight)
              : null,
        );
      }).toList();
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
  }

  void updateSetValues(String exerciseId, String setId, {int? reps, double? weight}) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.map((s) {
        if (s.id != setId) return s;
        return s.copyWith(
          actualReps: reps ?? s.actualReps,
          actualWeight: weight ?? s.actualWeight,
        );
      }).toList();
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
  }

  void addSet(String exerciseId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final lastSet = exercise.sets.lastOrNull;
      final newSet = ExerciseSet(
        id: 'set-${DateTime.now().millisecondsSinceEpoch}-${exercise.sets.length}',
        setNumber: exercise.sets.length + 1,
        targetReps: lastSet?.targetReps ?? 10,
        targetWeight: lastSet?.targetWeight ?? 0,
      );
      return exercise.copyWith(sets: [...exercise.sets, newSet]);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
  }

  void removeExercise(String exerciseId) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: state!.exercises.where((e) => e.id != exerciseId).toList(),
    );
  }

  void addExercise(Exercise exercise, {int? insertAfterIndex}) {
    if (state == null) return;
    if (state!.exercises.any((e) => e.id == exercise.id)) return;
    final list = [...state!.exercises];
    if (insertAfterIndex != null && insertAfterIndex < list.length) {
      list.insert(insertAfterIndex + 1, exercise);
    } else {
      list.add(exercise);
    }
    state = state!.copyWith(exercises: list);
  }

  void removeSet(String exerciseId, String setId) {
    if (state == null) return;
    final updatedExercises = state!.exercises.map((exercise) {
      if (exercise.id != exerciseId) return exercise;
      final updatedSets = exercise.sets.where((s) => s.id != setId).toList();
      // Renumber sets
      for (var i = 0; i < updatedSets.length; i++) {
        updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
      }
      return exercise.copyWith(sets: updatedSets);
    }).toList();
    state = state!.copyWith(exercises: updatedExercises);
  }

  WorkoutSession? finishSession(WidgetRef ref) {
    if (state == null) return null;
    final volume = state!.exercises.fold<int>(0, (acc, e) {
      return acc + e.sets.fold<int>(0, (setAcc, s) {
        if (!s.isCompleted) return setAcc;
        return setAcc + ((s.actualWeight ?? 0) * (s.actualReps ?? 0)).toInt();
      });
    });
    final finished = state!.copyWith(
      finishedAt: DateTime.now(),
      status: SessionStatus.completed,
      totalVolumeKg: volume,
    );
    // Fire-and-forget: saves to Supabase + updates local list
    ref.read(sessionHistoryProvider.notifier).addSession(finished);
    state = null;
    return finished;
  }

  void cancelSession() {
    state = null;
  }
}

final activeSessionProvider = NotifierProvider<ActiveSessionNotifier, WorkoutSession?>(
  ActiveSessionNotifier.new,
);
