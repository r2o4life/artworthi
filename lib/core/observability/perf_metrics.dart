class PerfMetrics {
  final double fps;
  final int buildMicrosAvg;
  final int rasterMicrosAvg;
  final int totalMicrosAvg;

  const PerfMetrics({required this.fps, required this.buildMicrosAvg, required this.rasterMicrosAvg, required this.totalMicrosAvg});

  const PerfMetrics.empty()
      : fps = 0,
        buildMicrosAvg = 0,
        rasterMicrosAvg = 0,
        totalMicrosAvg = 0;

  Map<String, Object?> toJson() => {
        'fps': fps,
        'build_us_avg': buildMicrosAvg,
        'raster_us_avg': rasterMicrosAvg,
        'total_us_avg': totalMicrosAvg,
      };
}
