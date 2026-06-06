import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/common/app_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(user: user),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: 'Goals',
                      children: [
                        _GoalSelector(user: user, ref: ref),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: 'Training',
                      children: [
                        _WeeklyTargetSelector(user: user, ref: ref),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSection(
                      title: 'Account',
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          trailing: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryContainer,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          trailing: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeThumbColor: AppColors.primary,
                            activeTrackColor: AppColors.primaryContainer,
                          ),
                        ),
                        _SettingsTile(
                          icon: Icons.info_outline,
                          label: 'About RepRise',
                          onTap: () => _showAbout(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      onTap: () {
                        ref.read(authProvider.notifier).signOut();
                        context.go(AppRoutes.onboarding);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Sign Out',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Text(
                        'RepRise v1.0.0 · MVP',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RepRise',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 RepRise',
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppUser user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A2C24), AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.fullRadius,
            ),
            child: Text(
              user.goal.label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: children.indexed
                .map(
                  (e) => Column(
                    children: [
                      e.$2,
                      if (e.$1 < children.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _GoalSelector extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;

  const _GoalSelector({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppColors.onSurface, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Fitness Goal', style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FitnessGoal.values.map((goal) {
              final isSelected = user.goal == goal;
              return GestureDetector(
                onTap: () => ref
                    .read(authProvider.notifier)
                    .updateUser(user.copyWith(goal: goal)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryContainer : AppColors.surfaceVariant,
                    borderRadius: AppRadius.fullRadius,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    goal.label,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTargetSelector extends StatelessWidget {
  final AppUser user;
  final WidgetRef ref;

  const _WeeklyTargetSelector({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.repeat_rounded, color: AppColors.onSurface, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text('Weekly Target', style: Theme.of(context).textTheme.bodyMedium),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(6, (i) {
              final day = i + 2;
              final isSelected = user.weeklyTargetDays == day;
              return GestureDetector(
                onTap: () => ref
                    .read(authProvider.notifier)
                    .updateUser(user.copyWith(weeklyTargetDays: day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.black : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
