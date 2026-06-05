import 'package:flutter/material.dart';

import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';

class TelemetrySparkline extends StatelessWidget {
  final String label;
  final double value;
  final TelemetryTone tone;

  const TelemetrySparkline({
    super.key,
    required this.label,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = switch (tone) {
      TelemetryTone.active => AppColors.accentCyan,
      TelemetryTone.validate => AppColors.accentEmerald,
      TelemetryTone.human => AppColors.accentAmber,
    };
    final pct = (value * 100).round();
    return SizedBox(
      width: 170,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.panelFillStrong,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.panelStroke, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$pct%',
                    style: t.textTheme.labelSmall?.copyWith(color: c, fontFamily: AppFonts.telemetry),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 7,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: AppColors.panelStroke.withValues(alpha: 0.55))),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        width: 170 * value.clamp(0, 1),
                        color: c.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
