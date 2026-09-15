import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// The app's own mascot for a streak: an ember that grows and brightens
/// with consecutive days instead of a bare number doing all the work.
/// Ties the "Hearth" name and its flame launcher icon to the one piece of
/// UI that's actually about keeping something burning.
class HearthFlame extends StatelessWidget {
  final int streak;
  final double size;

  const HearthFlame({super.key, required this.streak, this.size = 40});

  /// Streak thresholds an ember steps through — day one already looks lit
  /// (an active streak shouldn't look unlit), and growth tapers off after
  /// a month rather than scaling forever past the point it reads as
  /// "different".
  static const _thresholds = [0, 1, 3, 7, 14, 30];

  int get _tier {
    var tier = 0;
    for (var i = 0; i < _thresholds.length; i++) {
      if (streak >= _thresholds[i]) tier = i;
    }
    return tier;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final tier = _tier;
    final tierFraction = tier / (_thresholds.length - 1);
    final scale = 0.5 + tierFraction * 0.5;
    final color = Color.lerp(palette.textTertiary, palette.ember, tierFraction)!;
    final glow = tier == 0 ? 0.0 : 0.1 + tierFraction * 0.3;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow > 0)
            Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: palette.ember.withValues(alpha: glow),
                    blurRadius: size * 0.45,
                    spreadRadius: size * 0.02,
                  ),
                ],
              ),
            ),
          Icon(Icons.local_fire_department_rounded, size: size * scale, color: color),
        ],
      ),
    );
  }
}
