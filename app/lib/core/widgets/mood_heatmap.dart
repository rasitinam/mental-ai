import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/mood_tracking/domain/mood_entry.dart';
import '../../l10n/app_localizations.dart';

/// The last five weeks as a calendar: one row per week starting Monday, one
/// cell per day shaded by that day's valence. A day with no check-in is an
/// outlined empty cell, the rest of this week is left blank, and today is
/// ringed. Once-a-day check-ins mean a cell is never ambiguous.
class MoodHeatmap extends StatelessWidget {
  final List<MoodEntry> entries;
  final int weeks;

  const MoodHeatmap({super.key, required this.entries, this.weeks = 5});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();

    final byDay = <DateTime, double>{};
    for (final entry in entries) {
      final local = entry.recordedAt.toLocal();
      byDay[DateTime(local.year, local.month, local.day)] = entry.valence;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(Duration(days: 7 * (weeks - 1)));
    // 1 January 2024 was a Monday.
    final initials = [
      for (var i = 0; i < 7; i++) DateFormat('EEEEE', locale).format(DateTime(2024, 1, 1 + i)),
    ];

    Widget row(List<Widget> cells) => Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: cells[i]),
            ],
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row([
          for (final initial in initials)
            Text(
              initial,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: palette.textTertiary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
        ]),
        for (var week = 0; week < weeks; week++) ...[
          const SizedBox(height: 6),
          row([
            for (var day = 0; day < 7; day++)
              _Cell(
                date: start.add(Duration(days: week * 7 + day)),
                today: today,
                valence: byDay[start.add(Duration(days: week * 7 + day))],
                palette: palette,
              ),
          ]),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Text(l10n.lifeMoodHistoryLegendLow, style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 13)),
            const SizedBox(width: 5),
            for (final sample in const [-1.0, -0.4, 0.0, 0.4, 1.0]) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: moodCellColor(palette, sample), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 1),
            Text(l10n.lifeMoodHistoryLegendHigh, style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 13)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.pathTodayOutlined,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Five steps from the hardest day to the best, so a glance lands on a
/// clear color rather than a subtly different shade.
Color moodCellColor(AppPalette palette, double valence) {
  if (valence <= -0.55) return palette.moodLow;
  if (valence < -0.15) return palette.peach;
  if (valence <= 0.15) return palette.moodMid;
  if (valence < 0.55) return palette.mint;
  return palette.moodHigh;
}

class _Cell extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final double? valence;
  final AppPalette palette;

  const _Cell({required this.date, required this.today, required this.valence, required this.palette});

  @override
  Widget build(BuildContext context) {
    if (date.isAfter(today)) return const AspectRatio(aspectRatio: 1, child: SizedBox());

    final isToday = date == today;
    final fill = valence == null ? null : moodCellColor(palette, valence!);
    final cell = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(9),
        border: fill == null ? Border.all(color: palette.separator, width: 1.5) : null,
      ),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: isToday
          ? Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: palette.textPrimary, width: 2),
              ),
              child: cell,
            )
          : cell,
    );
  }
}
