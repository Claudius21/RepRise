import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'workout_templates.dart';

/// Repository for importing built-in workout templates to Supabase.
/// Users can import these as starting points and customize them.
class TemplateRepository {
  final SupabaseClient _client;

  TemplateRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  /// Get all available templates (local, not from Supabase)
  List<WorkoutPlan> get availableTemplates => WorkoutTemplates.all;

  /// Import a template to the user's library.
  /// Creates new records in workout_plans, workout_days, and day_exercises tables.
  Future<WorkoutPlan> importTemplate(WorkoutPlan template) async {
    // Generate new IDs for the imported plan
    final newPlanId = _generateId();

    // Create the plan
    await _client.from('workout_plans').insert({
      'id': newPlanId,
      'user_id': _uid,
      'name': template.name,
      'description': template.description,
      'difficulty': template.difficulty.name,
      'duration_weeks': template.durationWeeks,
      'is_active': false,
      'is_template': false,
    });

    // Create days and exercises
    for (final day in template.days) {
      final newDayId = _generateId();

      await _client.from('workout_days').insert({
        'id': newDayId,
        'plan_id': newPlanId,
        'name': day.name,
        'day_of_week': day.dayOfWeek,
        'sort_order': day.dayOfWeek,
      });

      // Insert day exercises
      for (final exercise in day.exercises) {
        await _client.from('day_exercises').insert({
          'id': _generateId(),
          'day_id': newDayId,
          'exercise_id': exercise.id,
          'sort_order': exercise.sets.first.setNumber,
          'sets': exercise.sets.length,
          'target_reps': exercise.sets.first.targetReps,
          'target_weight': exercise.sets.first.targetWeight,
          'rest_seconds': exercise.restSeconds,
        });
      }
    }

    // Fetch the newly created plan to return it
    return _fetchPlanById(newPlanId);
  }

  /// Import all templates at once
  Future<List<WorkoutPlan>> importAllTemplates() async {
    final imported = <WorkoutPlan>[];
    for (final template in WorkoutTemplates.all) {
      final importedPlan = await importTemplate(template);
      imported.add(importedPlan);
    }
    return imported;
  }

  /// Check if user has any plans already (to avoid duplicate imports)
  Future<bool> hasPlans() async {
    final data = await _client
        .from('workout_plans')
        .select()
        .eq('user_id', _uid)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  Future<WorkoutPlan> _fetchPlanById(String planId) async {
    final data = await _client
        .from('workout_plans')
        .select('''
          *,
          workout_days (
            *,
            day_exercises (
              *,
              exercises (*)
            )
          )
        ''')
        .eq('id', planId)
        .single();

    return _planFromJson(data as Map<String, dynamic>);
  }

  WorkoutPlan _planFromJson(Map<String, dynamic> json) {
    final days = (json['workout_days'] as List? ?? [])
        .map((d) => _dayFromJson(d as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      difficulty: _parseDifficulty(json['difficulty'] as String?),
      durationWeeks: json['duration_weeks'] as int? ?? 8,
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      days: days,
    );
  }

  WorkoutDay _dayFromJson(Map<String, dynamic> json) {
    final exercises = (json['day_exercises'] as List? ?? [])
        .map((e) => _exerciseFromDayJson(e as Map<String, dynamic>))
        .toList();

    return WorkoutDay(
      id: json['id'] as String,
      name: json['name'] as String,
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      exercises: exercises,
    );
  }

  Exercise _exerciseFromDayJson(Map<String, dynamic> json) {
    final ex = json['exercises'] as Map<String, dynamic>;
    final setCount = json['sets'] as int? ?? 3;
    final targetReps = json['target_reps'] as int? ?? 10;
    final targetWeight = (json['target_weight'] as num?)?.toDouble() ?? 0;
    final restSeconds = json['rest_seconds'] as int? ?? 90;

    return Exercise(
      id: ex['id'] as String,
      name: ex['name'] as String,
      muscleGroup: _parseMuscleGroup(ex['muscle_group'] as String?),
      description: ex['description'] as String?,
      restSeconds: restSeconds,
      sets: List.generate(
        setCount,
        (i) => ExerciseSet(
          id: '${ex['id']}-set-$i',
          setNumber: i + 1,
          targetReps: targetReps,
          targetWeight: targetWeight,
        ),
      ),
    );
  }

  DifficultyLevel _parseDifficulty(String? v) => switch (v) {
    'beginner' => DifficultyLevel.beginner,
    'advanced' => DifficultyLevel.advanced,
    _ => DifficultyLevel.intermediate,
  };

  MuscleGroup _parseMuscleGroup(String? v) => switch (v) {
    'chest' => MuscleGroup.chest,
    'back' => MuscleGroup.back,
    'shoulders' => MuscleGroup.shoulders,
    'arms' => MuscleGroup.arms,
    'legs' => MuscleGroup.legs,
    'core' => MuscleGroup.core,
    'cardio' => MuscleGroup.cardio,
    _ => MuscleGroup.fullBody,
  };

  String _generateId() => '${DateTime.now().millisecondsSinceEpoch}_${_uid.substring(0, 8)}';
}
