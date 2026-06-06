import 'package:equatable/equatable.dart';

enum FitnessGoal { loseWeight, buildMuscle, improveEndurance, stayActive }

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

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.goal,
    this.weeklyTargetDays = 4,
    required this.joinedAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    FitnessGoal? goal,
    int? weeklyTargetDays,
    DateTime? joinedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      goal: goal ?? this.goal,
      weeklyTargetDays: weeklyTargetDays ?? this.weeklyTargetDays,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, avatarUrl, goal, weeklyTargetDays, joinedAt];
}
