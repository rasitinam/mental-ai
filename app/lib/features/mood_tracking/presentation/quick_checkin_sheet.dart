import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/onboarding/first_run.dart';
import '../../../core/voice/voice.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';
import '../../settings/presentation/notification_settings_screen.dart' show reminderTimeLabel;
import '../../streak/data/streak_api.dart';
import '../data/mood_api.dart';
import '../domain/mood_emotion.dart';
import 'mood_controller.dart';

String moodEmotionLabel(AppLocalizations l10n, String key) => switch (key) {
      'calm' => l10n.moodWordCalm,
      'hopeful' => l10n.moodWordHopeful,
      'tired' => l10n.moodWordTired,
      'tense' => l10n.moodWordTense,
      'unsure' => l10n.moodWordUnsure,
      'relieved' => l10n.moodWordRelieved,
      'heavy' => l10n.moodWordHeavy,
      'joyful' => l10n.moodWordJoyful,
      'angry' => l10n.moodWordAngry,
      _ => l10n.moodWordEmpty,
    };

/// The whole check-in in one sheet over Bugün: words, the two-axis dot,
/// one optional sentence and Save. Opens on the root navigator, so nothing
/// in it can end up under the tab bar.
Future<void> showQuickCheckinSheet(BuildContext context, WidgetRef ref) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => const _QuickCheckinSheet(),
  );
  if (saved != true || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.moodSaved)));
  ref.invalidate(streakProvider);
  ref.invalidate(latestMoodProvider);
  ref.invalidate(moodHistoryProvider);

  await celebrateFirst(
    context,
    ref,
    key: FirstRun.firstMood,
    icon: Icons.favorite_rounded,
    title: l10n.milestoneFirstMoodTitle,
    body: l10n.milestoneFirstMoodBody,
  );
}

class _QuickCheckinSheet extends ConsumerStatefulWidget {
  const _QuickCheckinSheet();

  @override
  ConsumerState<_QuickCheckinSheet> createState() => _QuickCheckinSheetState();
}

class _QuickCheckinSheetState extends ConsumerState<_QuickCheckinSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(moodControllerProvider.notifier);
    final picked = ref.read(moodControllerProvider).emotions;
    final note = _note.text.trim();

    await controller.submit(
      note: note.isEmpty ? null : note,
      tags: [for (final key in picked) moodEmotionLabel(l10n, key)],
    );
    if (!mounted) return;

    final after = ref.read(moodControllerProvider);
    if (after.submitted) {
      Navigator.of(context).pop(true);
    } else if (after.isOnCooldown) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final footnote = profile != null && profile.checkinReminderEnabled
        ? l10n.quickCheckinFootnoteReminder(reminderTimeLabel(profile.checkinReminderHour))
        : l10n.quickCheckinFootnote;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SheetFrame(
        children: [
          SectionLabel(l10n.quickCheckinEyebrow),
          const SizedBox(height: 6),
          Text(l10n.moodHowAreYou, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final emotion in moodEmotions)
                AppChip(
                  label: moodEmotionLabel(l10n, emotion.key),
                  selected: state.emotions.contains(emotion.key),
                  fill: palette.canvasTop,
                  onTap: () => controller.toggleEmotion(emotion.key),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l10n.moodWhereItLands,
                  style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.moodDragHint,
                  textAlign: TextAlign.right,
                  style: AppTypography.caption.copyWith(color: palette.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoodPad(
            valence: state.valence,
            arousal: state.arousal,
            onChanged: controller.setMood,
          ),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            decoration: BoxDecoration(color: palette.canvasTop, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _note,
                    minLines: 1,
                    maxLines: 3,
                    style: AppTypography.body.copyWith(color: palette.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: l10n.quickCheckinNoteHint,
                      hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DictationButton(controller: _note, style: DictationStyle.pill),
              ],
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(friendlyErrorMessage(l10n, state.error!),
                style: AppTypography.footnote.copyWith(color: palette.warning)),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(label: l10n.commonSave, loading: state.submitting, onPressed: _save),
          const SizedBox(height: 10),
          Text(footnote,
              textAlign: TextAlign.center,
              style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }
}

/// Valence left to right, energy bottom to top, with a dot you can drag.
/// The dot is inset from the edges so a maxed-out reading stays visible.
class MoodPad extends StatelessWidget {
  final double valence;
  final double arousal;
  final void Function(double valence, double arousal) onChanged;

  const MoodPad({super.key, required this.valence, required this.arousal, required this.onChanged});

  static const _inset = 24.0;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final axisStyle = AppTypography.caption.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w700);

    return LayoutBuilder(
      builder: (context, constraints) {
        const height = 150.0;
        final width = constraints.maxWidth;
        final x = _inset + (valence.clamp(-1.0, 1.0) + 1) / 2 * (width - _inset * 2);
        final y = _inset + (1 - (arousal.clamp(-1.0, 1.0) + 1) / 2) * (height - _inset * 2);

        void handle(Offset p) {
          final v = ((p.dx - _inset) / (width - _inset * 2)) * 2 - 1;
          final a = 1 - ((p.dy - _inset) / (height - _inset * 2)) * 2;
          onChanged(v.clamp(-1.0, 1.0), a.clamp(-1.0, 1.0));
        }

        return Semantics(
          label: l10n.moodWhereItLands,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => handle(d.localPosition),
            onPanUpdate: (d) => handle(d.localPosition),
            child: Container(
              height: height,
              decoration: BoxDecoration(color: palette.canvasTop, borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  Positioned(
                    left: 84,
                    right: 74,
                    top: height / 2 - 0.75,
                    child: Container(height: 1.5, color: palette.separator),
                  ),
                  Positioned(
                    top: 30,
                    bottom: 30,
                    left: width / 2 - 0.75,
                    child: Container(width: 1.5, color: palette.separator),
                  ),
                  Positioned(top: 8, left: 0, right: 0, child: Text(l10n.moodEnergetic, textAlign: TextAlign.center, style: axisStyle)),
                  Positioned(bottom: 8, left: 0, right: 0, child: Text(l10n.moodCalm, textAlign: TextAlign.center, style: axisStyle)),
                  Positioned(left: 12, top: height / 2 - 9, child: Text(l10n.moodUnpleasant, style: axisStyle)),
                  Positioned(right: 12, top: height / 2 - 9, child: Text(l10n.moodPleasant, style: axisStyle)),
                  Positioned(
                    left: x - 14,
                    top: y - 14,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: palette.accent.withValues(alpha: 0.16), spreadRadius: 7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
