import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF242424);
  static const Color card = Color(0xFF1E1E1E);

  // Accent
  static const Color primary = Color(0xFF00E5A0);
  static const Color primaryDark = Color(0xFF00B87A);
  static const Color primaryContainer = Color(0xFF003D2B);

  // Text
  static const Color onBackground = Color(0xFFF0F0F0);
  static const Color onSurface = Color(0xFFE0E0E0);
  static const Color onSurfaceMuted = Color(0xFF8A8A8A);
  static const Color onPrimary = Color(0xFF000000);

  // Status
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFFF5252);

  // Misc
  static const Color divider = Color(0xFF2C2C2C);
  static const Color overlay = Color(0x80000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5A0), Color(0xFF00B87A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E1E), Color(0xFF242424)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
