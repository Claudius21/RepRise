import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_plan.dart';
import '../models/workout_session.dart';

class WorkoutRepository {
  final SupabaseClient _client;

  WorkoutRepository(this._client);

  String get _uid => _client.auth.currentUser!.id;

  // ─── Plans ───────────────────────────────────────────────────

  Future<List<WorkoutPlan>> fetchPlans() async {
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
        .eq('user_id', _uid)
        .order('created_at');

    return (data as List).map((e) => _planFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setActivePlan(String planId) async {
    await _client
        .from('workout_plans')
        .update({'is_active': false})
        .eq('user_id', _uid);
    await _client
        .from('workout_plans')
        .update({'is_active': true})
        .eq('id', planId);
  }

  // ─── Sessions ────────────────────────────────────────────────

  Future<List<WorkoutSession>> fetchSessions({int limit = 20}) async {
    final data = await _client
        .from('workout_sessions')
        .select()
        .eq('user_id', _uid)
        .order('started_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => _sessionFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> saveSession(WorkoutSession session) async {
    final result = await _client.from('workout_sessions').insert({
      'user_id': _uid,
      'plan_id': session.planId,
      'day_id': session.dayId,
      'day_name': session.dayName,
      'started_at': session.startedAt.toIso8601String(),
      'finished_at': session.finishedAt?.toIso8601String(),
      'status': session.status.name,
      'total_volume_kg': session.totalVolumeKg,
    }).select().single();

    final sessionId = result['id'] as String;

    // Save individual sets
    final sets = <Map<String, dynamic>>[];
    for (final exercise in session.exercises) {
      for (final s in exercise.sets) {
        if (s.isCompleted) {
          sets.add({
            'session_id': sessionId,
            'exercise_id': exercise.id,
            'exercise_name': exercise.name,
            'set_number': s.setNumber,
            'reps': s.actualReps,
            'weight_kg': s.actualWeight,
            'is_completed': true,
          });
        }
      }
    }
    if (sets.isNotEmpty) {
      await _client.from('session_sets').insert(sets);
    }

    // Update personal records
    await _updatePersonalRecords(session);

    return sessionId;
  }

  Future<void> _updatePersonalRecords(WorkoutSession session) async {
    for (final exercise in session.exercises) {
      double maxWeight = 0;
      int maxReps = 0;
      for (final s in exercise.sets) {
        if (s.isCompleted && (s.actualWeight ?? 0) >= maxWeight) {
          maxWeight = s.actualWeight ?? 0;
          maxReps = s.actualReps ?? 0;
        }
      }
      if (maxWeight <= 0 && maxReps <= 0) continue;

      await _client.from('personal_records').upsert({
        'user_id': _uid,
        'exercise_id': exercise.id,
        'exercise_name': exercise.name,
        'weight_kg': maxWeight,
        'reps': maxReps,
        'achieved_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,exercise_id');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPersonalRecords() async {
    final data = await _client
        .from('personal_records')
        .select()
        .eq('user_id', _uid)
        .order('achieved_at', ascending: false);
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ─── JSON Mappers ─────────────────────────────────────────────

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

  WorkoutSession _sessionFromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      planId: json['plan_id'] as String? ?? '',
      dayId: json['day_id'] as String? ?? '',
      dayName: json['day_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      finishedAt: json['finished_at'] != null
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      status: SessionStatus.completed,
      exercises: const [],
      totalVolumeKg: json['total_volume_kg'] as int? ?? 0,
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
}
