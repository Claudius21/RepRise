import '../models/app_user.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

abstract final class MockData {
  // ─── User ───────────────────────────────────────────────────────────────────
  static final AppUser currentUser = AppUser(
    id: 'user-001',
    name: 'Alex',
    email: 'alex@shredmembers.app',
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
    Exercise(
      id: 'ex-016',
      name: 'Dips',
      muscleGroup: MuscleGroup.chest,
      description: 'Bodyweight or weighted. Lean forward for chest emphasis.',
      sets: _buildSets(count: 3, reps: 10, weight: 0),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-017',
      name: 'Decline Bench Press',
      muscleGroup: MuscleGroup.chest,
      description: 'Targets lower chest. 15-20° decline.',
      sets: _buildSets(count: 3, reps: 8, weight: 70),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-018',
      name: 'Push-Ups',
      muscleGroup: MuscleGroup.chest,
      description: 'Classic bodyweight exercise. Wide grip for chest.',
      sets: _buildSets(count: 3, reps: 15, weight: 0),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-019',
      name: 'Pec Deck Machine',
      muscleGroup: MuscleGroup.chest,
      description: 'Machine isolation. Full range of motion.',
      sets: _buildSets(count: 3, reps: 12, weight: 25),
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
    Exercise(
      id: 'ex-020',
      name: 'Lat Pulldown',
      muscleGroup: MuscleGroup.back,
      description: 'Wide grip, pull to upper chest. Control negative.',
      sets: _buildSets(count: 3, reps: 12, weight: 60),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-021',
      name: 'T-Bar Row',
      muscleGroup: MuscleGroup.back,
      description: 'Close grip, pull to sternum. Keep back straight.',
      sets: _buildSets(count: 3, reps: 10, weight: 50),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-022',
      name: 'Seated Cable Row',
      muscleGroup: MuscleGroup.back,
      description: 'Full stretch, pull to navel. Keep chest up.',
      sets: _buildSets(count: 3, reps: 12, weight: 45),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-023',
      name: 'Chin-Ups',
      muscleGroup: MuscleGroup.back,
      description: 'Underhand grip, bicep emphasis. Full range.',
      sets: _buildSets(count: 3, reps: 10, weight: 0),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-024',
      name: 'Hyperextensions',
      muscleGroup: MuscleGroup.back,
      description: 'Lower back focus. Don\'t overextend.',
      sets: _buildSets(count: 3, reps: 15, weight: 0),
      restSeconds: 60,
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
    Exercise(
      id: 'ex-025',
      name: 'Bulgarian Split Squats',
      muscleGroup: MuscleGroup.legs,
      description: 'Rear foot elevated, front knee tracks over toes.',
      sets: _buildSets(count: 3, reps: 10, weight: 15),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-026',
      name: 'Leg Extensions',
      muscleGroup: MuscleGroup.legs,
      description: 'Quad isolation. Squeeze at top.',
      sets: _buildSets(count: 3, reps: 15, weight: 40),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-027',
      name: 'Leg Curls',
      muscleGroup: MuscleGroup.legs,
      description: 'Hamstring isolation. Control negative.',
      sets: _buildSets(count: 3, reps: 15, weight: 35),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-028',
      name: 'Calf Raises',
      muscleGroup: MuscleGroup.legs,
      description: 'Full range, pause at top.',
      sets: _buildSets(count: 4, reps: 20, weight: 50),
      restSeconds: 45,
    ),
    Exercise(
      id: 'ex-029',
      name: 'Goblet Squats',
      muscleGroup: MuscleGroup.legs,
      description: 'Hold dumbbell at chest. Keep chest up.',
      sets: _buildSets(count: 3, reps: 12, weight: 25),
      restSeconds: 90,
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
    Exercise(
      id: 'ex-030',
      name: 'Dumbbell Shoulder Press',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Seated or standing. Neutral grip for shoulders.',
      sets: _buildSets(count: 3, reps: 12, weight: 20),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-031',
      name: 'Front Raises',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Front delt focus. Control movement.',
      sets: _buildSets(count: 3, reps: 15, weight: 10),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-032',
      name: 'Bent Over Reverse Flyes',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Rear delts. Keep back straight, don\'t use momentum.',
      sets: _buildSets(count: 3, reps: 15, weight: 8),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-033',
      name: 'Upright Row',
      muscleGroup: MuscleGroup.shoulders,
      description: 'Pull bar to chin. Don\'t go too high.',
      sets: _buildSets(count: 3, reps: 12, weight: 30),
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
    Exercise(
      id: 'ex-034',
      name: 'Crunches',
      muscleGroup: MuscleGroup.core,
      description: 'Abs focus, don\'t pull on neck.',
      sets: _buildSets(count: 3, reps: 20, weight: 0),
      restSeconds: 45,
    ),
    Exercise(
      id: 'ex-035',
      name: 'Russian Twists',
      muscleGroup: MuscleGroup.core,
      description: 'Rotate torso, keep feet off ground.',
      sets: _buildSets(count: 3, reps: 20, weight: 0),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-036',
      name: 'Mountain Climbers',
      muscleGroup: MuscleGroup.core,
      description: 'Fast pace, keep hips down.',
      sets: _buildSets(count: 3, reps: 30, weight: 0),
      restSeconds: 45,
    ),
    Exercise(
      id: 'ex-037',
      name: 'Side Plank',
      muscleGroup: MuscleGroup.core,
      description: 'Keep body straight, don\'t let hips drop.',
      sets: _buildSets(count: 3, reps: 45, weight: 0),
      restSeconds: 45,
    ),
  ];

  static List<Exercise> armsExercises = [
    Exercise(
      id: 'ex-038',
      name: 'Bicep Curls',
      muscleGroup: MuscleGroup.arms,
      description: 'Full range, no swinging. Supinated grip.',
      sets: _buildSets(count: 3, reps: 12, weight: 20),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-039',
      name: 'Tricep Pushdowns',
      muscleGroup: MuscleGroup.arms,
      description: 'Cable pushdown, lock elbows at sides.',
      sets: _buildSets(count: 3, reps: 15, weight: 25),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-040',
      name: 'Hammer Curls',
      muscleGroup: MuscleGroup.arms,
      description: 'Neutral grip, brachioradialis focus.',
      sets: _buildSets(count: 3, reps: 12, weight: 18),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-041',
      name: 'Skull Crushers',
      muscleGroup: MuscleGroup.arms,
      description: 'Lying tricep extension, control negative.',
      sets: _buildSets(count: 3, reps: 12, weight: 15),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-042',
      name: 'Preacher Curls',
      muscleGroup: MuscleGroup.arms,
      description: 'Isolate biceps, no cheating.',
      sets: _buildSets(count: 3, reps: 12, weight: 18),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-043',
      name: 'Tricep Dips',
      muscleGroup: MuscleGroup.arms,
      description: 'Bodyweight or weighted. Keep elbows close.',
      sets: _buildSets(count: 3, reps: 12, weight: 0),
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-044',
      name: 'Concentration Curls',
      muscleGroup: MuscleGroup.arms,
      description: 'Seated, isolate bicep peak.',
      sets: _buildSets(count: 3, reps: 12, weight: 10),
      restSeconds: 45,
    ),
    Exercise(
      id: 'ex-045',
      name: 'Overhead Tricep Extension',
      muscleGroup: MuscleGroup.arms,
      description: 'Cable or dumbbell. Full stretch.',
      sets: _buildSets(count: 3, reps: 15, weight: 12),
      restSeconds: 60,
    ),
  ];

  static List<Exercise> cardioExercises = [
    Exercise(
      id: 'ex-046',
      name: 'Running',
      muscleGroup: MuscleGroup.cardio,
      description: 'Steady pace or intervals. Focus on form.',
      sets: _buildSets(count: 1, reps: 30, weight: 0), // 30 minutes
      restSeconds: 0,
    ),
    Exercise(
      id: 'ex-047',
      name: 'Cycling',
      muscleGroup: MuscleGroup.cardio,
      description: 'Stationary bike or outdoor. Adjust resistance.',
      sets: _buildSets(count: 1, reps: 45, weight: 0), // 45 minutes
      restSeconds: 0,
    ),
    Exercise(
      id: 'ex-048',
      name: 'Jump Rope',
      muscleGroup: MuscleGroup.cardio,
      description: 'High intensity. Stay on balls of feet.',
      sets: _buildSets(count: 3, reps: 100, weight: 0), // 100 jumps
      restSeconds: 60,
    ),
    Exercise(
      id: 'ex-049',
      name: 'Burpees',
      muscleGroup: MuscleGroup.cardio,
      description: 'Full body cardio. Push-up at bottom optional.',
      sets: _buildSets(count: 3, reps: 10, weight: 0),
      restSeconds: 90,
    ),
    Exercise(
      id: 'ex-050',
      name: 'Rowing Machine',
      muscleGroup: MuscleGroup.cardio,
      description: 'Full body, low impact. Focus on form.',
      sets: _buildSets(count: 1, reps: 20, weight: 0), // 20 minutes
      restSeconds: 0,
    ),
    Exercise(
      id: 'ex-051',
      name: 'Stair Climber',
      muscleGroup: MuscleGroup.cardio,
      description: 'Great for glutes and cardio. Don\'t lean on rails.',
      sets: _buildSets(count: 1, reps: 25, weight: 0), // 25 minutes
      restSeconds: 0,
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

  // ─── Tim Doodlerino Plan ────────────────────────────────────────────────
  // Professional 5-day split showing how a personal trainer trains
  static List<ExerciseSet> _buildProSets(
      {required int count, required int reps, required double weight}) {
    return List.generate(
      count,
      (i) => ExerciseSet(
        id: 'set-pro-${DateTime.now().microsecondsSinceEpoch}-$i',
        setNumber: i + 1,
        targetReps: reps,
        targetWeight: weight,
      ),
    );
  }

  static final WorkoutPlan timDoodlerinoPro = WorkoutPlan(
    id: 'plan-tim-pro',
    name: 'Tim Doodlerinos Plan',
    description: '🔥 Train like a Pro! My personal 5-day high-volume split. Heavy compounds, strategic rest. For advanced lifters only.',
    difficulty: DifficultyLevel.advanced,
    durationWeeks: 12,
    isActive: false,
    createdAt: DateTime(2024, 6, 1),
    days: [
      // Day 1: Heavy Push (Chest & Shoulder focus)
      WorkoutDay(
        id: 'day-tim-001',
        name: '🔥 Heavy Push',
        dayOfWeek: 1,
        exercises: [
          Exercise(
            id: 'ex-tim-001',
            name: 'Overhead Press',
            muscleGroup: MuscleGroup.shoulders,
            description: 'Strict press, control the descent.',
            sets: _buildProSets(count: 4, reps: 10, weight: 35),
            restSeconds: 120,
          ),
          Exercise(
            id: 'ex-tim-002-push',
            name: 'Incline Bench Press',
            muscleGroup: MuscleGroup.chest,
            description: '30° incline, focus on upper chest.',
            sets: _buildProSets(count: 3, reps: 8, weight: 27.5),
            restSeconds: 120,
          ),
          Exercise(
            id: 'ex-tim-003-push',
            name: 'Lateral Raises',
            muscleGroup: MuscleGroup.shoulders,
            description: 'Controlled, pause at top.',
            sets: _buildProSets(count: 4, reps: 10, weight: 8),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-004-push',
            name: 'Cable Flyes',
            muscleGroup: MuscleGroup.chest,
            description: 'Stretch at bottom, squeeze at top.',
            sets: _buildProSets(count: 3, reps: 12, weight: 8),
            restSeconds: 90,
          ),
        ],
      ),
      // Day 2: Heavy Pull (Back focus)
      WorkoutDay(
        id: 'day-tim-002',
        name: '🔥 Heavy Pull',
        dayOfWeek: 2,
        exercises: [
          Exercise(
            id: 'ex-tim-002-pullup',
            name: 'Pull Up',
            muscleGroup: MuscleGroup.back,
            description: 'Bodyweight. Full range, control the negative.',
            sets: _buildProSets(count: 4, reps: 15, weight: 0),
            restSeconds: 120,
          ),
          backExercises[4].copyWith(
            name: 'Row Machine',
            description: 'Chest supported row machine. Squeeze shoulder blades.',
          ), // T-Bar Row renamed to Row Machine
          Exercise(
            id: 'ex-tim-003-onearm',
            name: 'One Arm Row',
            muscleGroup: MuscleGroup.back,
            description: 'Heavy dumbbell row. Drive elbow back.',
            sets: _buildProSets(count: 3, reps: 10, weight: 32),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-004-facepull',
            name: 'Face Pulls',
            muscleGroup: MuscleGroup.back,
            description: 'Rope to face, external rotation at end. Rear delt focus.',
            sets: _buildProSets(count: 4, reps: 15, weight: 15),
            restSeconds: 60,
          ), // Face Pulls for rear delts
          armsExercises[0], // Bicep Curls
        ],
      ),
      // Day 3: Quad Dominant Legs
      WorkoutDay(
        id: 'day-tim-003',
        name: '🔥 Quad Killer',
        dayOfWeek: 3,
        exercises: [
          Exercise(
            id: 'ex-tim-003-legpress',
            name: 'Leg Press',
            muscleGroup: MuscleGroup.legs,
            description: 'Heavy quad focus. Full range of motion.',
            sets: _buildProSets(count: 4, reps: 8, weight: 220),
            restSeconds: 180,
          ),
          Exercise(
            id: 'ex-tim-003-ext',
            name: 'Leg Extensions',
            muscleGroup: MuscleGroup.legs,
            description: 'Squeeze at top, controlled negative.',
            sets: _buildProSets(count: 3, reps: 12, weight: 65),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-003-curl',
            name: 'Seated Leg Curl',
            muscleGroup: MuscleGroup.legs,
            description: 'Hamstring isolation. Drive heels to glutes.',
            sets: _buildProSets(count: 3, reps: 11, weight: 55),
            restSeconds: 90,
          ),
          legExercises[4], // Bulgarian Split Squats
        ],
      ),
      // Day 4: Active Recovery - Links to Cardio Log (not a workout)
      WorkoutDay(
        id: 'day-tim-004',
        name: '🔄 Active Recovery',
        dayOfWeek: 4,
        exercises: [], // Empty - will show Log Cardio button
      ),
      // Day 5: Arm Day
      WorkoutDay(
        id: 'day-tim-005',
        name: '💪 Arm Day',
        dayOfWeek: 5,
        exercises: [
          Exercise(
            id: 'ex-tim-005-skull',
            name: 'Lying Triceps Extension',
            muscleGroup: MuscleGroup.arms,
            description: 'EZ-Bar skull crusher. Elbows tucked, control the weight.',
            sets: _buildProSets(count: 3, reps: 10, weight: 10),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-005-curl',
            name: 'Curl',
            muscleGroup: MuscleGroup.arms,
            description: 'Standing EZ-Bar curl. Full range, no swinging.',
            sets: _buildProSets(count: 3, reps: 8, weight: 27),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-005-incline',
            name: 'Incline Bench Press',
            muscleGroup: MuscleGroup.chest,
            description: '30° incline. Upper chest focus.',
            sets: _buildProSets(count: 3, reps: 8, weight: 27.5),
            restSeconds: 120,
          ),
          Exercise(
            id: 'ex-tim-005-spider',
            name: 'Reverse Spider Curl',
            muscleGroup: MuscleGroup.arms,
            description: 'Face down on incline bench. Zottman curl style.',
            sets: _buildProSets(count: 3, reps: 10, weight: 10),
            restSeconds: 90,
          ),
          Exercise(
            id: 'ex-tim-005-kickback',
            name: 'Single Arm Kickback',
            muscleGroup: MuscleGroup.arms,
            description: 'Dumbbell kickback. Lock elbow, extend fully.',
            sets: _buildProSets(count: 3, reps: 12, weight: 7.5),
            restSeconds: 60,
          ),
          Exercise(
            id: 'ex-tim-005-fly',
            name: 'Pec Deck Chest Fly',
            muscleGroup: MuscleGroup.chest,
            description: 'Machine fly. Squeeze at peak contraction.',
            sets: _buildProSets(count: 3, reps: 8, weight: 55),
            restSeconds: 90,
          ),
        ],
      ),
      // Day 6: Active Recovery - Links to Cardio Log (not a workout)
      WorkoutDay(
        id: 'day-tim-006',
        name: '🔄 Active Recovery',
        dayOfWeek: 6,
        exercises: [], // Empty - will show Log Cardio button
      ),
    ],
  );

  static List<WorkoutPlan> get allPlans => [timDoodlerinoPro, push4DayPlan, fullBodyBeginner];

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
