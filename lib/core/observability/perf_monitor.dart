import 'dart:math';

import 'package:flutter/scheduler.dart';

import 'package:portfoliox/core/observability/perf_metrics.dart';

class PerfMonitor {
  final int window;
  final List<FrameTiming> _timings = <FrameTiming>[];
  void Function(PerfMetrics metrics)? onUpdate;

  PerfMonitor({this.window = 60, this.onUpdate});

  void start() {
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _timings.clear();
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);
    if (_timings.length > window) _timings.removeRange(0, _timings.length - window);

    final msPerFrame = _timings.isEmpty
        ? 0.0
        : _timings.map((t) => t.totalSpan.inMicroseconds / 1000.0).reduce((a, b) => a + b) / _timings.length;
    final fps = msPerFrame <= 0 ? 0.0 : min(240.0, 1000.0 / msPerFrame);

    int avgMicros(Duration Function(FrameTiming t) sel) {
      if (_timings.isEmpty) return 0;
      final sum = _timings.map((t) => sel(t).inMicroseconds).reduce((a, b) => a + b);
      return (sum / _timings.length).round();
    }

    onUpdate?.call(
      PerfMetrics(
        fps: fps,
        buildMicrosAvg: avgMicros((t) => t.buildDuration),
        rasterMicrosAvg: avgMicros((t) => t.rasterDuration),
        totalMicrosAvg: avgMicros((t) => t.totalSpan),
      ),
    );
  }
}
