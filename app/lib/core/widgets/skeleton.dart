import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// A placeholder rectangle with a slow shimmer sweep, standing in for text
/// or an image while real content loads — reads as "something is coming"
/// rather than the dead time a bare spinner leaves in the middle of the
/// screen it's about to fill.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({super.key, this.width = double.infinity, this.height = 14, this.radius = 6});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      width: widget.width == double.infinity ? null : widget.width,
      height: widget.height,
      child: widget.width == double.infinity
          ? _shimmer(palette)
          : SizedBox(width: widget.width, child: _shimmer(palette)),
    );
  }

  Widget _shimmer(AppPalette palette) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Sweeps a lighter band left to right and loops — the -1..2 range
        // (rather than 0..1) gives the band room to fully enter and leave
        // the box instead of popping in already at full brightness.
        final t = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(t - 0.3, 0),
            end: Alignment(t + 0.3, 0),
            colors: [palette.surfaceMuted, palette.glassBorder, palette.surfaceMuted],
          ).createShader(bounds),
          child: DecoratedBox(
            decoration:
                BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(widget.radius)),
          ),
        );
      },
    );
  }
}
