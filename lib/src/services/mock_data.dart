import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

abstract final class MockData {
  // ─── User ───────────────────────────────────────────────────────────────────
  static final AppUser currentUser = AppUser(
    id: 'user-001',
    name: 'Alex',
    email: 'alex@reprise.app',
    goal: FitnessGoal.buildMuscle,
    weeklyTargetDays: 4,
    joinedAt: DateTime(2024, 1, 15),
  );

  // ─── Exercises ───────────────────────────────────────────────────────────────
  static List<ExerciseSet> _buildSets(
      {required int count, required int reps, required double weight}) {
    return List.generate(
      count,
      (i) => ExerciseSet(
        id: 'set-${DateTime.now().microsecondsSinceEpoch}-$i',
        setNumber: i + 1,
        targetReps: reps,
        targetWeight: weight,
      ),
    );
  }

  static List<Exercise> chestExercises = [
    Exercise(
      id: 'ex-001',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      description: 'Classic compound chest exercise. Keep elbows at 75°.',
      sets: _buildSets(count: 4, reps: 8, weight: 80),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-002',
      name: 'Incline Dumbbell Press',
      muscleGroup: MuscleGroup.chest,
      description: 'Targets upper chest. Set bench to 30-45°.',
      sets: _buildSets(count: 3, reps: 10, weight: 30),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-003',
      name: 'Cable Flyes',
      muscleGroup: MuscleGroup.chest,
      description: 'Isolation movement. Focus on the squeeze at peak.',
      sets: _buildSets(count: 3, reps: 12, weight: 15),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> backExercises = [
    Exercise(
      id: 'ex-004',
      name: 'Deadlift',
      muscleGroup: MuscleGroup.back,
      description: 'King of compound movements. Neutral spine throughout.',
      sets: _buildSets(count: 4, reps: 5, weight: 120),
      restSeconds: 180,
    ),
    Exercise(
      id: 'ex-005',
      name: 'Pull-Ups',
      muscleGroup: MuscleGroup.back,
      description: 'Full range of motion. Dead hang at bottom.',
      sets: _buildSets(count: 4, reps: 8, weight: 0),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-006',
      name: 'Barbell Row',
      muscleGroup: MuscleGroup.back,
      description: 'Hinge at hip, row to lower chest.',
      sets: _buildSets(count: 3, reps: 10, weight: 70),
      restSeconds: 90,
    ),
  ];

  static List<Exercise> legExercises = [
    Exercise(
      id: 'ex-007',
      name: 'Squat',
      muscleGroup: MuscleGroup.legs,
      description: 'Break parallel, knees track over toes.',
      sets: _buildSets(count: 4, reps: 8, weight: 100),
      restSeconds: 150,
    ),
    Exercise(
      id: 'ex-008',
      name: 'Romanian Deadlift',
      muscleGroup: MuscleGroup.legs,
      description: 'Hip hinge, soft knee bend, stretch hamstrings.',
      sets: _buildSets(count: 3, reps: 10, weight: 80),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-009',
      name: 'Leg Press',
      muscleGroup: MuscleGroup.legs,
      description: 'Full range. Feet hip-width apart.',
      sets: _buildSets(count: 3, reps: 12, weight: 150),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-010',
      name: 'Walking Lunges',
      muscleGroup: MuscleGroup.legs,
      description: 'Keep torso upright, knee doesn\'t touch ground.',
      sets: _buildSets(count: 3, reps: 12, weight: 20),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> shoulderExercises = [
    Exercise(
      id: 'ex-011',
      name: 'Overhead Press',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Press bar directly overhead, full lockout.',
      sets: _buildSets(count: 4, reps: 8, weight: 60),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-012',
      name: 'Lateral Raises',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Control the negative, slight forward lean.',
      sets: _buildSets(count: 4, reps: 15, weight: 12),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-013',
      name: 'Face Pulls',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Pull to face level, external rotation.',
      sets: _buildSets(count: 3, reps: 15, weight: 20),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> coreExercises = [
    Exercise(
      id: 'ex-014',
      name: 'Plank',
      muscleGroup: MuscleGroup.core,
      description: 'Neutral spine, don\'t let hips sag.',
      sets: _buildSets(count: 3, reps: 60, weight: 0),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-015',
      name: 'Hanging Leg Raises',
      muscleGroup: MuscleGroup.core,
      description: 'Control the movement, avoid swinging.',
      sets: _buildSets(count: 3, reps: 12, weight: 0),
      restSeconds: 60,
    ),
  ];

  // ─── Workout Plan ────────────────────────────────────────────────────────────
  static final WorkoutPlan push4DayPlan = WorkoutPlan(
    id: 'plan-001',
    name: 'Push / Pull / Legs',
    description: 'Classic 4-day split targeting all major muscle groups with optimal frequency and volume.',
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 8,
    isActive: true,
    createdAt: DateTime(2024, 3, 1),
    days: [
      WorkoutDay(
        id: 'day-001',
        name: 'Push Day A',
        dayOfWeek: 1,
        exercises: [
          chestExercises[0],
          chestExercises[1],
          shoulderExercises[0],
          shoulderExercises[1],
        ],
      ),
      WorkoutDay(
        id: 'day-002',
        name: 'Pull Day A',
        dayOfWeek: 2,
        exercises: [
          backExercises[0],
          backExercises[1],
          backExercises[2],
        ],
      ),
      WorkoutDay(
        id: 'day-003',
        name: 'Leg Day A',
        dayOfWeek: 4,
        exercises: [
          legExercises[0],
          legExercises[1],
          legExercises[2],
          legExercises[3],
        ],
      ),
      WorkoutDay(
        id: 'day-004',
        name: 'Push Day B',
        dayOfWeek: 5,
        exercises: [
          chestExercises[2],
          shoulderExercises[2],
          coreExercises[0],
          coreExercises[1],
        ],
      ),
    ],
  );

  static final WorkoutPlan fullBodyBeginner = WorkoutPlan(
    id: 'plan-002',
    name: 'Full Body Starter',
    description: 'Perfect 3-day full-body routine for beginners. Focuses on form and building a strong base.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 12,
    createdAt: DateTime(2024, 2, 1),
    days: [
      WorkoutDay(
        id: 'day-005',
        name: 'Day A',
        dayOfWeek: 1,
        exercises: [
          legExercises[0],
          chestExercises[0],
          backExercises[1],
          coreExercises[0],
        ],
      ),
      WorkoutDay(
        id: 'day-006',
        name: 'Day B',
        dayOfWeek: 3,
        exercises: [
          legExercises[1],
          shoulderExercises[0],
          backExercises[2],
          coreExercises[1],
        ],
      ),
      WorkoutDay(
        id: 'day-007',
        name: 'Day C',
        dayOfWeek: 5,
        exercises: [
          legExercises[2],
          chestExercises[1],
          backExercises[1],
          shoulderExercises[1],
        ],
      ),
    ],
  );

  static List<WorkoutPlan> get allPlans => [push4DayPlan, fullBodyBeginner];

  // ─── Past Sessions ────────────────────────────────────────────────────────────
  static List<WorkoutSession> get recentSessions {
    final now = DateTime.now();
    return [
      WorkoutSession(
        id: 'session-001',
        planId: 'plan-001',
        dayId: 'day-001',
        dayName: 'Push Day A',
        startedAt: now.subtract(const Duration(days: 1, hours: 1)),
        finishedAt: now.subtract(const Duration(days: 1)),
        status: SessionStatus.completed,
        exercises: chestExercises.map((e) => e.copyWith(
          sets: e.sets.map((s) => s.copyWith(
            actualReps: s.targetReps,
            actualWeight: s.targetWeight,
            isCompleted: true,
          )).toList(),
        )).toList(),
        totalVolumeKg: 3240,
      ),
      WorkoutSession(
        id: 'session-002',
        planId: 'plan-001',
        dayId: 'day-002',
        dayName: 'Pull Day A',
        startedAt: now.subtract(const Duration(days: 3, hours: 1, minutes: 10)),
        finishedAt: now.subtract(const Duration(days: 3)),
        status: SessionStatus.completed,
        exercises: backExercises.map((e) => e.copyWith(
          sets: e.sets.map((s) => s.copyWith(
            actualReps: s.targetReps,
            actualWeight: s.targetWeight,
            isCompleted: true,
          )).toList(),
        )).toList(),
        totalVolumeKg: 4100,
      ),
      WorkoutSession(
        id: 'session-003',
        planId: 'plan-001',
        dayId: 'day-003',
        dayName: 'Leg Day A',
        startedAt: now.subtract(const Duration(days: 5, hours: 1, minutes: 20)),
        finishedAt: now.subtract(const Duration(days: 5)),
        status: SessionStatus.completed,
        exercises: legExercises.map((e) => e.copyWith(
          sets: e.sets.map((s) => s.copyWith(
            actualReps: s.targetReps,
            actualWeight: s.targetWeight,
            isCompleted: true,
          )).toList(),
        )).toList(),
        totalVolumeKg: 5800,
      ),
      WorkoutSession(
        id: 'session-004',
        planId: 'plan-001',
        dayId: 'day-004',
        dayName: 'Push Day B',
        startedAt: now.subtract(const Duration(days: 7, hours: 1)),
        finishedAt: now.subtract(const Duration(days: 7)),
        status: SessionStatus.completed,
        exercises: [],
        totalVolumeKg: 2600,
      ),
      WorkoutSession(
        id: 'session-005',
        planId: 'plan-001',
        dayId: 'day-001',
        dayName: 'Push Day A',
        startedAt: now.subtract(const Duration(days: 8, hours: 1)),
        finishedAt: now.subtract(const Duration(days: 8)),
        status: SessionStatus.completed,
        exercises: [],
        totalVolumeKg: 3100,
      ),
      WorkoutSession(
        id: 'session-006',
        planId: 'plan-001',
        dayId: 'day-002',
        dayName: 'Pull Day A',
        startedAt: now.subtract(const Duration(days: 10, hours: 1)),
        finishedAt: now.subtract(const Duration(days: 10)),
        status: SessionStatus.completed,
        exercises: [],
        totalVolumeKg: 3900,
      ),
    ];
  }

  // ─── Weekly Volume Data for Charts ───────────────────────────────────────────
  static List<Map<String, dynamic>> get weeklyVolumeData => [
        {'day': 'Mon', 'volume': 3240},
        {'day': 'Tue', 'volume': 0},
        {'day': 'Wed', 'volume': 4100},
        {'day': 'Thu', 'volume': 0},
        {'day': 'Fri', 'volume': 5800},
        {'day': 'Sat', 'volume': 0},
        {'day': 'Sun', 'volume': 2600},
      ];

  static List<Map<String, dynamic>> get monthlySessionData => List.generate(
        12,
        (i) => {
          'month': [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ][i],
          'sessions': [8, 10, 12, 9, 14, 16, 11, 13, 15, 12, 14, 6][i],
        },
      );
}
