import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/workout_provider.dart';
import '../../services/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionHistoryProvider).valueOrNull ?? [];
    final weeklyData = MockData.weeklyVolumeData;
    final totalVolume = sessions.fold<int>(0, (acc, s) => acc + s.totalVolumeKg);

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
                    Text('Progress', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Track your fitness journey',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Summary Cards ──
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Sessions',
                            value: sessions.length.toString(),
                            icon: Icons.fitness_center_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Total Volume',
                            value: '${(totalVolume / 1000).toStringAsFixed(1)}t',
                            icon: Icons.monitor_weight_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _SummaryCard(
                            label: 'This Week',
                            value: sessions
                                .where((s) => s.startedAt
                                    .isAfter(DateTime.now().subtract(const Duration(days: 7))))
                                .length
                                .toString(),
                            icon: Icons.calendar_view_week_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Weekly Volume Chart ──
                    const SectionHeader(title: 'Weekly Volume'),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: AppCard(
                  child: SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 7000,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= weeklyData.length) {
                                  return const SizedBox();
                                }
                                return Text(
                                  weeklyData[idx]['day'] as String,
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceMuted,
                                    fontSize: 11,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppColors.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: weeklyData.asMap().entries.map((e) {
                          final volume = (e.value['volume'] as int).toDouble();
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: volume,
                                color: volume > 0
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                                width: 24,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
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
                    const SectionHeader(title: 'Recent Sessions'),
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
                    final date = DateFormat('EEE, MMM d · HH:mm').format(session.startedAt);
                    final duration = session.duration != null
                        ? '${session.duration!.inMinutes} min'
                        : '—';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: AppRadius.mdRadius,
                              ),
                              child: const Icon(
                                Icons.fitness_center,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(session.dayName,
                                      style: Theme.of(context).textTheme.titleSmall),
                                  Text(date,
                                      style: Theme.of(context).textTheme.bodySmall),
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
                                Text(duration,
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: sessions.length,
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
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
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
