import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/exercise.dart';
import '../../models/workout_plan.dart';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ConfettiController _confettiCtrl;
  int _prevLifting = 0;
  int _prevCardio = 0;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final activePlan = ref.watch(activePlanProvider);
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final thisWeekSessions = sessions
        .where((s) =>
            s.startedAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .toList();
    final thisWeekLifting = thisWeekSessions.where((s) => !s.isCardio).length;
    final thisWeekCardio = thisWeekSessions.where((s) => s.isCardio).length;
    final weeklyTarget = user?.weeklyTargetDays ?? 4;

    // Fire confetti when lifting or cardio hits the weekly target
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final liftingJustHit = thisWeekLifting >= weeklyTarget && _prevLifting < weeklyTarget;
      final cardioJustHit = thisWeekCardio >= weeklyTarget && _prevCardio < weeklyTarget;
      if (liftingJustHit || cardioJustHit) {
        _confettiCtrl.play();
        _showTargetDialog(liftingJustHit ? 'Lifting' : 'Cardio');
      }
      _prevLifting = thisWeekLifting;
      _prevCardio = thisWeekCardio;
    });

    final now = DateTime.now();
    final today = DateFormat('EEEE, MMM d').format(now);
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 18
            ? 'Good Afternoon'
            : 'Good Evening';

    return Stack(
      children: [
      Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(sessionHistoryProvider.future),
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
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Column(
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
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.profile),
                          child: Container(
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
                            value: '$thisWeekLifting',
                            label: 'Lifting\nthis week',
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            value: '$thisWeekCardio',
                            label: 'Cardio\nthis week',
                            icon: Icons.directions_run,
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
                  child: _TodayWorkoutCard(plan: activePlan),
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: () => _showLogCardio(context, ref),
                  icon: const Icon(Icons.directions_run, size: 18),
                  label: const Text('Log Cardio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withAlpha(120)),
                    minimumSize: const Size(double.infinity, 44),
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
            if (sessions.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: AppCard(
                    child: Column(
                      children: [
                        const Icon(Icons.history, color: AppColors.onSurfaceMuted, size: 40),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No workouts yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Complete your first workout to see it here!',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
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
      ),
      ),
      // Confetti overlay
      Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiCtrl,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 40,
          gravity: 0.2,
          colors: const [
            AppColors.primary,
            Colors.white,
            Color(0xFF00E676),
            Color(0xFFFFD700),
            Color(0xFFFF6B6B),
          ],
        ),
      ),
      ],
    );
  }

  void _showTargetDialog(String type) {
    final icon = type == 'Lifting' ? '🏋️' : '🏃';
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              'Weekly $type Target Hit!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Amazing work – you\'ve reached your $type goal for this week! 🎉',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Keep it up! 💪',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLogCardio(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _LogCardioSheet(ref: ref),
  );
}

class _LogCardioSheet extends StatefulWidget {
  final WidgetRef ref;
  const _LogCardioSheet({required this.ref});

  @override
  State<_LogCardioSheet> createState() => _LogCardioSheetState();
}

class _LogCardioSheetState extends State<_LogCardioSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Running';
  int _minutes = 30;
  double _distanceKm = 0;
  int _calories = 0;
  bool _saving = false;

  static const _cardioTypes = [
    'Running', 'Cycling', 'Swimming', 'Rowing',
    'Elliptical', 'Jump Rope', 'Walking', 'Other',
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _saving = true);
    final now = DateTime.now();
    final session = WorkoutSession(
      id: 'session-live-${now.millisecondsSinceEpoch}',
      planId: '',
      dayId: '',
      dayName: _type,
      startedAt: now.subtract(Duration(minutes: _minutes)),
      finishedAt: now,
      status: SessionStatus.completed,
      exercises: const [],
      totalVolumeKg: 0,
      sessionType: SessionType.cardio,
      cardioMinutes: _minutes,
      distanceKm: _distanceKm > 0 ? _distanceKm : null,
      caloriesBurned: _calories > 0 ? _calories : null,
    );
    await widget.ref.read(sessionHistoryProvider.notifier).addSession(session);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceMuted.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Log Cardio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xl),
            DropdownButtonFormField<String>(
              value: _type,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(
                labelText: 'Activity type',
                prefixIcon: Icon(Icons.directions_run, color: AppColors.onSurfaceMuted),
              ),
              items: _cardioTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: _minutes.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                prefixIcon: Icon(Icons.timer_outlined, color: AppColors.onSurfaceMuted),
              ),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid duration';
                return null;
              },
              onSaved: (v) => _minutes = int.tryParse(v ?? '') ?? 30,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Distance (km) – optional',
                prefixIcon: Icon(Icons.straighten, color: AppColors.onSurfaceMuted),
              ),
              onSaved: (v) => _distanceKm = double.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories burned – optional',
                prefixIcon: Icon(Icons.local_fire_department_outlined, color: AppColors.onSurfaceMuted),
              ),
              onSaved: (v) => _calories = int.tryParse(v ?? '') ?? 0,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Save',
              onPressed: _save,
              isLoading: _saving,
            ),
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

