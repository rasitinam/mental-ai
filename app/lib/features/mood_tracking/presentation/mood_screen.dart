import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/onboarding/first_run.dart';
import '../../../core/widgets/countdown_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/mood_emotion.dart';
import 'mood_controller.dart';

/// Mood check-in by picking words, not by aiming at a grid. The words
/// average onto the same valence/arousal pair the backend has always
/// stored — the axes are still there, shown underneath as two readouts
/// you can nudge by hand, so the model stays legible without asking
/// anyone to think in coordinates first.
///
/// Once-per-day: the backend rejects a second check-in inside 24h (see
/// `apps/server/src/routes/mood.rs`), so this screen shows a live
/// countdown and disables the form instead of letting someone fill it
/// out just to get an error on submit.
class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  /// Saves, then — the very first time it works — marks the milestone.
  /// Keyed off `submitted` rather than the absence of an error so a
  /// rejected check-in (cooldown, network) never spends the moment.
  Future<void> _submit() async {
    await ref.read(moodControllerProvider.notifier).submit();
    if (!mounted || !ref.read(moodControllerProvider).submitted) return;

    final l10n = AppLocalizations.of(context)!;
    await celebrateFirst(
      context,
      ref,
      key: FirstRun.firstMood,
      icon: Icons.favorite_rounded,
      title: l10n.milestoneFirstMoodTitle,
      body: l10n.milestoneFirstMoodBody,
    );
  }

  String _formatRemaining(AppLocalizations l10n, Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours${l10n.timeUnitHour} $minutes${l10n.timeUnitMinute}';
    final seconds = d.inSeconds.remainder(60);
    return '$minutes${l10n.timeUnitMinute} $seconds${l10n.timeUnitSecond}';
  }

  String _emotionLabel(AppLocalizations l10n, String key) => switch (key) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SquareIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => context.go('/report'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                onCooldown ? l10n.moodDoneToday : l10n.moodHowAreYou,
                style: AppTypography.title2.copyWith(color: palette.textPrimary, fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.moodPickHint,
                style: AppTypography.footnote
                    .copyWith(color: palette.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              FeatureIntroCard(
                introKey: FirstRun.moodIntro,
                icon: Icons.favorite_rounded,
                title: l10n.introMoodTitle,
                body: l10n.introMoodBody,
              ),
              Opacity(
                opacity: onCooldown ? 0.45 : 1,
                child: IgnorePointer(
                  ignoring: onCooldown,
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final emotion in moodEmotions)
                        _EmotionChip(
                          label: _emotionLabel(l10n, emotion.key),
                          selected: state.emotions.contains(emotion.key),
                          palette: palette,
                          onTap: () => controller.toggleEmotion(emotion.key),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Opacity(
                opacity: onCooldown ? 0.45 : 1,
                child: IgnorePointer(
                  ignoring: onCooldown,
                  child: GlassSurface(
                    radius: 18,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel(l10n.moodWhereItLands),
                        const SizedBox(height: 14),
                        _AxisSlider(
                          low: l10n.moodUnpleasant,
                          high: l10n.moodPleasant,
                          value: state.valence,
                          palette: palette,
                          onChanged: (v) => controller.setMood(v, state.arousal),
                        ),
                        const SizedBox(height: 16),
                        _AxisSlider(
                          low: l10n.moodCalm,
                          high: l10n.moodEnergetic,
                          value: state.arousal,
                          palette: palette,
                          onChanged: (a) => controller.setMood(state.valence, a),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.moodAxisHint,
                          style: AppTypography.footnote
                              .copyWith(color: palette.textSecondary, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (state.error != null) ...[
                Text(friendlyErrorMessage(l10n, state.error!),
                    textAlign: TextAlign.center, style: TextStyle(color: palette.warning)),
                const SizedBox(height: 12),
              ],
              if (state.submitted && !onCooldown) ...[
                Text(l10n.moodSaved,
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(color: palette.accent)),
                const SizedBox(height: 12),
              ],
              AppPrimaryButton(
                label: onCooldown ? l10n.moodTryTomorrow : l10n.commonSave,
                loading: state.submitting || state.loadingCooldown,
                icon: onCooldown ? Icons.schedule_rounded : null,
                onPressed: onCooldown ? null : _submit,
              ),
              const SizedBox(height: 12),
              // The countdown owns its own ticker so a second passing
              // repaints this one line, not the whole screen — and stops
              // ticking entirely once the cooldown is over.
              if (onCooldown)
                CountdownText(
                  until: state.cooldownUntil!,
                  onFinished: () => setState(() {}),
                  format: (remaining) => l10n.moodNextIn(_formatRemaining(l10n, remaining)),
                  textAlign: TextAlign.center,
                  style: AppTypography.footnote
                      .copyWith(color: palette.textSecondary, fontSize: 12),
                )
              else
                Text(
                  l10n.moodOncePerDay,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.footnote.copyWith(color: palette.textSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _EmotionChip({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? palette.accent : palette.separator),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected ? AppPalette.of(context).onAccent : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// One axis as a labelled track with a draggable dot. The dot's range is
/// padded past the ends (-1.3..1.3 rather than -1..1) so a maxed-out
/// reading still sits inside the track instead of clipping at its edge.
class _AxisSlider extends StatelessWidget {
  final String low;
  final String high;
  final double value;
  final AppPalette palette;
  final ValueChanged<double> onChanged;

  const _AxisSlider({
    required this.low,
    required this.high,
    required this.value,
    required this.palette,
    required this.onChanged,
  });

  static const _span = 2.6;

  @override
  Widget build(BuildContext context) {
    final fraction = ((value + _span / 2) / _span).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(low, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
            Text(high, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            void handle(double dx) {
              final next = (dx / constraints.maxWidth) * _span - _span / 2;
              onChanged(next.clamp(-1.0, 1.0));
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => handle(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => handle(d.localPosition.dx),
              child: SizedBox(
                height: 18,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Positioned(
                      left: (fraction * constraints.maxWidth - 7)
                          .clamp(0.0, constraints.maxWidth - 14),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accent,
                          border: Border.all(color: palette.glassFill, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
