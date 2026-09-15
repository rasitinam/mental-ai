import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// The app's one card surface: an opaque panel with a soft continuous
/// corner, separated from the stone ground by fill alone — no border, no
/// shadow stack.
///
/// [blur] stays opt-in: `BackdropFilter` forces a save-layer per surface
/// per frame, which dropped frames on a mid-range phone when every card
/// had one.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;
  final bool blur;

  /// A hairline outline, for a surface that must separate from another
  /// card-colored surface behind it.
  final bool bordered;

  /// Overrides the card fill — a tab-colored tile, for instance.
  final Color? color;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 22,
    this.blurSigma = 24,
    this.blur = false,
    this.bordered = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: bordered ? BorderSide(color: palette.glassBorder, width: 1.5) : BorderSide.none,
    );
    final fill = color ?? palette.glassFill;

    final surface = DecoratedBox(
      decoration: ShapeDecoration(
        color: blur ? fill.withValues(alpha: 0.86) : fill,
        shape: shape,
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

/// The app's constant backdrop, painted once into its own layer.
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

/// The primary call to action: an ink block, 56 tall.
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
      height: 56,
      child: Material(
        color: disabled ? palette.accent.withValues(alpha: 0.45) : palette.accent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: Center(
            child: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.onAccent),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: palette.onAccent),
                        const SizedBox(width: 9),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label.copyWith(
                            color: palette.onAccent,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
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

/// The small uppercase label that heads a group of rows or a card.
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
        fontFamily: AppTypography.bodyFamily,
        fontSize: 12.5,
        height: 1.3,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: color ?? palette.textSecondary,
      ),
    );
  }
}

/// The 44×44 rounded-square icon button used for back navigation.
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final String? tooltip;
  const SquareIconButton({super.key, required this.icon, this.onPressed, this.iconColor, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final button = Material(
      color: palette.glassFill,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Opacity(
            opacity: onPressed == null ? 0.45 : 1,
            child: Icon(icon, size: 22, color: iconColor ?? palette.textPrimary),
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
