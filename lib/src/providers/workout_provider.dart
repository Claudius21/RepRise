import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';
import '../services/mock_data.dart';

// ─── Plans Provider ───────────────────────────────────────────────────────────
class WorkoutPlansNotifier extends Notifier<List<WorkoutPlan>> {
  @override
  List<WorkoutPlan> build() => MockData.allPlans;

  void setActive(String planId) {
    state = state.map((p) => p.copyWith(isActive: p.id == planId)).toList();
  }
}

final workoutPlansProvider = NotifierProvider<WorkoutPlansNotifier, List<WorkoutPlan>>(
  WorkoutPlansNotifier.new,
);

final activePlanProvider = Provider<WorkoutPlan?>((ref) {
  final plans = ref.watch(workoutPlansProvider);
  try {
    return plans.firstWhere((p) => p.isActive);
  } catch (_) {
    return null;
  }
});

// ─── Session History Provider ─────────────────────────────────────────────────
class SessionHistoryNotifier extends Notifier<List<WorkoutSession>> {
  @override
  List<WorkoutSession> build() => MockData.recentSessions;

  void addSession(WorkoutSession session) {
    state = [session, ...state];
  }
}

final sessionHistoryProvider = NotifierProvider<SessionHistoryNotifier, List<WorkoutSession>>(
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
        return s.copyWith(
          isCompleted: !s.isCompleted,
          actualReps: s.isCompleted ? null : s.targetReps,
          actualWeight: s.isCompleted ? null : s.targetWeight,
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
