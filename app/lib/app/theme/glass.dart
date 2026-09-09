import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's one card surface: an opaque panel with a soft continuous
/// ("squircle") corner and, in light mode, a shadow just heavy enough to
/// lift it off the canvas — `0 1px 2px` at 5%, not a drop shadow anyone
/// would describe as a drop shadow. Dark mode drops the shadow entirely
/// and separates by fill alone, since a shadow under a near-black card
/// on a near-black canvas is only ever mud.
///
/// [blur] is off by default, and that is a deliberate performance call.
/// `BackdropFilter` forces a save-layer and a read-back of everything
/// painted behind it, per surface, per frame — with a dozen cards on
/// screen that alone was dropping frames on a mid-range phone. The blur
/// is kept only where something genuinely scrolls underneath the
/// surface: the floating tab bar.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;

  /// Real backdrop blur. Only worth it when content actually moves behind
  /// this surface; see the class docs.
  final bool blur;

  /// A hairline outline. Off for cards (the design separates them with
  /// fill and shadow), on for surfaces that float over moving content.
  final bool bordered;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.blurSigma = 24,
    this.blur = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: bordered ? BorderSide(color: palette.glassBorder) : BorderSide.none,
    );

    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: blur ? palette.glassFill.withValues(alpha: 0.82) : palette.glassFill,
        shape: shape,
        shadows: [
          BoxShadow(color: palette.glassShadow, blurRadius: 2, offset: const Offset(0, 1)),
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

/// The app's constant backdrop: one flat, quiet ground the cards sit on.
/// Painted once into its own layer — it never changes while a screen
/// scrolls, so isolating it keeps scrolling content from dragging a
/// full-screen repaint behind it.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: palette.canvasTop)),
        child,
      ],
    );
  }
}

/// A single-accent block button — the app's one primary call-to-action
/// style. Deliberately not a gradient-filled button, and deliberately a
/// soft rectangle rather than a full pill: at 54pt tall a stadium border
/// reads as a toggle, not a commit.
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
    final disabled = loading || onPressed == null;

    return SizedBox(
      height: 54,
      child: Material(
        color: disabled ? palette.accent.withValues(alpha: 0.5) : palette.accent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
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
                          letterSpacing: -0.1,
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

/// The small uppercase label that heads almost every section in the
/// design — 11px, semibold, wide tracking, secondary color. Common
/// enough that every screen was repeating the same four lines of
/// `copyWith`.
class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        height: 1.3,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.99,
        color: color ?? palette.textSecondary,
      ),
    );
  }
}

/// The 44×44 rounded-square icon button the design uses for back
/// navigation and for the refresh affordance on the home and life
/// screens.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  const SquareIconButton({super.key, required this.icon, this.onPressed, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Opacity(
            opacity: onPressed == null ? 0.5 : 1,
            child: Icon(icon, size: 19, color: iconColor ?? palette.textSecondary),
          ),
        ),
      ),
    );
  }
}
