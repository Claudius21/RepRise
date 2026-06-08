import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../providers/workout_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class WorkoutTrackingScreen extends ConsumerStatefulWidget {
  const WorkoutTrackingScreen({super.key});

  @override
  ConsumerState<WorkoutTrackingScreen> createState() => _WorkoutTrackingScreenState();
}

class _WorkoutTrackingScreenState extends ConsumerState<WorkoutTrackingScreen> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _finishWorkout() {
    final session = ref.read(activeSessionProvider.notifier).finishSession(ref);
    if (session != null && mounted) {
      _timer.cancel();
      _showCompletionSheet(session);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeSessionProvider.notifier).cancelSession();
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            child: const Text('Cancel Workout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showCompletionSheet(WorkoutSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CompletionSheet(
        session: session,
        elapsed: _elapsed,
        onDone: () {
          context.go(AppRoutes.home);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeSessionProvider);

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(AppRoutes.home);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completedSets = session.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.where((s) => s.isCompleted).length,
    );
    final totalSets = session.exercises.fold<int>(
      0,
      (acc, e) => acc + e.sets.length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          children: [
            Text(session.dayName, style: Theme.of(context).textTheme.titleMedium),
            Text(
              _formatDuration(_elapsed),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _confirmCancel,
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text(
              'Finish',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedSets / $totalSets sets',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      totalSets > 0
                          ? '${((completedSets / totalSets) * 100).toInt()}%'
                          : '0%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: AppRadius.fullRadius,
                  child: LinearProgressIndicator(
                    value: totalSets > 0 ? completedSets / totalSets : 0,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: session.exercises.length + 1, // +1 for finish button
              itemBuilder: (ctx, i) {
                if (i == session.exercises.length) {
                  // Finish Workout button at the bottom
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 32),
                    child: ElevatedButton.icon(
                      onPressed: _finishWorkout,
                      icon: const Icon(Icons.check_circle, size: 24),
                      label: const Text(
                        'Finish Workout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TrackingExerciseCard(
                    exercise: session.exercises[i],
                    index: i,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingExerciseCard extends ConsumerWidget {
  final Exercise exercise;
  final int index;

  const _TrackingExerciseCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFullyDone = exercise.isCompleted;

    return AppCard(
      backgroundColor: isFullyDone
          ? AppColors.primaryContainer.withAlpha(80)
          : AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isFullyDone ? AppColors.primary : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFullyDone ? Icons.check_rounded : Icons.fitness_center,
                  size: 16,
                  color: isFullyDone ? Colors.black : AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isFullyDone
                                ? AppColors.primary
                                : AppColors.onBackground,
                          ),
                    ),
                    Text(
                      '${exercise.completedSets}/${exercise.sets.length} sets · ${exercise.restSeconds}s rest',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Set rows
          ...exercise.sets.asMap().entries.map((entry) {
            final s = entry.value;
            return _SetRow(
              set: s,
              exerciseId: exercise.id,
              canRemove: exercise.sets.length > 1,
              onToggle: () => ref
                  .read(activeSessionProvider.notifier)
                  .toggleSet(exercise.id, s.id),
              onRemove: () => ref
                  .read(activeSessionProvider.notifier)
                  .removeSet(exercise.id, s.id),
              onEditReps: (reps) => ref
                  .read(activeSessionProvider.notifier)
                  .updateSetValues(exercise.id, s.id, reps: reps),
              onEditWeight: (weight) => ref
                  .read(activeSessionProvider.notifier)
                  .updateSetValues(exercise.id, s.id, weight: weight),
            );
          }),
          // Add set button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: () => ref
                  .read(activeSessionProvider.notifier)
                  .addSet(exercise.id),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Set'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final ExerciseSet set;
  final String exerciseId;
  final bool canRemove;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final Function(int) onEditReps;
  final Function(double) onEditWeight;

  const _SetRow({
    required this.set,
    required this.exerciseId,
    required this.canRemove,
    required this.onToggle,
    required this.onRemove,
    required this.onEditReps,
    required this.onEditWeight,
  });

  void _showEditDialog(BuildContext context, {bool isReps = true}) {
    final controller = TextEditingController(
      text: isReps
          ? (set.actualReps ?? set.targetReps).toString()
          : (set.actualWeight ?? set.targetWeight).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(isReps ? 'Edit Reps' : 'Edit Weight (kg)'),
        content: TextField(
          controller: controller,
          keyboardType: isReps ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            hintText: isReps ? 'Enter reps' : 'Enter weight in kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (isReps) {
                final value = int.tryParse(controller.text);
                if (value != null && value > 0) {
                  onEditReps(value);
                }
              } else {
                final value = double.tryParse(controller.text.replaceAll(',', '.'));
                if (value != null && value > 0) {
                  onEditWeight(value);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actualReps = set.actualReps ?? set.targetReps;
    final actualWeight = set.actualWeight ?? set.targetWeight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: set.isCompleted ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: set.isCompleted ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
              ),
              child: set.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Set number
          Expanded(
            child: Text(
              'Set ${set.setNumber}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          // Reps - editable
          GestureDetector(
            onTap: () => _showEditDialog(context, isReps: true),
            child: _ValueBadge(
              value: '${actualReps} reps',
              isDone: set.isCompleted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Weight - editable
          GestureDetector(
            onTap: () => _showEditDialog(context, isReps: false),
            child: _ValueBadge(
              value: actualWeight > 0
                  ? '${actualWeight.toStringAsFixed(1)} kg'
                  : 'BW',
              isDone: set.isCompleted,
              isAccent: true,
            ),
          ),
          // Remove button (if more than 1 set)
          if (canRemove) ...[
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.remove_circle_outline,
                size: 20,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueBadge extends StatelessWidget {
  final String value;
  final bool isDone;
  final bool isAccent;

  const _ValueBadge({
    required this.value,
    required this.isDone,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary.withAlpha(20)
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDone
                  ? AppColors.primary
                  : isAccent
                      ? AppColors.primary
                      : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _CompletionSheet extends StatelessWidget {
  final WorkoutSession session;
  final Duration elapsed;
  final VoidCallback onDone;

  const _CompletionSheet({
    required this.session,
    required this.elapsed,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: Colors.black, size: 44),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Workout Complete!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            session.dayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CompletionStat(
                icon: Icons.timer_outlined,
                value: '$m:$s',
                label: 'Duration',
              ),
              _CompletionStat(
                icon: Icons.fitness_center,
                value: '${session.completedExercisesCount}',
                label: 'Exercises',
              ),
              _CompletionStat(
                icon: Icons.monitor_weight_outlined,
                value: '${session.totalVolumeKg}',
                label: 'kg volume',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: onDone,
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _CompletionStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
