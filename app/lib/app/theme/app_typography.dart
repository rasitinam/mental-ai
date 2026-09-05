import 'package:flutter/widgets.dart';

/// A type scale modeled on Apple's Human Interface Guidelines (large
/// title down to caption), deliberately left on the platform's default
/// font rather than importing a web font. On iOS/macOS that default
/// resolves to San Francisco for free; on other platforms it resolves to
/// that platform's own native font — either way the app feels native
/// instead of shipping one generic "AI product" typeface everywhere.
/// Colors are intentionally omitted here; apply [AppPalette] colors with
/// `.copyWith(color: ...)` at the call site.
class AppTypography {
  AppTypography._();

  static const largeTitle = TextStyle(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const title1 = TextStyle(
    fontSize: 26,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  static const title2 = TextStyle(
    fontSize: 21,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const headline = TextStyle(
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const body = TextStyle(
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  static const subheadline = TextStyle(
    fontSize: 14.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  static const footnote = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const caption = TextStyle(
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );
}
