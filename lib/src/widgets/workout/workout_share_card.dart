import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/workout_session.dart';
import '../../theme/app_colors.dart';

/// A branded, shareable summary card for a completed workout.
/// Designed at a fixed 1080x1350 aspect-friendly size for social sharing.
class WorkoutShareCard extends StatelessWidget {
  final WorkoutSession session;
  final Duration elapsed;
  final int prCount;

  const WorkoutShareCard({
    super.key,
    required this.session,
    required this.elapsed,
    this.prCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final m = elapsed.inMinutes.toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final date = DateFormat('EEEE, MMM d, yyyy').format(session.startedAt);

    return Container(
      width: 1080,
      height: 1350,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0F0D), Color(0xFF12231C), Color(0xFF0A0F0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.black, size: 56),
                ),
                const SizedBox(width: 28),
                const Text(
                  'RepRise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 90),

            // Title
            const Text(
              'WORKOUT COMPLETE',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 88,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              date,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 38,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Spacer(),

            // Stats grid
            Row(
              children: [
                _ShareStat(
                  icon: Icons.timer_outlined,
                  value: '$m:$s',
                  label: 'DURATION',
                ),
                _ShareStat(
                  icon: Icons.fitness_center,
                  value: '${session.completedExercisesCount}',
                  label: 'EXERCISES',
                ),
              ],
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                _ShareStat(
                  icon: Icons.monitor_weight_outlined,
                  value: '${session.totalVolumeKg}',
                  label: 'KG VOLUME',
                ),
                _ShareStat(
                  icon: Icons.emoji_events_outlined,
                  value: '$prCount',
                  label: prCount == 1 ? 'NEW PR' : 'NEW PRS',
                ),
              ],
            ),

            const Spacer(),

            // Footer
            Center(
              child: Text(
                'Tracked with RepRise',
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ShareStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 32),
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.primary.withAlpha(50), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 56),
            const SizedBox(height: 24),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 76,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
