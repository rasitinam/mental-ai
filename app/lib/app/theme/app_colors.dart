import 'package:flutter/material.dart';

/// A calm, low-arousal palette on purpose — this is a mental-wellness
/// app, not a productivity dashboard. Avoid saturated reds/oranges for
/// anything that isn't an explicit warning (e.g. the crisis-resources
/// banner).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B7F73); // sage green
  static const Color primaryDark = Color(0xFF3E5A50);
  static const Color background = Color(0xFFF6F5F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF8AA9C9); // muted blue
  static const Color warning = Color(0xFFC97B4A);
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF6B6B6B);
}
