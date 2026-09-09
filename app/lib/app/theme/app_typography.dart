import 'package:flutter/widgets.dart';

/// The type scale from the design, transcribed rather than invented: the
/// sizes, weights and tracking here are the ones the mockups actually
/// use, which is why they aren't a tidy modular scale.
///
/// Every style is deliberately family-less. `AppTheme` puts the family
/// on the theme's own text styles, and Flutter merges that down through
/// `DefaultTextStyle` — so these inherit the right font (Instrument Sans
/// in light, Sora in dark) without a single call site naming it.
/// Colors are omitted for the same reason: apply [AppPalette] colors
/// with `.copyWith(color: ...)` at the call site.
class AppTypography {
  AppTypography._();

  /// Login's welcome line — the largest type in the app.
  static const largeTitle = TextStyle(
    fontSize: 27,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.68,
  );

  /// The condition name on a reference card.
  static const title1 = TextStyle(
    fontSize: 25,
    height: 1.15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.63,
  );

  /// Top-level screen titles: the greeting, "Rehber", "Ayarlar".
  static const title2 = TextStyle(
    fontSize: 23,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.46,
  );

  /// Pushed-screen titles, which sit next to a back button and so run a
  /// step smaller: "Profilim", "Tanılarım", "Moderasyon".
  static const title3 = TextStyle(
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.44,
  );

  /// The one-line verdict at the top of the home state card.
  static const headline = TextStyle(
    fontSize: 19,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.19,
  );

  /// The title of a card that holds a paragraph — a research insight.
  static const cardTitle = TextStyle(
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.16,
  );

  /// Row labels: a settings row, a disorder card's name, a picker entry.
  static const label = TextStyle(
    fontSize: 14.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  /// Running text people actually read: composer contents, story bodies.
  static const body = TextStyle(
    fontSize: 15,
    height: 1.6,
    fontWeight: FontWeight.w400,
  );

  /// Secondary running text — list items, past entries.
  static const subheadline = TextStyle(
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  /// Explanatory notes, disclaimers, helper text under a field.
  static const footnote = TextStyle(
    fontSize: 12.5,
    height: 1.55,
    fontWeight: FontWeight.w400,
  );

  /// Metadata: dates, counters, "4 / 5".
  static const caption = TextStyle(
    fontSize: 11.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
}
