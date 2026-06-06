import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/workout_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workout_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/stat_chip.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final activePlan = ref.watch(activePlanProvider);
    final sessions = ref.watch(sessionHistoryProvider);
    final thisWeekSessions = sessions
        .where((s) =>
            s.startedAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();

    final now = DateTime.now();
    final today = DateFormat('EEEE, MMM d').format(now);
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting,',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.onSurfaceMuted,
                                  ),
                            ),
                            Text(
                              user?.name ?? 'Athlete',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      today,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Weekly stats row ──
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: thisWeekSessions.length.toString(),
                            label: 'Workouts\nthis week',
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            value: '${user?.weeklyTargetDays ?? 4}',
                            label: 'Weekly\nTarget',
                            icon: Icons.flag_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            value: sessions.isEmpty
                                ? '—'
                                : '${(sessions.first.duration?.inMinutes ?? 0)} min',
                            label: 'Last\nWorkout',
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Today's Workout card ──
                    SectionHeader(
                      title: "Today's Workout",
                      actionLabel: 'All Plans',
                      onAction: () => context.go(AppRoutes.plans),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            if (activePlan != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: _TodayWorkoutCard(plan: activePlan, ref: ref),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    child: Column(
                      children: [
                        const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No active plan',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Browse our workout plans and start training.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Browse Plans',
                          onPressed: () => context.go(AppRoutes.plans),
                          width: 180,
                          height: 44,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Recent Activity',
                      actionLabel: 'See All',
                      onAction: () => context.go(AppRoutes.progress),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final session = sessions[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SessionTile(session: session),
                    );
                  },
                  childCount: sessions.length.clamp(0, 4),
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

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  final dynamic plan;
  final WidgetRef ref;

  const _TodayWorkoutCard({required this.plan, required this.ref});

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday - 1;
    final todayDay = plan.days.isNotEmpty
        ? plan.days[todayIndex % plan.days.length]
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2C24), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Active Plan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (todayDay != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Today: ${todayDay.name}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: todayDay.exercises
                  .take(4)
                  .map<Widget>((e) => StatChip(
                        label: 'exercise',
                        value: e.name,
                        icon: Icons.circle,
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Start Workout',
            onPressed: () {
              if (todayDay != null) {
                ref.read(activeSessionProvider.notifier).startSession(todayDay, plan.id);
                context.push(AppRoutes.workoutTracking);
              }
            },
            icon: Icons.play_arrow_rounded,
            height: 48,
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, MMM d').format(session.startedAt);
    final duration = session.duration != null
        ? '${session.duration!.inMinutes} min'
        : '—';

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.mdRadius,
            ),
            child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.dayName, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '$date · $duration',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${session.totalVolumeKg} kg',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              Text('volume', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
