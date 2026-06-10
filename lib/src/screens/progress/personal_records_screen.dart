import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/personal_record.dart';
import '../../providers/personal_records_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/pr/pr_celebration.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prState = ref.watch(personalRecordsProvider);
    final stats = prState.stats;
    
    // Show celebration if there's a new record
    if (prState.showCelebration && prState.lastNewRecord != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.transparent,
          builder: (_) => PRCelebration(
            record: prState.lastNewRecord!,
            onDismiss: () {
              ref.read(personalRecordsProvider.notifier).dismissCelebration();
              Navigator.of(context).pop();
            },
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Strength Hall of Fame'),
        centerTitle: true,
      ),
      body: prState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(prState.error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(personalRecordsProvider.notifier).fetchRecords();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(personalRecordsProvider.notifier).fetchRecords(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header stats
                        if (stats != null) _StatsHeader(stats: stats),
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Recent PRs section
                        if (prState.recentRecords.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Recent Achievements',
                            subtitle: '${stats?.newRecordsThisMonth ?? 0} this month',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _RecentRecordsList(records: prState.recentRecords),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // Top Records (All-time best)
                        if (prState.topRecords.isNotEmpty) ...[
                          const _SectionTitle(title: 'All-Time Bests'),
                          const SizedBox(height: AppSpacing.md),
                          _TopRecordsList(records: prState.topRecords.take(5).toList()),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        
                        // All Records Grid
                        if (prState.records.isNotEmpty) ...[
                          const _SectionTitle(title: 'All Records'),
                          const SizedBox(height: AppSpacing.md),
                          _AllRecordsGrid(records: prState.records),
                        ],
                        
                        // Empty state
                        if (prState.records.isEmpty)
                          _EmptyState(onRefresh: () {
                            ref.read(personalRecordsProvider.notifier).fetchRecords();
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final PersonalRecordStats stats;

  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: stats.totalRecords.toString(),
                  label: 'Total PRs',
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _StatBox(
                  value: stats.newRecordsThisMonth.toString(),
                  label: 'This Month',
                  icon: Icons.trending_up,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '${stats.currentStreakWeeks}',
                  label: 'Week Streak',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _StatBox(
                  value: '${(stats.totalVolumeLifted / 1000).toStringAsFixed(1)}k',
                  label: 'Total kg',
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (stats.strongestExercise != null) ...[
            const Divider(height: 24, color: AppColors.divider),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Strongest: ${stats.strongestExercise}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
      ],
    );
  }
}

class _RecentRecordsList extends StatelessWidget {
  final List<PersonalRecord> records;

  const _RecentRecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final daysAgo = DateTime.now().difference(record.achievedAt).inDays;
          
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: AppCard(
              backgroundColor: AppColors.primaryContainer.withAlpha(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(record.trophyLevel.emoji, style: const TextStyle(fontSize: 24)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          daysAgo == 0 ? 'Today' : '${daysAgo}d ago',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    record.exerciseName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${record.weightKg.toStringAsFixed(1)} kg × ${record.reps}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopRecordsList extends StatelessWidget {
  final List<PersonalRecord> records;

  const _TopRecordsList({required this.records});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: records.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : index == 2 ? '🥉' : '${index + 1}.';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    medal,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.exerciseName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'Est. 1RM: ${record.estimatedOneRepMax.toStringAsFixed(1)} kg',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${record.weightKg.toStringAsFixed(1)}kg',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AllRecordsGrid extends StatelessWidget {
  final List<PersonalRecord> records;

  const _AllRecordsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    record.trophyLevel.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const Spacer(),
                  if (record.weightBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.weightBadge!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                record.exerciseName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${record.weightKg.toStringAsFixed(1)} kg × ${record.reps}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center_outlined, size: 64, color: AppColors.onSurfaceMuted),
          const SizedBox(height: 16),
          Text(
            'No Personal Records Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete workouts and lift heavy to set your first PR!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
