import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../journal/data/journal_api.dart';
import '../../mood_tracking/data/mood_api.dart';
import '../../streak/data/streak_api.dart';
import '../domain/recap_data.dart';

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Folds the last 7 days of mood/journal history plus the streak summary
/// into one [RecapData] for `RecapScreen`. `autoDispose` — this is a
/// destination someone visits, not a tab that should keep fetching once
/// nobody's looking at it.
final recapProvider = FutureProvider.autoDispose<RecapData>((ref) async {
  final periodEnd = DateTime.now();
  final periodStart = periodEnd.subtract(const Duration(days: 7));

  final moodHistory = await ref.watch(moodApiProvider).history();
  final journalEntries = await ref.watch(journalApiProvider).list();
  final streak = await ref.watch(streakApiProvider).summary();

  final moodsThisWeek =
      moodHistory.where((m) => m.recordedAt.isAfter(periodStart)).toList();
  final journalsThisWeek =
      journalEntries.where((j) => j.createdAt.isAfter(periodStart)).toList();

  double? avgValence;
  if (moodsThisWeek.isNotEmpty) {
    avgValence = moodsThisWeek.map((m) => m.valence).reduce((a, b) => a + b) / moodsThisWeek.length;
  }

  final activeDays = <String>{
    for (final m in moodsThisWeek) _dayKey(m.recordedAt),
    for (final j in journalsThisWeek) _dayKey(j.createdAt),
  };

  return RecapData(
    periodStart: periodStart,
    periodEnd: periodEnd,
    checkins: moodsThisWeek.length,
    journalEntries: journalsThisWeek.length,
    streak: streak.current,
    activeDays: activeDays.length,
    avgValence: avgValence,
  );
});
