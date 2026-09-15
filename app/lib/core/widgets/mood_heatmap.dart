import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/mood_tracking/domain/mood_entry.dart';
import '../../l10n/app_localizations.dart';

/// A GitHub-contributions-style grid of the last several weeks, one cell
/// per day, shaded by that day's valence — reading the whole history at a
/// glance instead of as a list of numbers. Once-a-day check-ins mean a
/// filled cell is unambiguous: at most one entry to color it by.
class MoodHeatmap extends StatelessWidget {
  final List<MoodEntry> entries;

  /// How many weeks of columns to draw. 12 weeks fits comfortably next to
  /// the life-analysis screen's other cards without scrolling.
  final int weeks;

  const MoodHeatmap({super.key, required this.entries, this.weeks = 12});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final byDay = <DateTime, double>{};
    for (final entry in entries) {
      final day = DateTime(entry.recordedAt.year, entry.recordedAt.month, entry.recordedAt.day);
      byDay[day] = entry.valence;
    }

    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    // Sunday-ending columns: today's weekday (1=Mon..7=Sun) tells us how
    // many days into the current week we are, so the grid always ends on
    // the most recent Sunday-aligned column rather than a partial one.
    final daysAfterLastSunday = today.weekday % 7;
    final gridEnd = todayDay.subtract(Duration(days: daysAfterLastSunday));
    final gridStart = gridEnd.subtract(Duration(days: weeks * 7 - 1));

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = ((constraints.maxWidth - (weeks - 1) * 3) / weeks).clamp(8.0, 20.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var week = 0; week < weeks; week++) ...[
                  if (week > 0) const SizedBox(width: 3),
                  Column(
                    children: [
                      for (var day = 0; day < 7; day++) ...[
                        if (day > 0) const SizedBox(height: 3),
                        _Cell(
                          size: cell,
                          valence: byDay[gridStart.add(Duration(days: week * 7 + day))],
                          isFuture: gridStart.add(Duration(days: week * 7 + day)).isAfter(todayDay),
                          palette: palette,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.lifeMoodHistoryLegendLow,
                    style: AppTypography.caption.copyWith(color: palette.textTertiary)),
                const SizedBox(width: 6),
                // -1..1 across five swatches, through the same mapping the
                // cells use, so the legend is an honest key rather than a
                // decorative gradient.
                for (final sample in const [-1.0, -0.5, 0.0, 0.5, 1.0])
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: moodCellColor(palette, sample),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Text(l10n.lifeMoodHistoryLegendHigh,
                    style: AppTypography.caption.copyWith(color: palette.textTertiary)),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A day with no check-in stays [AppPalette.separator] (the grid's own
/// "empty" gray/black, not a mood reading) — everything else runs on a
/// diverging scale from [AppPalette.moodLow] at the worst valence through
/// to [AppPalette.moodHigh] at the best, so "zorlu" and "keyifli" read as two
/// different colors, not two intensities of the same one.
Color moodCellColor(AppPalette palette, double? valence) {
  if (valence == null) return palette.separator;

  final magnitude = valence.abs().clamp(0.0, 1.0);
  return Color.lerp(palette.moodMid, valence >= 0 ? palette.moodHigh : palette.moodLow, magnitude)!;
}

class _Cell extends StatelessWidget {
  final double size;
  final double? valence;
  final bool isFuture;
  final AppPalette palette;

  const _Cell({
    required this.size,
    required this.valence,
    required this.isFuture,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFuture ? Colors.transparent : moodCellColor(palette, valence);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}
