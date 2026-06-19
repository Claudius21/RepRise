import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/subscription.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../routing/app_router.dart';

class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final subscription = subState.subscription;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Abonnement',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
      ),
      body: subState.status == SubscriptionLoadingStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : subscription == null
              ? _buildNoSubscription(context)
              : _buildSubscriptionDetails(context, ref, subState),
    );
  }

  Widget _buildNoSubscription(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.onSurfaceMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Kein Abonnement gefunden',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.paywall),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Upgrade jetzt'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails(
    BuildContext context,
    WidgetRef ref,
    SubscriptionState state,
  ) {
    final subscription = state.subscription!;
    final isInTrial = state.isInTrial;
    final isActive = state.isActiveSubscription;
    final trialDays = state.trialDaysRemaining;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          AppCard(
            backgroundColor: _getStatusColor(isInTrial, isActive),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.check_circle
                          : isInTrial
                              ? Icons.access_time
                              : Icons.info,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isInTrial
                          ? 'Testphase aktiv'
                          : isActive
                              ? 'Abonnement aktiv'
                              : subscription.status.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isInTrial) ...[
                  Text(
                    'Noch $trialDays Tage verbleibend',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  Text(
                    'Test endet am ${_formatDate(subscription.trialEndsAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ] else if (isActive && subscription.currentPeriodEnd != null) ...[
                  Text(
                    subscription.cancelAtPeriodEnd
                        ? 'Läuft am ${_formatDate(subscription.currentPeriodEnd!)} ab'
                        : 'Nächste Zahlung am ${_formatDate(subscription.currentPeriodEnd!)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  if (subscription.discountApplied)
                    Text(
                      'Rabattcode aktiv',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                    ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Plan Details
          Text(
            'Plan Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Plan',
                  value: subscription.plan?.name ?? 'ShredMembers Pro',
                ),
                const Divider(color: AppColors.divider),
                _DetailRow(
                  label: 'Preis',
                  value: subscription.plan != null
                      ? '${subscription.plan!.priceMonthly.toStringAsFixed(2)}€/Monat'
                      : '-',
                ),
                if (subscription.discountApplied) ...[
                  const Divider(color: AppColors.divider),
                  _DetailRow(
                    label: 'Rabatt',
                    value: 'Aktiv',
                    valueColor: AppColors.success,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // History
          if (subscription.subscribedAt != null) ...[
            Text(
              'Verlauf',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Registriert am',
                    value: _formatDate(subscription.trialStartedAt),
                  ),
                  const Divider(color: AppColors.divider),
                  _DetailRow(
                    label: 'Abonniert am',
                    value: _formatDate(subscription.subscribedAt!),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Actions
          if (isActive) ...[
            if (subscription.cancelAtPeriodEnd)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _reactivateSubscription(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Abonnement reaktivieren'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Abonnement kündigen'),
                ),
              ),
          ] else if (!isInTrial) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.paywall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Jetzt upgraden'),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Upgrade option during trial
          if (isInTrial)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.paywall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Jetzt upgraden (30% günstiger)'),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(bool isInTrial, bool isActive) {
    if (isActive) return AppColors.primary;
    if (isInTrial) return AppColors.warning;
    return AppColors.error;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Abonnement kündigen?',
          style: TextStyle(color: AppColors.onBackground),
        ),
        content: Text(
          'Du behältst den Zugriff bis zum Ende der aktuellen Periode. Danach wird dein Abonnement nicht erneuert.',
          style: TextStyle(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Kündigen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(subscriptionProvider.notifier).cancelSubscription();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abonnement wurde gekündigt'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _reactivateSubscription(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(subscriptionProvider.notifier).reactivateSubscription();
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abonnement wurde reaktiviert'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
