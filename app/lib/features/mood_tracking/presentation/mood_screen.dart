import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import 'mood_controller.dart';

/// Mood check-in on a 2D valence/arousal pad instead of a single "1-5
/// stars" scalar or two separate sliders — one direct gesture lets
/// someone place "calm and content" at a different point from "content
/// and excited" rather than collapsing both onto the same number.
class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodControllerProvider);
    final controller = ref.read(moodControllerProvider.notifier);
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ruh Hali')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            children: [
              Text(
                'Şu an nasılsın?',
                style: AppTypography.title2.copyWith(color: palette.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Noktayı hissettiğin yere sürükle',
                style: AppTypography.footnote.copyWith(color: palette.textTertiary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
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
              const SizedBox(height: 24),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: TextStyle(color: palette.warning)),
                ),
              if (state.submitted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Kaydedildi. Teşekkürler!',
                      style: AppTypography.subheadline.copyWith(color: palette.accent)),
                ),
              AppPrimaryButton(
                label: 'Kaydet',
                loading: state.submitting,
                onPressed: () => controller.submit(),
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
                _AxisLabel('Enerjik', Alignment.topCenter, palette),
                _AxisLabel('Sakin', Alignment.bottomCenter, palette),
                _AxisLabel('Zorlayıcı', Alignment.centerLeft, palette),
                _AxisLabel('Keyifli', Alignment.centerRight, palette),
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
