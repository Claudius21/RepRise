import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool hasBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.card,
      borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
        splashColor: AppColors.primary.withAlpha(20),
        highlightColor: AppColors.primary.withAlpha(10),
        child: Container(
          padding: padding ?? AppSpacing.cardPadding,
          decoration: hasBorder
              ? BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.lg),
                )
              : null,
          child: child,
        ),
      ),
    );
  }
}
