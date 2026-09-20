import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

const _perfLog = bool.fromEnvironment('PERF_LOG');

/// Development tool: build with `--dart-define=PERF_LOG=true` (ideally in
/// `--profile` mode) and it prints one `PERF` line per ~2 seconds of
/// activity to the console / logcat: how many frames were drawn, how many
/// blew the 60 fps budget (16.7 ms) or dropped visibly (33 ms), and the
/// worst one, split into the UI thread (building/layout) and the raster
/// thread (painting). Without the define this is a constant `false` and the
/// whole thing is compiled out.
void startFrameMonitor() {
  if (!_perfLog) return;

  final totals = <int>[];
  var worstBuild = 0;
  var worstRaster = 0;

  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      totals.add(t.totalSpan.inMicroseconds);
      worstBuild = t.buildDuration.inMicroseconds > worstBuild ? t.buildDuration.inMicroseconds : worstBuild;
      worstRaster = t.rasterDuration.inMicroseconds > worstRaster ? t.rasterDuration.inMicroseconds : worstRaster;
    }
  });

  Timer.periodic(const Duration(seconds: 2), (_) {
    if (totals.isEmpty) return;
    final sorted = [...totals]..sort();
    int pct(double p) => sorted[((sorted.length - 1) * p).round()];
    final slow = totals.where((us) => us > 16700).length;
    final dropped = totals.where((us) => us > 33400).length;
    String ms(int us) => (us / 1000).toStringAsFixed(1);
    debugPrint('PERF frames=${totals.length} slow>16ms=$slow dropped>33ms=$dropped '
        'p50=${ms(pct(0.5))} p90=${ms(pct(0.9))} p99=${ms(pct(0.99))} max=${ms(sorted.last)} '
        'worstBuild=${ms(worstBuild)} worstRaster=${ms(worstRaster)}');
    totals.clear();
    worstBuild = 0;
    worstRaster = 0;
  });
}
