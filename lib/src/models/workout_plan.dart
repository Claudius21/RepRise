import 'package:equatable/equatable.dart';
import 'exercise.dart';

enum DifficultyLevel { beginner, intermediate, advanced }

extension DifficultyLabel on DifficultyLevel {
  String get label => switch (this) {
        DifficultyLevel.beginner => 'Beginner',
        DifficultyLevel.intermediate => 'Intermediate',
        DifficultyLevel.advanced => 'Advanced',
      };
}

class WorkoutDay extends Equatable {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final int dayOfWeek;

  const WorkoutDay({
    required this.id,
    required this.name,
    required this.exercises,
    required this.dayOfWeek,
  });

  int get estimatedMinutes =>
      exercises.fold(0, (acc, e) => acc + (e.sets.length * 2) + (e.sets.length * (e.restSeconds ~/ 60 + 1)));

  @override
  List<Object?> get props => [id, name, exercises, dayOfWeek];
}

class WorkoutPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final DifficultyLevel difficulty;
  final int durationWeeks;
  final List<WorkoutDay> days;
  final bool isActive;
  final DateTime createdAt;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.days,
    this.isActive = false,
    required this.createdAt,
  });

  WorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    DifficultyLevel? difficulty,
    int? durationWeeks,
    List<WorkoutDay>? days,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      days: days ?? this.days,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get totalExercises => days.fold(0, (acc, d) => acc + d.exercises.length);
  int get trainingDaysPerWeek => days.length;

  @override
  List<Object?> get props => [id, name, description, difficulty, durationWeeks, days, isActive, createdAt];
}
