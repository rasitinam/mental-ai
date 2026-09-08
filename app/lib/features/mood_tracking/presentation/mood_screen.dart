import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import 'mood_controller.dart';

/// Mood check-in on a 2D valence/arousal pad instead of a single "1-5
/// stars" scalar or two separate sliders — one direct gesture lets
/// someone place "calm and content" at a different point from "content
/// and excited" rather than collapsing both onto the same number.
///
/// Once-per-day: the backend rejects a second check-in inside 24h (see
/// `apps/server/src/routes/mood.rs`), so this screen shows a live
/// countdown and disables the pad/button instead of letting someone fill
/// it out just to get an error on submit.
class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Only drives the countdown label + re-enabling the form when the
    // cooldown lapses — the actual gate is server-side.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours sa $minutes dk';
    final seconds = d.inSeconds.remainder(60);
    return '$minutes dk $seconds sn';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMood)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            children: [
              Text(
                onCooldown ? l10n.moodDoneToday : l10n.moodHowAreYou,
                style: AppTypography.title2.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                onCooldown
                    ? l10n.moodNextIn(_formatRemaining(state.cooldownUntil!.difference(DateTime.now())))
                    : l10n.moodDragHint,
                style: AppTypography.footnote.copyWith(color: palette.textTertiary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: onCooldown ? 0.45 : 1,
                      child: IgnorePointer(
                        ignoring: onCooldown,
                        child: _MoodPad(
                          valence: state.valence,
                          arousal: state.arousal,
                          onChanged: (v, a) {
                            controller.setValence(v);
                            controller.setArousal(a);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: TextStyle(color: palette.warning)),
                ),
              if (state.submitted && !onCooldown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(l10n.moodSaved,
                      style: AppTypography.subheadline.copyWith(color: palette.accent)),
                ),
              AppPrimaryButton(
                label: onCooldown ? l10n.moodTryTomorrow : l10n.commonSave,
                loading: state.submitting || state.loadingCooldown,
                icon: onCooldown ? Icons.schedule_rounded : null,
                onPressed: onCooldown ? null : () => controller.submit(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPad extends StatelessWidget {
  final double valence;
  final double arousal;
  final void Function(double valence, double arousal) onChanged;

  const _MoodPad({required this.valence, required this.arousal, required this.onChanged});

  void _handle(Offset localPosition, Size size) {
    final dx = (localPosition.dx / size.width) * 2 - 1;
    final dy = 1 - (localPosition.dy / size.height) * 2;
    onChanged(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final dotX = (valence + 1) / 2 * size.width;
        final dotY = (1 - arousal) / 2 * size.height;

        return GestureDetector(
          onPanStart: (details) => _handle(details.localPosition, size),
          onPanUpdate: (details) => _handle(details.localPosition, size),
          onTapDown: (details) => _handle(details.localPosition, size),
          child: GlassSurface(
            radius: 32,
            blurSigma: 20,
            padding: EdgeInsets.zero,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _AxisPainter(color: palette.separator)),
                ),
                _AxisLabel(l10n.moodEnergetic, Alignment.topCenter, palette),
                _AxisLabel(l10n.moodCalm, Alignment.bottomCenter, palette),
                _AxisLabel(l10n.moodUnpleasant, Alignment.centerLeft, palette),
                _AxisLabel(l10n.moodPleasant, Alignment.centerRight, palette),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 60),
                  left: dotX - 14,
                  top: dotY - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.accent,
                      boxShadow: [
                        BoxShadow(color: palette.accent.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 1),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final Alignment alignment;
  final AppPalette palette;
  const _AxisLabel(this.text, this.alignment, this.palette);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(text, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
      ),
    );
  }
}

class _AxisPainter extends CustomPainter {
  final Color color;
  const _AxisPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _AxisPainter oldDelegate) => oldDelegate.color != color;
}
