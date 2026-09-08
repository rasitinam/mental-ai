import 'dart:async';

import 'package:flutter/widgets.dart';

/// A ticking "time left" label that repaints only itself.
///
/// The mood and journal screens both show a cooldown countdown. Both used to
/// drive it with a screen-level `Timer.periodic` calling `setState`, which
/// rebuilt the whole screen — composer, archive, every card — once a second,
/// and kept doing it while the user was on a different tab, because the
/// shell keeps each branch alive. This widget owns the timer instead, so a
/// tick rebuilds one `Text`, and it stops the timer the moment the deadline
/// passes rather than ticking forever.
class CountdownText extends StatefulWidget {
  /// When the countdown reaches zero.
  final DateTime until;

  /// Renders the remaining time. Called on every tick.
  final String Function(Duration remaining) format;

  /// Fired once when the deadline passes, so the screen can swap the
  /// cooldown card back for the form.
  final VoidCallback? onFinished;
  final TextStyle? style;
  final TextAlign? textAlign;

  const CountdownText({
    super.key,
    required this.until,
    required this.format,
    this.onFinished,
    this.style,
    this.textAlign,
  });

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _ticker;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.until.difference(DateTime.now());
    _start();
  }

  @override
  void didUpdateWidget(CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) {
      _remaining = widget.until.difference(DateTime.now());
      _start();
    }
  }

  void _start() {
    _ticker?.cancel();
    if (_remaining <= Duration.zero) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.until.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _ticker?.cancel();
        // Deferred: the callback usually rebuilds the parent, which can't
        // happen during this widget's own build/tick without a frame race.
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onFinished?.call());
      }
      if (mounted) setState(() => _remaining = remaining);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _remaining > Duration.zero ? _remaining : Duration.zero;
    return Text(widget.format(remaining), style: widget.style, textAlign: widget.textAlign);
  }
}
