import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/glass.dart';
import '../../l10n/app_localizations.dart';
import '../storage/local_prefs.dart';

/// The one-time moments each screen can show: an intro the first time
/// someone opens a feature, and a short acknowledgement the first time
/// they actually complete something with it.
///
/// Both are keyed here rather than as loose strings at the call sites, so
/// "has this person seen X" is answerable in one place — and so renaming
/// a key can't silently re-show an intro to everyone who already read it.
class FirstRun {
  FirstRun._();

  static const moodIntro = 'intro.mood';
  static const journalIntro = 'intro.journal';
  static const chatIntro = 'intro.chat';

  static const firstMood = 'done.mood';
  static const firstJournal = 'done.journal';
  static const firstChat = 'done.chat';
}

/// Per-account, on-device record of which first-run moments are spent.
///
/// Scoped by user id because two accounts on one phone are two different
/// people's first times; local rather than server-side because nothing
/// here is worth a column — the cost of a wrong answer is one extra
/// intro card, and a fresh install genuinely *is* a fresh start.
class FirstRunState {
  final Set<String> seen;
  const FirstRunState(this.seen);

  bool has(String key) => seen.contains(key);
}

final firstRunProvider =
    NotifierProvider<FirstRunController, FirstRunState>(FirstRunController.new);

class FirstRunController extends Notifier<FirstRunState> {
  static const _prefix = 'mental_ai.first_run';

  String? get _userId => ref.read(currentUserIdProvider);

  String _key(String key) => '$_prefix.${_userId ?? 'anon'}.$key';

  @override
  FirstRunState build() {
    // Watched, not read: signing into another account on the same device
    // has to start that person's first-run state from scratch.
    ref.watch(sessionTokenProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final userId = ref.read(currentUserIdProvider) ?? 'anon';
    final prefix = '$_prefix.$userId.';

    return FirstRunState({
      for (final key in prefs.getKeys())
        if (key.startsWith(prefix)) key.substring(prefix.length),
    });
  }

  /// Marks a moment spent. Returns true when this call is what spent it,
  /// so a caller can both record and decide to celebrate in one step
  /// without racing itself on a rebuild.
  Future<bool> markSeen(String key) async {
    if (state.has(key)) return false;
    state = FirstRunState({...state.seen, key});
    await ref.read(sharedPreferencesProvider).setBool(_key(key), true);
    return true;
  }
}

/// A dismissible "here's what this screen is for" card, shown once at
/// the top of a feature the first time it's opened. Deliberately part of
/// the page rather than a modal: an overlay on first open is something
/// to get rid of, a card is something to read.
class FeatureIntroCard extends ConsumerWidget {
  final String introKey;
  final IconData icon;
  final String title;
  final String body;

  const FeatureIntroCard({
    super.key,
    required this.introKey,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final seen = ref.watch(firstRunProvider).has(introKey);
    if (seen) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassSurface(
        radius: 18,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 16, color: palette.accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(title,
                      style: AppTypography.label
                          .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.55)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ref.read(firstRunProvider.notifier).markSeen(introKey),
                child: Text(l10n.introGotIt,
                    style: AppTypography.footnote
                        .copyWith(color: palette.accent, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks a milestone and, if this was the first time, shows a short
/// acknowledgement sheet. Safe to call after every save — it's a no-op
/// on every run but the first.
Future<void> celebrateFirst(
  BuildContext context,
  WidgetRef ref, {
  required String key,
  required IconData icon,
  required String title,
  required String body,
}) async {
  final first = await ref.read(firstRunProvider.notifier).markSeen(key);
  if (!first || !context.mounted) return;

  final palette = AppPalette.of(context);
  final l10n = AppLocalizations.of(context)!;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: BoxDecoration(
        color: palette.canvasTop,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration:
                  BoxDecoration(color: palette.separator, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 27, color: palette.accent),
            ),
          ),
          const SizedBox(height: 18),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTypography.title3.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 10),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.55),
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: l10n.milestoneContinue,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
