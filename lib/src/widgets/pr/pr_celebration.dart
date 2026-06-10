import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/personal_record.dart';
import '../../theme/app_colors.dart';

/// Celebration overlay shown when user achieves a new personal record
class PRCelebration extends StatefulWidget {
  final PersonalRecord record;
  final VoidCallback onDismiss;

  const PRCelebration({
    super.key,
    required this.record,
    required this.onDismiss,
  });

  @override
  State<PRCelebration> createState() => _PRCelebrationState();
}

class _PRCelebrationState extends State<PRCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // Start animations
    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
      _slideController.forward();
    });
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _scaleController.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trophy = widget.record.trophyLevel;
    final badge = widget.record.weightBadge;
    
    return GestureDetector(
      onTap: _dismiss,
      child: Container(
        color: Colors.black.withAlpha(180),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surface,
                      AppColors.surfaceVariant,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withAlpha(100),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Confetti-like decoration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ConfettiPiece(color: AppColors.primary, delay: 0),
                        _ConfettiPiece(color: Colors.amber, delay: 100),
                        _ConfettiPiece(color: Colors.redAccent, delay: 200),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Trophy emoji
                    Text(
                      trophy.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 16),
                    
                    // NEW RECORD text
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'NEW RECORD!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Exercise name
                    Text(
                      widget.record.exerciseName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight and reps
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${widget.record.weightKg.toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'kg × ${widget.record.reps}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppColors.onSurfaceMuted,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Estimated 1RM
                    Text(
                      'Est. 1RM: ${widget.record.estimatedOneRepMax.toStringAsFixed(1)} kg',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Weight badge if applicable
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Tap to dismiss hint
                    Text(
                      'Tap anywhere to continue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated confetti piece
class _ConfettiPiece extends StatefulWidget {
  final Color color;
  final int delay;

  const _ConfettiPiece({
    required this.color,
    required this.delay,
  });

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final random = Random(widget.delay);
    final offsetX = (random.nextDouble() - 0.5) * 60;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            offsetX * _animation.value,
            -50 * _animation.value,
          ),
          child: Transform.rotate(
            angle: _animation.value * 2 * pi,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
