import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/personal_record.dart';
import '../../providers/personal_records_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

/// Chronological diary/log of all personal records
class PRDiaryScreen extends ConsumerWidget {
  const PRDiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prState = ref.watch(personalRecordsProvider);
    
    // Sort records by date (newest first)
    final sortedRecords = List<PersonalRecord>.from(prState.records)
      ..sort((a, b) => b.achievedAt.compareTo(a.achievedAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Personal Record Diary'),
        centerTitle: true,
      ),
      body: prState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedRecords.isEmpty
              ? _EmptyState(onRefresh: () {
                  ref.read(personalRecordsProvider.notifier).fetchRecords();
                })
              : RefreshIndicator(
                  onRefresh: () => ref.read(personalRecordsProvider.notifier).fetchRecords(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sortedRecords.length,
                    itemBuilder: (context, index) {
                      final record = sortedRecords[index];
                      final previousRecord = index < sortedRecords.length - 1
                          ? sortedRecords[index + 1]
                          : null;
                      
                      return _DiaryEntry(
                        record: record,
                        previousRecord: previousRecord,
                        isFirst: index == 0,
                      );
                    },
                  ),
                ),
    );
  }
}

class _DiaryEntry extends StatelessWidget {
  final PersonalRecord record;
  final PersonalRecord? previousRecord;
  final bool isFirst;

  const _DiaryEntry({
    required this.record,
    this.previousRecord,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final improvement = _calculateImprovement();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header with "NEW" badge
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.onSurfaceMuted,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(record.achievedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
              ),
              const Spacer(),
              if (isFirst)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Exercise name and trophy
          Row(
            children: [
              Text(
                record.trophyLevel.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.exerciseName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (record.weightBadge != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.orange.shade400],
                          ),
                          borderRadius: BorderRadius.circular(4),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Achievement details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AchievementMetric(
                  label: 'Weight',
                  value: '${record.weightKg.toStringAsFixed(1)} kg',
                  icon: Icons.fitness_center,
                ),
                _AchievementMetric(
                  label: 'Reps',
                  value: '${record.reps}',
                  icon: Icons.repeat,
                ),
                _AchievementMetric(
                  label: 'Est. 1RM',
                  value: '${record.estimatedOneRepMax.toStringAsFixed(1)} kg',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),
          
          // Improvement indicator
          if (improvement != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    improvement,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
  }

  String? _calculateImprovement() {
    // In a real implementation, compare with previous PR for same exercise
    // For now, just show the PR level
    if (record.trophyLevel == TrophyLevel.gold) {
      return 'New Gold Trophy achieved!';
    } else if (record.weightBadge != null) {
      return 'New milestone: ${record.weightBadge}';
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday at ${_formatTime(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _AchievementMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AchievementMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.book_outlined, size: 64, color: AppColors.onSurfaceMuted),
          const SizedBox(height: 16),
          Text(
            'Your PR Diary is Empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete sets with heavy weights to start your record book!',
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
