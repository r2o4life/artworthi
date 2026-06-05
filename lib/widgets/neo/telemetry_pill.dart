import 'package:flutter/material.dart';

import 'package:portfoliox/theme.dart';

enum TelemetryTone { active, validate, human }

class TelemetryPill extends StatelessWidget {
  final String label;
  final TelemetryTone tone;
  final IconData? icon;
  final VoidCallback? onTap;

  const TelemetryPill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final c = _toneColor(tone);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: t.textTheme.labelSmall?.copyWith(
              color: c,
              letterSpacing: 0.6,
              fontFamily: AppFonts.telemetry,
            ),
          ),
        ),
      ],
    );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.panelFillStrong,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: 0.32), width: 1),
          ),
          child: content,
        ),
      ),
    );
  }

  Color _toneColor(TelemetryTone t) => switch (t) {
        TelemetryTone.active => AppColors.accentCyan,
        TelemetryTone.validate => AppColors.accentEmerald,
        TelemetryTone.human => AppColors.accentAmber,
      };
}