class _TodayWorkoutCard extends ConsumerWidget {
  final WorkoutPlan plan;

  const _TodayWorkoutCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];

    WorkoutDay? todayDay;
    if (plan.days.isNotEmpty) {
      final days = List.from(plan.days)
        ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

      // Find last completed day index in plan
      final lastDayId = sessions
          .where((s) => s.planId == plan.id)
          .map((s) => s.dayId)
          .firstWhere((_) => true, orElse: () => '');

      final lastIdx = lastDayId.isEmpty
          ? -1
          : days.indexWhere((d) => d.id == lastDayId);

      final nextIdx = (lastIdx + 1) % days.length;
      todayDay = days[nextIdx];
    }

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

class _SessionTile extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionTile({required this.session});

  void _showSessionDetails(BuildContext context, WorkoutSession current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SessionDetailsSheet(session: current),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete workout?'),
        content: const Text('This entry will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sessionHistoryProvider.notifier).deleteSession(session.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(sessionHistoryProvider).valueOrNull
        ?.firstWhere((s) => s.id == session.id, orElse: () => session) ?? session;
    final date = DateFormat('EEE, MMM d').format(live.startedAt);
    final duration = live.isCardio
        ? '${live.cardioMinutes ?? 0} min'
        : (live.duration != null ? '${live.duration!.inMinutes} min' : '—');

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withAlpha(200),
          borderRadius: AppRadius.mdRadius,
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete workout?'),
            content: const Text('This entry will be permanently deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) =>
          ref.read(sessionHistoryProvider.notifier).deleteSession(session.id),
      child: AppCard(
      onTap: () => _showSessionDetails(context, live),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Icon(
              live.isCardio ? Icons.directions_run : Icons.fitness_center,
              color: AppColors.primary, size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(live.dayName, style: Theme.of(context).textTheme.titleSmall),
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
                live.isCardio
                    ? (live.distanceKm != null && live.distanceKm! > 0
                        ? '${live.distanceKm!.toStringAsFixed(1)} km'
                        : '${live.cardioMinutes ?? 0} min')
                    : '${live.totalVolumeKg} kg',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
              Text('volume', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

bool _isSynced(String id) => RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(id);

class _SessionDetailsSheet extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionDetailsSheet({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateFormat('EEEE, MMM d, yyyy').format(session.startedAt);
    final time = DateFormat('HH:mm').format(session.startedAt);
    final duration = session.duration != null
        ? '${session.duration!.inMinutes} min'
        : '—';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      session.isCardio ? Icons.directions_run : Icons.check_rounded,
                      color: Colors.black, size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.dayName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$date at $time',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DetailStat(
                    icon: Icons.timer_outlined,
                    value: session.isCardio
                        ? '${session.cardioMinutes ?? 0} min'
                        : duration,
                    label: 'Duration',
                  ),
                  if (session.isCardio) ...[                    
                    _DetailStat(
                      icon: Icons.straighten,
                      value: session.distanceKm != null && session.distanceKm! > 0
                          ? '${session.distanceKm!.toStringAsFixed(1)} km'
                          : '—',
                      label: 'Distance',
                    ),
                    _DetailStat(
                      icon: Icons.local_fire_department_outlined,
                      value: session.caloriesBurned != null
                          ? '${session.caloriesBurned} kcal'
                          : '—',
                      label: 'Calories',
                    ),
                  ] else ...[                    
                    _DetailStat(
                      icon: Icons.fitness_center,
                      value: '${session.exercises.length}',
                      label: 'Exercises',
                    ),
                    _DetailStat(
                      icon: Icons.monitor_weight_outlined,
                      value: '${session.totalVolumeKg}',
                      label: 'kg Volume',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (!_isSynced(session.id)) {
                          await ref.refresh(sessionHistoryProvider.future);
                          if (context.mounted) Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => _SessionEditSheet(session: session),
                        );
                      },
                      icon: Icon(
                        _isSynced(session.id) ? Icons.edit_outlined : Icons.sync,
                        size: 18,
                      ),
                      label: Text(_isSynced(session.id) ? 'Edit' : 'Sync now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withAlpha(120)),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: const Text('Delete workout?'),
                            content: const Text('This entry will be permanently deleted.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await ref
                              .read(sessionHistoryProvider.notifier)
                              .deleteSession(session.id);
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Exercises (only for strength sessions)
              if (!session.isCardio) ...[
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                ...session.exercises.map((exercise) => _ExerciseDetailCard(exercise: exercise)),
              ],
              
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseDetailCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        backgroundColor: AppColors.card,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: completedSets == exercise.sets.length
                      ? AppColors.primary
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completedSets == exercise.sets.length ? Icons.check : Icons.fitness_center,
                  color: completedSets == exercise.sets.length ? Colors.black : AppColors.onSurfaceMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$completedSets/${exercise.sets.length} sets completed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Sets
          ...exercise.sets.where((s) => s.isCompleted).map((set) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 52),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${set.setNumber}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${set.actualReps ?? set.targetReps} reps · ${(set.actualWeight ?? set.targetWeight).toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          )),
        ],
        ),
      ),
    );
  }
}

class _SessionEditSheet extends ConsumerStatefulWidget {
  final WorkoutSession session;
  const _SessionEditSheet({required this.session});

  @override
  ConsumerState<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends ConsumerState<_SessionEditSheet> {
  late List<Exercise> _exercises;
  bool _saving = false;

  // Cardio fields
  late TextEditingController _cardioMinutesCtrl;
  late TextEditingController _distanceCtrl;
  late TextEditingController _caloriesCtrl;
  late String _cardioType;

  static const _cardioTypes = [
    'Running', 'Cycling', 'Swimming', 'Rowing',
    'Elliptical', 'Jump Rope', 'Walking', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _exercises = widget.session.exercises
        .map((e) => e.copyWith(
              sets: e.sets
                  .map((s) => s.copyWith(
                        actualReps: s.actualReps ?? 0,
                        actualWeight: s.actualWeight ?? 0.0,
                      ))
                  .toList(),
            ))
        .toList();
    _cardioType = _cardioTypes.contains(widget.session.dayName)
        ? widget.session.dayName
        : 'Other';
    _cardioMinutesCtrl = TextEditingController(
        text: (widget.session.cardioMinutes ?? 0).toString());
    _distanceCtrl = TextEditingController(
        text: widget.session.distanceKm != null
            ? widget.session.distanceKm!.toStringAsFixed(1)
            : '');
    _caloriesCtrl = TextEditingController(
        text: widget.session.caloriesBurned != null
            ? widget.session.caloriesBurned.toString()
            : '');
  }

  @override
  void dispose() {
    _cardioMinutesCtrl.dispose();
    _distanceCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  void _updateSet(int exIdx, int setIdx, {int? reps, double? weight}) {
    setState(() {
      final old = _exercises[exIdx].sets[setIdx];
      final updated = old.copyWith(
        actualReps: reps ?? old.actualReps ?? 0,
        actualWeight: weight ?? old.actualWeight ?? 0.0,
      );
      final newSets = List<ExerciseSet>.from(_exercises[exIdx].sets);
      newSets[setIdx] = updated;
      _exercises[exIdx] = _exercises[exIdx].copyWith(sets: newSets);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final WorkoutSession updated;
      if (widget.session.isCardio) {
        updated = widget.session.copyWith(
          dayName: _cardioType,
          cardioMinutes: int.tryParse(_cardioMinutesCtrl.text) ?? widget.session.cardioMinutes,
          distanceKm: double.tryParse(_distanceCtrl.text),
          caloriesBurned: int.tryParse(_caloriesCtrl.text),
        );
      } else {
        final exercisesWithCompleted = _exercises.map((e) => e.copyWith(
          sets: e.sets.map((s) => s.copyWith(
            isCompleted: true,
            actualReps: s.actualReps ?? s.targetReps,
            actualWeight: s.actualWeight ?? s.targetWeight,
          )).toList(),
        )).toList();
        final totalVolume = exercisesWithCompleted
            .expand((e) => e.sets)
            .fold<double>(0, (sum, s) => sum + (s.actualReps ?? 0) * (s.actualWeight ?? 0));
        updated = widget.session.copyWith(
          exercises: exercisesWithCompleted,
          totalVolumeKg: totalVolume.round(),
        );
      }
      await ref.read(sessionHistoryProvider.notifier).updateSession(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.session.dayName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  TextButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded),
                    label: const Text('Save'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.session.isCardio) ...[
                DropdownButtonFormField<String>(
                  value: _cardioType,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(
                    labelText: 'Activity type',
                    prefixIcon: Icon(Icons.directions_run, color: AppColors.onSurfaceMuted),
                  ),
                  items: _cardioTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _cardioType = v ?? _cardioType),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _cardioMinutesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    prefixIcon: Icon(Icons.timer_outlined, color: AppColors.onSurfaceMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _distanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Distance (km) – optional',
                    prefixIcon: Icon(Icons.straighten, color: AppColors.onSurfaceMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _caloriesCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories burned – optional',
                    prefixIcon: Icon(Icons.local_fire_department_outlined, color: AppColors.onSurfaceMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ] else ...[
              ..._exercises.asMap().entries.map((exEntry) {
                final exIdx = exEntry.key;
                final exercise = exEntry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                        const SizedBox(height: AppSpacing.md),
                        ...exercise.sets.map((set) {
                          final setIdx = exercise.sets
                              .indexWhere((s) => s.setNumber == set.setNumber);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: set.isCompleted
                                        ? AppColors.primary.withAlpha(30)
                                        : AppColors.surfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${set.setNumber}',
                                        style: TextStyle(
                                          color: set.isCompleted
                                              ? AppColors.primary
                                              : AppColors.onSurfaceMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: '${set.actualReps ?? 0}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Reps',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                    onChanged: (v) => _updateSet(exIdx, setIdx,
                                        reps: int.tryParse(v)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: (set.actualWeight ?? 0.0).toStringAsFixed(1),
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'kg',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                    ),
                                    onChanged: (v) => _updateSet(exIdx, setIdx,
                                        weight: double.tryParse(v)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
              ], // end else (strength)
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
