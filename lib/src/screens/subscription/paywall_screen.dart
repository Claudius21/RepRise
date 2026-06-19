import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';
import '../../routing/app_router.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPlan = 'yearly'; // 'monthly' oder 'yearly'
  final _discountController = TextEditingController();
  bool _isValidatingDiscount = false;
  bool _isStartingCheckout = false;

  @override
  void initState() {
    super.initState();
    // Lade Subscription-Daten
    Future.microtask(() {
      ref.read(subscriptionProvider.notifier).loadSubscription();
    });
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final trialDays = subState.trialDaysRemaining;
    final isExpired = subState.isExpired;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(trialDays, isExpired),
            ),
            
            // Features
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildFeatures(),
              ),
            ),

            // Plan Auswahl
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildPlanSelection(subState),
              ),
            ),

            // Discount Code
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildDiscountCode(subState),
              ),
            ),

            // CTA Button
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildCTAButton(subState),
              ),
            ),

            // Trial Info
            if (!isExpired && trialDays > 0)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverToBoxAdapter(
                  child: _buildTrialInfo(trialDays),
                ),
              ),

            // Footer
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: _buildFooter(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int trialDays, bool isExpired) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          // Crown Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.onPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isExpired ? 'Dein Testzeitraum ist abgelaufen' : 'ShredMembers Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isExpired
                ? 'Schalte alle Features frei und erreiche deine Fitness-Ziele'
                : 'Nutze alle Premium-Features und bringe dein Training auf das nächste Level',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
            textAlign: TextAlign.center,
          ),
          if (!isExpired && trialDays > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$trialDays Tage verbleibend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      ('Unbegrenzte Trainingspläne', Icons.fitness_center),
      ('Detaillierte Fortschrittsanalyse', Icons.show_chart),
      ('Personal Records Tracking', Icons.emoji_events),
      ('Alle Übungen freigeschaltet', Icons.sports_gymnastics),
      ('Werbefrei', Icons.block),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enthaltene Features',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...features.map((feature) => _FeatureItem(
            icon: feature.$2,
            text: feature.$1,
          )),
        ],
      ),
    );
  }

  Widget _buildPlanSelection(SubscriptionState state) {
    if (state.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = state.plans.first;
    final hasDiscount = state.appliedDiscount != null;
    final discountPercent = state.appliedDiscount?.discountPercent ?? 0;

    double monthlyPrice = plan.priceMonthly;
    double yearlyPrice = plan.priceYearly;

    if (hasDiscount && state.appliedDiscount != null) {
      final discount = state.appliedDiscount!.discountPercent / 100;
      monthlyPrice = monthlyPrice * (1 - discount);
      yearlyPrice = yearlyPrice * (1 - discount);
    }

    return Column(
      children: [
        // Jahresplan (Best Value)
        _PlanCard(
          title: 'Jährlich',
          subtitle: 'Bestes Angebot',
          price: '${yearlyPrice.toStringAsFixed(2)}€',
          period: '/Jahr',
          badge: '2 Monate geschenkt',
          isSelected: _selectedPlan == 'yearly',
          onTap: () => setState(() => _selectedPlan = 'yearly'),
          originalPrice: hasDiscount ? '${plan.priceYearly.toStringAsFixed(2)}€' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        // Monatsplan
        _PlanCard(
          title: 'Monatlich',
          subtitle: 'Flexibel kündbar',
          price: '${monthlyPrice.toStringAsFixed(2)}€',
          period: '/Monat',
          isSelected: _selectedPlan == 'monthly',
          onTap: () => setState(() => _selectedPlan = 'monthly'),
          originalPrice: hasDiscount ? '${plan.priceMonthly.toStringAsFixed(2)}€' : null,
        ),
      ],
    );
  }

  Widget _buildDiscountCode(SubscriptionState state) {
    final hasDiscount = state.appliedDiscount != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rabattcode',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountController,
                enabled: !hasDiscount,
                style: const TextStyle(color: AppColors.onBackground),
                decoration: InputDecoration(
                  hintText: 'Code eingeben',
                  hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: hasDiscount
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : null,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (!hasDiscount)
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _isValidatingDiscount ? null : _validateDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isValidatingDiscount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.onSurface,
                          ),
                        )
                      : const Text('Anwenden'),
                ),
              )
            else
              TextButton(
                onPressed: () {
                  ref.read(subscriptionProvider.notifier).clearDiscount();
                  _discountController.clear();
                },
                child: const Text('Entfernen'),
              ),
          ],
        ),
        if (hasDiscount) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${state.appliedDiscount!.discountPercent}% Rabatt angewendet!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCTAButton(SubscriptionState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isStartingCheckout ? null : _startCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isStartingCheckout
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : Text(
                    'Jetzt upgraden',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
          ),
        ),
        if (state.appliedDiscount != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Rabatt wird im Checkout angewendet',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildTrialInfo(int trialDays) {
    return AppCard(
      backgroundColor: AppColors.surfaceVariant,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Du hast noch $trialDays Tage Zeit, alle Features kostenlos zu testen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final subState = ref.watch(subscriptionProvider);
    final trialDays = subState.trialDaysRemaining;
    final isExpired = subState.isExpired;

    return Column(
      children: [
        if (!isExpired && trialDays > 0)
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(
              'Weiter – noch $trialDays Tag${trialDays == 1 ? '' : 'e'} kostenlos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          )
        else
          TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: Text(
              'Vielleicht später',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sichere Zahlung via Stripe. Jederzeit kündbar.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _validateDiscount() async {
    setState(() => _isValidatingDiscount = true);
    
    final code = _discountController.text.trim();
    if (code.isEmpty) {
      setState(() => _isValidatingDiscount = false);
      return;
    }

    final isValid = await ref.read(subscriptionProvider.notifier).applyDiscountCode(code);
    
    setState(() => _isValidatingDiscount = false);

    if (!isValid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ungültiger oder abgelaufener Rabattcode'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _isStartingCheckout = true);

    final result = await ref.read(subscriptionProvider.notifier).startCheckout(
      priceType: _selectedPlan,
    );

    setState(() => _isStartingCheckout = false);

    if (result != null && result['url'] != null) {
      // Öffne Stripe Checkout URL
      final url = Uri.parse(result['url'] as String);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Starten des Checkouts. Bitte versuche es erneut.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
  final String? originalPrice;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.originalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceMuted,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: AppColors.onPrimary, size: 16)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.onBackground,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                  ),
                ],
              ),
            ),
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (originalPrice != null)
                  Text(
                    originalPrice!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
