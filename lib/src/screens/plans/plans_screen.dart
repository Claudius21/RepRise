import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/workout_plan.dart';
import '../../providers/workout_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(workoutPlansProvider).valueOrNull ?? [];
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workout Plans', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${plans.length} available plans',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: isWide
                  ? SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        mainAxisExtent: 240,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _PlanCard(plan: plans[i]),
                        childCount: plans.length,
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlanCard(plan: plans[i]),
                        ),
                        childCount: plans.length,
                      ),
                    ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final WorkoutPlan plan;

  const _PlanCard({required this.plan});

  Color _difficultyColor(DifficultyLevel level) => switch (level) {
        DifficultyLevel.beginner => const Color(0xFF4CAF50),
        DifficultyLevel.intermediate => AppColors.warning,
        DifficultyLevel.advanced => AppColors.error,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffColor = _difficultyColor(plan.difficulty);

    return AppCard(
      onTap: () => context.push(
        AppRoutes.workoutDetail,
        extra: {'plan': plan, 'dayIndex': 0},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    Text(plan.name, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: diffColor.withAlpha(25),
                  borderRadius: AppRadius.fullRadius,
                  border: Border.all(color: diffColor.withAlpha(80)),
                ),
                child: Text(
                  plan.difficulty.label,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            plan.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: '${plan.durationWeeks}w',
              ),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                icon: Icons.repeat_rounded,
                label: '${plan.trainingDaysPerWeek}x/week',
              ),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                icon: Icons.fitness_center_outlined,
                label: '${plan.totalExercises} exercises',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(
                    AppRoutes.workoutDetail,
                    extra: {'plan': plan, 'dayIndex': 0},
                  ),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('View'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.planEdit, extra: plan),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              if (!plan.isActive) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        ref.read(workoutPlansProvider.notifier).setActive(plan.id),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: const Text('Activate'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
