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
        final cell = ((constraints.maxWidth - (weeks - 1) * 3) / weeks).clamp(8.0, 16.0);

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
                for (var i = 0; i < 4; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.18 + (i / 3) * 0.72),
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
    final color = isFuture
        ? Colors.transparent
        : valence == null
            ? palette.separator
            // -1..1 mapped to 0..1 so a bad day still shows the coolest
            // shade of the accent rather than reading as "no data".
            : palette.accent.withValues(alpha: 0.18 + ((valence! + 1) / 2) * 0.72);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}
