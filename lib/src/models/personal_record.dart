import 'package:equatable/equatable.dart';

/// Represents a personal record for a specific exercise
class PersonalRecord extends Equatable {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime achievedAt;

  const PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.achievedAt,
  });

  /// Calculate estimated one-rep max using Epley formula
  double get estimatedOneRepMax => weightKg * (1 + reps / 30);

  /// Volume for this record (weight × reps)
  double get volume => weightKg * reps;

  /// Trophy level based on weight achievements
  TrophyLevel get trophyLevel {
    if (weightKg >= 100) return TrophyLevel.gold;
    if (weightKg >= 60) return TrophyLevel.silver;
    return TrophyLevel.bronze;
  }

  /// Badge text based on weight milestones
  String? get weightBadge {
    if (weightKg >= 150) return '150KG CLUB';
    if (weightKg >= 100) return '100KG CLUB';
    if (weightKg >= 80) return '80KG CLUB';
    if (weightKg >= 60) return '60KG CLUB';
    if (weightKg >= 40) return '40KG CLUB';
    return null;
  }

  PersonalRecord copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    double? weightKg,
    int? reps,
    DateTime? achievedAt,
  }) {
    return PersonalRecord(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    // Use exercise_ref if available (original ID), otherwise fall back to exercise_id
    final exerciseId = json['exercise_ref'] as String? ?? json['exercise_id'] as String;
    return PersonalRecord(
      id: json['id'] as String,
      exerciseId: exerciseId,
      exerciseName: json['exercise_name'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      reps: json['reps'] as int,
      achievedAt: DateTime.parse(json['achieved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'exercise_name': exerciseName,
      'weight_kg': weightKg,
      'reps': reps,
      'achieved_at': achievedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, exerciseId, exerciseName, weightKg, reps, achievedAt];
}

enum TrophyLevel { bronze, silver, gold }

extension TrophyLevelExtension on TrophyLevel {
  String get emoji => switch (this) {
    TrophyLevel.bronze => '🥉',
    TrophyLevel.silver => '🥈',
    TrophyLevel.gold => '🥇',
  };

  String get name => switch (this) {
    TrophyLevel.bronze => 'Bronze',
    TrophyLevel.silver => 'Silver',
    TrophyLevel.gold => 'Gold',
  };
}

/// Summary statistics for personal records
class PersonalRecordStats extends Equatable {
  final int totalRecords;
  final int newRecordsThisMonth;
  final double totalVolumeLifted;
  final String? strongestExercise;
  final int currentStreakWeeks;

  const PersonalRecordStats({
    required this.totalRecords,
    required this.newRecordsThisMonth,
    required this.totalVolumeLifted,
    this.strongestExercise,
    required this.currentStreakWeeks,
  });

  @override
  List<Object?> get props => [
    totalRecords,
    newRecordsThisMonth,
    totalVolumeLifted,
    strongestExercise,
    currentStreakWeeks,
  ];
}
