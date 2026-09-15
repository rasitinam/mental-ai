import 'package:flutter/widgets.dart';

/// Two faces: Bricolage Grotesque (narrow cut) for titles, Atkinson
/// Hyperlegible Next for everything read — designed for low-vision
/// readers, so I/l/1 and 0/O never blur together.
///
/// Body styles are family-less on purpose: `AppTheme` sets Atkinson on the
/// theme's text styles and Flutter merges it down, so every call site
/// inherits it. Title styles name [displayFamily] themselves. Colors are
/// omitted everywhere; apply [AppPalette] colors with `.copyWith`.
class AppTypography {
  AppTypography._();

  static const displayFamily = 'Bricolage Grotesque';
  static const bodyFamily = 'Atkinson Hyperlegible Next';
  static const _fallback = ['system-ui', 'sans-serif'];

  /// Login's welcome line and the greeting on Bugün.
  static const largeTitle = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
  );

  /// The condition name on a reference card.
  static const title1 = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontSize: 28,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  /// Tab titles: "Sohbet", "Hikayeler", "Yolum", "Ben".
  static const title2 = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontSize: 30,
    height: 1.08,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
  );

  /// Pushed-screen titles, next to a back button.
  static const title3 = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
  );

  /// A card's one-line verdict or a section heading.
  static const headline = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: _fallback,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  /// Row labels, chips, buttons.
  static const label = TextStyle(
    fontSize: 15.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  /// Running text people actually read.
  static const body = TextStyle(
    fontSize: 16,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  static const subheadline = TextStyle(
    fontSize: 15,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  /// Explanatory notes and helper text.
  static const footnote = TextStyle(
    fontSize: 13.5,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  /// Metadata: dates, counters.
  static const caption = TextStyle(
    fontSize: 12.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
}
