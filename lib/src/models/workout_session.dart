import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum SessionStatus { notStarted, inProgress, completed, skipped }

class WorkoutSession extends Equatable {
  final String id;
  final String planId;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final SessionStatus status;
  final List<Exercise> exercises;
  final int totalVolumeKg;

  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    this.finishedAt,
    required this.status,
    required this.exercises,
    this.totalVolumeKg = 0,
  });

  WorkoutSession copyWith({
    String? id,
    String? planId,
    String? dayId,
    String? dayName,
    DateTime? startedAt,
    DateTime? finishedAt,
    SessionStatus? status,
    List<Exercise>? exercises,
    int? totalVolumeKg,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      dayId: dayId ?? this.dayId,
      dayName: dayName ?? this.dayName,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
    );
  }

  Duration? get duration => finishedAt?.difference(startedAt);

  int get completedExercisesCount => exercises.where((e) => e.isCompleted).length;
  double get completionPercentage =>
      exercises.isEmpty ? 0 : completedExercisesCount / exercises.length;

  @override
  List<Object?> get props => [
        id, planId, dayId, dayName, startedAt,
        finishedAt, status, exercises, totalVolumeKg,
      ];
}
