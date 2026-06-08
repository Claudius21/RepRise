import '../models/exercise.dart';
import '../models/workout_plan.dart';

/// Built-in workout templates that users can import and customize.
/// These are stored locally as templates and copied to Supabase on import.
abstract final class WorkoutTemplates {
  // ─── Exercise Library ─────────────────────────────────────────────────────

  static List<ExerciseSet> _buildSets({
    required int count,
    required int reps,
    required double weight,
  }) {
    return List.generate(
      count,
      (i) => ExerciseSet(
        id: 'set-$i',
        setNumber: i + 1,
        targetReps: reps,
        targetWeight: weight,
      ),
    );
  }

  static List<Exercise> get _chestExercises => [
    Exercise(
      id: 'ex-chest-001',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      description: 'Classic compound chest exercise. Keep elbows at 75°.',
      sets: _buildSets(count: 4, reps: 8, weight: 80),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-chest-002',
      name: 'Incline Dumbbell Press',
      muscleGroup: MuscleGroup.chest,
      description: 'Targets upper chest. Set bench to 30-45°.',
      sets: _buildSets(count: 3, reps: 10, weight: 30),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-chest-003',
      name: 'Cable Flyes',
      muscleGroup: MuscleGroup.chest,
      description: 'Isolation movement. Focus on the squeeze at peak.',
      sets: _buildSets(count: 3, reps: 12, weight: 15),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> get _backExercises => [
    Exercise(
      id: 'ex-back-001',
      name: 'Deadlift',
      muscleGroup: MuscleGroup.back,
      description: 'King of compound movements. Neutral spine throughout.',
      sets: _buildSets(count: 4, reps: 5, weight: 120),
      restSeconds: 180,
    ),
    Exercise(
      id: 'ex-back-002',
      name: 'Pull-Ups',
      muscleGroup: MuscleGroup.back,
      description: 'Full range of motion. Dead hang at bottom.',
      sets: _buildSets(count: 4, reps: 8, weight: 0),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-back-003',
      name: 'Barbell Row',
      muscleGroup: MuscleGroup.back,
      description: 'Hinge at hip, row to lower chest.',
      sets: _buildSets(count: 3, reps: 10, weight: 70),
      restSeconds: 90,
    ),
  ];

  static List<Exercise> get _legExercises => [
    Exercise(
      id: 'ex-legs-001',
      name: 'Squat',
      muscleGroup: MuscleGroup.legs,
      description: 'Break parallel, knees track over toes.',
      sets: _buildSets(count: 4, reps: 8, weight: 100),
      restSeconds: 150,
    ),
    Exercise(
      id: 'ex-legs-002',
      name: 'Romanian Deadlift',
      muscleGroup: MuscleGroup.legs,
      description: 'Hip hinge, soft knee bend, stretch hamstrings.',
      sets: _buildSets(count: 3, reps: 10, weight: 80),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-legs-003',
      name: 'Leg Press',
      muscleGroup: MuscleGroup.legs,
      description: 'Full range. Feet hip-width apart.',
      sets: _buildSets(count: 3, reps: 12, weight: 150),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-legs-004',
      name: 'Walking Lunges',
      muscleGroup: MuscleGroup.legs,
      description: 'Keep torso upright, knee doesn\'t touch ground.',
      sets: _buildSets(count: 3, reps: 12, weight: 20),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> get _shoulderExercises => [
    Exercise(
      id: 'ex-shoulders-001',
      name: 'Overhead Press',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Press bar directly overhead, full lockout.',
      sets: _buildSets(count: 4, reps: 8, weight: 60),
      restSeconds: 120,
    ),
    Exercise(
      id: 'ex-shoulders-002',
      name: 'Lateral Raises',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Control the negative, slight forward lean.',
      sets: _buildSets(count: 4, reps: 15, weight: 12),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-shoulders-003',
      name: 'Face Pulls',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Pull to face level, external rotation.',
      sets: _buildSets(count: 3, reps: 15, weight: 20),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> get _coreExercises => [
    Exercise(
      id: 'ex-core-001',
      name: 'Plank',
      muscleGroup: MuscleGroup.core,
      description: 'Neutral spine, don\'t let hips sag.',
      sets: _buildSets(count: 3, reps: 60, weight: 0),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-core-002',
      name: 'Hanging Leg Raises',
      muscleGroup: MuscleGroup.core,
      description: 'Control the movement, avoid swinging.',
      sets: _buildSets(count: 3, reps: 12, weight: 0),
      restSeconds: 60,
    ),
  ];

  // ─── Templates ─────────────────────────────────────────────────────────────

  static WorkoutPlan get pushPullLegs => WorkoutPlan(
    id: 'tpl-ppl-001',
    name: 'Push / Pull / Legs',
    description: 'Classic 4-day split targeting all major muscle groups with optimal frequency and volume.',
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 8,
    isActive: false,
    createdAt: DateTime.now(),
    days: [
      WorkoutDay(
        id: 'day-ppl-001',
        name: 'Push Day A',
        dayOfWeek: 1,
        exercises: [
          _chestExercises[0], // Bench Press
          _chestExercises[1], // Incline Dumbbell Press
          _shoulderExercises[0], // Overhead Press
          _shoulderExercises[1], // Lateral Raises
        ],
      ),
      WorkoutDay(
        id: 'day-ppl-002',
        name: 'Pull Day A',
        dayOfWeek: 2,
        exercises: [
          _backExercises[0], // Deadlift
          _backExercises[1], // Pull-Ups
          _backExercises[2], // Barbell Row
        ],
      ),
      WorkoutDay(
        id: 'day-ppl-003',
        name: 'Leg Day A',
        dayOfWeek: 4,
        exercises: [
          _legExercises[0], // Squat
          _legExercises[1], // Romanian Deadlift
          _legExercises[2], // Leg Press
          _legExercises[3], // Walking Lunges
        ],
      ),
      WorkoutDay(
        id: 'day-ppl-004',
        name: 'Push Day B',
        dayOfWeek: 5,
        exercises: [
          _chestExercises[2], // Cable Flyes
          _shoulderExercises[2], // Face Pulls
          _coreExercises[0], // Plank
          _coreExercises[1], // Hanging Leg Raises
        ],
      ),
    ],
  );

  static WorkoutPlan get fullBodyStarter => WorkoutPlan(
    id: 'tpl-fb-001',
    name: 'Full Body Starter',
    description: 'Perfect 3-day full-body routine for beginners. Focuses on form and building a strong base.',
    difficulty: DifficultyLevel.beginner,
    durationWeeks: 12,
    isActive: false,
    createdAt: DateTime.now(),
    days: [
      WorkoutDay(
        id: 'day-fb-001',
        name: 'Day A',
        dayOfWeek: 1,
        exercises: [
          _legExercises[0], // Squat
          _chestExercises[0], // Bench Press
          _backExercises[1], // Pull-Ups
          _coreExercises[0], // Plank
        ],
      ),
      WorkoutDay(
        id: 'day-fb-002',
        name: 'Day B',
        dayOfWeek: 3,
        exercises: [
          _legExercises[1], // Romanian Deadlift
          _shoulderExercises[0], // Overhead Press
          _backExercises[2], // Barbell Row
          _coreExercises[1], // Hanging Leg Raises
        ],
      ),
      WorkoutDay(
        id: 'day-fb-003',
        name: 'Day C',
        dayOfWeek: 5,
        exercises: [
          _legExercises[2], // Leg Press
          _chestExercises[1], // Incline Dumbbell Press
          _backExercises[1], // Pull-Ups
          _shoulderExercises[1], // Lateral Raises
        ],
      ),
    ],
  );

  static WorkoutPlan get upperLowerSplit => WorkoutPlan(
    id: 'tpl-ul-001',
    name: 'Upper / Lower Split',
    description: '4-day split alternating between upper and lower body. Great for strength and muscle building.',
    difficulty: DifficultyLevel.intermediate,
    durationWeeks: 8,
    isActive: false,
    createdAt: DateTime.now(),
    days: [
      WorkoutDay(
        id: 'day-ul-001',
        name: 'Upper A',
        dayOfWeek: 1,
        exercises: [
          _chestExercises[0], // Bench Press
          _backExercises[2], // Barbell Row
          _shoulderExercises[0], // Overhead Press
          _chestExercises[1], // Incline Dumbbell Press
        ],
      ),
      WorkoutDay(
        id: 'day-ul-002',
        name: 'Lower A',
        dayOfWeek: 2,
        exercises: [
          _legExercises[0], // Squat
          _legExercises[1], // Romanian Deadlift
          _legExercises[3], // Walking Lunges
          _coreExercises[0], // Plank
        ],
      ),
      WorkoutDay(
        id: 'day-ul-003',
        name: 'Upper B',
        dayOfWeek: 4,
        exercises: [
          _backExercises[1], // Pull-Ups
          _chestExercises[2], // Cable Flyes
          _shoulderExercises[1], // Lateral Raises
          _backExercises[0], // Deadlift
        ],
      ),
      WorkoutDay(
        id: 'day-ul-004',
        name: 'Lower B',
        dayOfWeek: 5,
        exercises: [
          _legExercises[2], // Leg Press
          _legExercises[0], // Squat (lighter)
          _coreExercises[1], // Hanging Leg Raises
          _legExercises[3], // Walking Lunges
        ],
      ),
    ],
  );

  static List<WorkoutPlan> get all => [
    pushPullLegs,
    fullBodyStarter,
    upperLowerSplit,
  ];
}
