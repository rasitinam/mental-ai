import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's one shared surface material: a frosted panel with a hairline
/// border and a soft, low-spread shadow — no gradient border, no glow, no
/// saturated tint. The corner is Apple's continuous ("squircle") curve
/// rather than a plain circular arc, which is the detail that makes it read
/// as native instead of generic-rounded-card.
///
/// [blur] is off by default, and that is a deliberate performance call.
/// `BackdropFilter` forces a save-layer and a read-back of everything
/// painted behind it, per surface, per frame — with a dozen cards on screen
/// that alone was dropping frames on a mid-range phone. What sits behind
/// these cards is [AppBackground]: a smooth two-stop gradient. Blurring a
/// smooth gradient returns almost exactly the same pixels a translucent fill
/// does, so the cost bought nothing. The blur is kept only where something
/// genuinely scrolls underneath the surface — the floating tab bar.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  /// Real backdrop blur. Only worth it when content actually moves behind
  /// this surface; see the class docs.
  final bool blur;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.blurSigma = 24,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: palette.glassBorder),
    );

    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.glassFill,
        shape: shape,
        shadows: [
          BoxShadow(color: palette.glassShadow, blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!blur) return surface;

    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      ),
    );
  }
}

/// The app's constant backdrop: a calm two-stop gradient plus one very
/// faint radial highlight in the accent color, anchored off-canvas at the
/// top. Kept deliberately quiet — this is meant to give the glass panels
/// something to refract, not to be a decoration in its own right.
///
/// Painted once into its own layer: it never changes while a screen
/// scrolls, so isolating it keeps scrolling content from dragging two
/// full-screen gradients through every repaint.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _BackdropPainter(palette)),
          ),
        ),
        child,
      ],
    );
  }
}

/// One painter for the whole backdrop instead of a `DecoratedBox` plus two
/// gradient-filled `Container`s in a `Stack`: same picture, a third of the
/// render objects, and nothing to lay out.
class _BackdropPainter extends CustomPainter {
  final AppPalette palette;
  const _BackdropPainter(this.palette);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.canvasTop, palette.canvasBottom],
        ).createShader(bounds),
    );

    _glow(canvas, Offset(size.width + 120, -180), 210, palette.accent.withValues(alpha: 0.10));
    _glow(canvas, Offset(-160, size.height + 220), 230, palette.accent.withValues(alpha: 0.06));
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.palette != palette;
}

/// A single-line, single-accent pill button — the app's one primary
/// call-to-action style. Deliberately not a gradient-filled button.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      height: 52,
      child: Material(
        color: palette.accent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (loading || onPressed == null) ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
