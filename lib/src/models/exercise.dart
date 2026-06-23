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
  final bool wasPR; // Persist PR status when set was completed

  const ExerciseSet({
    required this.id,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    this.actualReps,
    this.actualWeight,
    this.isCompleted = false,
    this.wasPR = false,
  });

  ExerciseSet copyWith({
    String? id,
    int? setNumber,
    int? targetReps,
    double? targetWeight,
    int? actualReps,
    double? actualWeight,
    bool? isCompleted,
    bool? wasPR,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      actualReps: actualReps ?? this.actualReps,
      actualWeight: actualWeight ?? this.actualWeight,
      isCompleted: isCompleted ?? this.isCompleted,
      wasPR: wasPR ?? this.wasPR,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'setNumber': setNumber,
        'targetReps': targetReps,
        'targetWeight': targetWeight,
        'actualReps': actualReps,
        'actualWeight': actualWeight,
        'isCompleted': isCompleted,
        'wasPR': wasPR,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        id: json['id'] as String,
        setNumber: json['setNumber'] as int,
        targetReps: json['targetReps'] as int,
        targetWeight: (json['targetWeight'] as num).toDouble(),
        actualReps: json['actualReps'] as int?,
        actualWeight: (json['actualWeight'] as num?)?.toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
        wasPR: json['wasPR'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id, setNumber, targetReps, targetWeight,
        actualReps, actualWeight, isCompleted, wasPR,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscleGroup': muscleGroup.name,
        'description': description,
        'imageUrl': imageUrl,
        'sets': sets.map((s) => s.toJson()).toList(),
        'restSeconds': restSeconds,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        name: json['name'] as String,
        muscleGroup: MuscleGroup.values.firstWhere(
          (e) => e.name == json['muscleGroup'],
          orElse: () => MuscleGroup.fullBody,
        ),
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        sets: (json['sets'] as List)
            .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
            .toList(),
        restSeconds: json['restSeconds'] as int? ?? 90,
      );

  @override
  List<Object?> get props => [id, name, muscleGroup, description, imageUrl, sets, restSeconds];
}
