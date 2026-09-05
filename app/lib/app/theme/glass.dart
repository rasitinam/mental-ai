import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's one shared surface material: a frosted panel with a hairline
/// border and a soft, low-spread shadow — no gradient border, no glow, no
/// saturated tint. `ClipRSuperellipse` gives it Apple's continuous
/// ("squircle") corner instead of a plain circular-arc rounded rect,
/// which is the detail that makes it read as native rather than
/// generic-rounded-card.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.blurSigma = 24,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: palette.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: palette.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(color: palette.glassShadow, blurRadius: 28, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// The app's constant backdrop: a calm two-stop gradient plus one very
/// faint radial highlight in the accent color, anchored off-canvas at the
/// top. Kept deliberately quiet — this is meant to give the glass panels
/// something to refract, not to be a decoration in its own right.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.canvasTop, palette.canvasBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -180,
            right: -120,
            child: _SoftGlow(color: palette.accent.withValues(alpha: 0.10), size: 420),
          ),
          Positioned(
            bottom: -220,
            left: -160,
            child: _SoftGlow(color: palette.accent.withValues(alpha: 0.06), size: 460),
          ),
          child,
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _SoftGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
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
