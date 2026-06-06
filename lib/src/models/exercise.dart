import 'package:equatable/equatable.dart';

enum MuscleGroup {
  chest,
  back,
  shoulders,
  arms,
  legs,
  core,
  cardio,
  fullBody,
}

extension MuscleGroupLabel on MuscleGroup {
  String get label => switch (this) {
        MuscleGroup.chest => 'Chest',
        MuscleGroup.back => 'Back',
        MuscleGroup.shoulders => 'Shoulders',
        MuscleGroup.arms => 'Arms',
        MuscleGroup.legs => 'Legs',
        MuscleGroup.core => 'Core',
        MuscleGroup.cardio => 'Cardio',
        MuscleGroup.fullBody => 'Full Body',
      };
}

class ExerciseSet extends Equatable {
  final String id;
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final int? actualReps;
  final double? actualWeight;
  final bool isCompleted;

  const ExerciseSet({
    required this.id,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    this.actualReps,
    this.actualWeight,
    this.isCompleted = false,
  });

  ExerciseSet copyWith({
    String? id,
    int? setNumber,
    int? targetReps,
    double? targetWeight,
    int? actualReps,
    double? actualWeight,
    bool? isCompleted,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id, setNumber, targetReps, targetWeight,
        actualReps, actualWeight, isCompleted,
      ];
}

class Exercise extends Equatable {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final String? description;
  final String? imageUrl;
  final List<ExerciseSet> sets;
  final int restSeconds;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.imageUrl,
    required this.sets,
    this.restSeconds = 90,
  });

  Exercise copyWith({
    String? id,
    String? name,
    MuscleGroup? muscleGroup,
    String? description,
    String? imageUrl,
    List<ExerciseSet>? sets,
    int? restSeconds,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sets: sets ?? this.sets,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  int get completedSets => sets.where((s) => s.isCompleted).length;
  bool get isCompleted => sets.isNotEmpty && completedSets == sets.length;

  @override
  List<Object?> get props => [id, name, muscleGroup, description, imageUrl, sets, restSeconds];
}
