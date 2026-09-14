import 'package:flutter/widgets.dart';

/// How far the end of a screen's content has to stay from the bottom edge
/// so nothing sits underneath whatever covers that edge.
///
/// Inside `HomeShell` that cover is the floating tab bar: the shell's
/// `Scaffold(extendBody: true)` reports the bar's real height — its 60px
/// plus whichever is larger of its 20px margin and the system inset — as
/// the body's bottom padding. Outside the shell (onboarding, premium,
/// pushed social pages, bottom sheets on the root navigator) the same
/// padding is just the system inset: the iPhone home indicator, Android's
/// navigation bar, or nothing on the web. Reading it instead of
/// hard-coding a number is what makes one value right on all three
/// platforms — the old fixed 140/120/100 guesses each fit one device and
/// left buttons or list rows under the bar on another.
///
/// Only meaningful where that padding hasn't already been consumed, i.e.
/// under `SafeArea(bottom: false)` or no `SafeArea` at all.
double bottomClearance(BuildContext context, {double gap = 24}) =>
    MediaQuery.paddingOf(context).bottom + gap;
