import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
import '../../providers/workout_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final WorkoutPlan plan;
  final int dayIndex;

  const WorkoutDetailScreen({
    super.key,
    required this.plan,
    required this.dayIndex,
  });

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedDayIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.dayIndex;
    _tabController = TabController(
      length: widget.plan.days.length,
      vsync: this,
      initialIndex: _selectedDayIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedDayIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  WorkoutDay get selectedDay => widget.plan.days[_selectedDayIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A2C24), AppColors.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.fullRadius,
                        ),
                        child: Text(
                          widget.plan.difficulty.label,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.plan.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.plan.durationWeeks} weeks · ${widget.plan.trainingDaysPerWeek}x/week',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppColors.background,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.onSurfaceMuted,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: widget.plan.days
                      .map((d) => Tab(text: d.name))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: widget.plan.days.map((day) => _DayView(day: day, plan: widget.plan, ref: ref)).toList(),
        ),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
  final WorkoutDay day;
  final WorkoutPlan plan;
  final WidgetRef ref;

  const _DayView({required this.day, required this.plan, required this.ref});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.name, style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        day.name.contains('Active Recovery')
                            ? 'Rest day · Log your cardio'
                            : '${day.exercises.length} exercises · ~${day.estimatedMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (day.name.contains('Active Recovery'))
                  ElevatedButton.icon(
                    onPressed: () {
                      context.go(AppRoutes.home);
                    },
                    icon: const Icon(Icons.directions_walk_rounded, size: 18),
                    label: const Text('Log Cardio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(activeSessionProvider.notifier).startSession(day, plan.id);
                      context.push(AppRoutes.workoutTracking);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 16)),
        if (day.name.contains('Active Recovery'))
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Recommended: Walk 60 min',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseCard(exercise: day.exercises[i], index: i),
                ),
                childCount: day.exercises.length,
              ),
            ),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final int index;

  const _ExerciseCard({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      exercise.muscleGroup.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.fullRadius,
                ),
                child: Text(
                  '${exercise.restSeconds}s rest',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (exercise.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              exercise.description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Sets table header
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text('Set',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Reps',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Weight',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...exercise.sets.map(
            (s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Text(
                      'Set ${s.setNumber}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.targetReps}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.targetWeight > 0 ? '${s.targetWeight.toStringAsFixed(1)} kg' : 'BW',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
