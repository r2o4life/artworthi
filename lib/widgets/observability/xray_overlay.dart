import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/core/observability/perf_metrics.dart';
import 'package:portfoliox/theme.dart';

class XRayOverlay extends StatelessWidget {
  const XRayOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final probes = controller.probes;
    final perf = controller.perf;

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(child: CustomPaint(painter: _ProbePainter(probes: probes))),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _PerfHud(perf: perf, probeCount: probes.length),
          ),
        ],
      ),
    );
  }
}

class _PerfHud extends StatelessWidget {
  final int probeCount;
  final PerfMetrics perf;
  const _PerfHud({required this.perf, required this.probeCount});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final fps = perf.fps;
    final buildUs = perf.buildMicrosAvg;
    final rasterUs = perf.rasterMicrosAvg;
    final totalUs = perf.totalMicrosAvg;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelFillStrong.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.panelStroke.withValues(alpha: 0.8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: DefaultTextStyle(
          style: t.textTheme.labelSmall!.copyWith(color: AppColors.textPrimary, fontFamily: AppFonts.telemetry, height: 1.45),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('XRAY • perf', style: t.textTheme.labelSmall!.copyWith(color: AppColors.accentCyan, fontFamily: AppFonts.telemetry, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text('fps: ${fps.toStringAsFixed(1)}'),
              Text('build: ${_fmtUs(buildUs)}'),
              Text('raster: ${_fmtUs(rasterUs)}'),
              Text('total: ${_fmtUs(totalUs)}'),
              Text('probes: $probeCount'),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtUs(int us) {
    if (us >= 1000) return '${(us / 1000).toStringAsFixed(2)}ms';
    return '${us}µs';
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accentCyan.withValues(alpha: 0.12);

    final major = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.accentCyan.withValues(alpha: 0.18);

    const spacing = 18.0;
    const majorEvery = 6;
    for (var x = 0.0; x <= size.width; x += spacing) {
      final p = (x / spacing).round();
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p % majorEvery == 0 ? major : paint);
    }
    for (var y = 0.0; y <= size.height; y += spacing) {
      final p = (y / spacing).round();
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p % majorEvery == 0 ? major : paint);
    }

    final center = Offset(size.width / 2, size.height / 2);
    final cross = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = AppColors.accentEmerald.withValues(alpha: 0.22);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), cross);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), cross);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accentEmerald.withValues(alpha: 0.12);
    final r = min(size.width, size.height) * 0.32;
    canvas.drawCircle(center, r, ring);
    canvas.drawCircle(center, r * 0.66, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProbePainter extends CustomPainter {
  final Map<String, Rect> probes;
  _ProbePainter({required this.probes});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.accentAmber.withValues(alpha: 0.55);
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentAmber.withValues(alpha: 0.06);

    for (final entry in probes.entries) {
      final rect = entry.value;
      final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(10));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ProbePainter oldDelegate) => oldDelegate.probes != probes;
}
