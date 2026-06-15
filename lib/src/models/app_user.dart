import 'package:equatable/equatable.dart';

enum FitnessGoal { loseWeight, buildMuscle, improveEndurance, stayActive }

enum Gender { male, female, other, preferNotToSay }

extension GenderLabel on Gender {
  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
        Gender.preferNotToSay => 'Prefer not to say',
      };
}

extension FitnessGoalLabel on FitnessGoal {
  String get label => switch (this) {
        FitnessGoal.loseWeight => 'Lose Weight',
        FitnessGoal.buildMuscle => 'Build Muscle',
        FitnessGoal.improveEndurance => 'Improve Endurance',
        FitnessGoal.stayActive => 'Stay Active',
      };
}

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final FitnessGoal goal;
  final int weeklyTargetDays;
  final DateTime joinedAt;
  final Gender? gender;
  final double? heightCm;
  final double? weightKg;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.goal,
    this.weeklyTargetDays = 4,
    required this.joinedAt,
    this.gender,
    this.heightCm,
    this.weightKg,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    FitnessGoal? goal,
    int? weeklyTargetDays,
    DateTime? joinedAt,
    Gender? gender,
    double? heightCm,
    double? weightKg,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      goal: goal ?? this.goal,
      weeklyTargetDays: weeklyTargetDays ?? this.weeklyTargetDays,
      joinedAt: joinedAt ?? this.joinedAt,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, avatarUrl, goal, weeklyTargetDays, joinedAt, 
        gender, heightCm, weightKg
      ];
}
