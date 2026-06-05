import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';
import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/widgets/observability/runtime_probe.dart';

class FrameworkLabModule extends StatelessWidget {
  const FrameworkLabModule({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final metrics = context.watch<List<FrameworkMetric>>();
    final profile = context.watch<SystemsProfile>();
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 1100 ? 3 : (w >= 820 ? 2 : 1);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                TelemetryPill(label: 'FRAMEWORK LAB', tone: TelemetryTone.active, icon: Icons.hub_rounded),
                TelemetryPill(label: 'proprietary protocols', tone: TelemetryTone.validate),
                TelemetryPill(label: 'graphs + meters', tone: TelemetryTone.human),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Protocols made visible.', style: t.textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Three systems—METRICS, GEMSG, and Universal BIOS—presented as bounded, inspectable UI machines. '
              'All signals are stream-driven and reducible.',
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.55),
            ),
            const SizedBox(height: AppSpacing.xl),
            _ProtocolGrid(cols: cols, metrics: metrics, profile: profile),
          ],
        ),
      ),
    );
  }
}

class _ProtocolGrid extends StatelessWidget {
  final int cols;
  final List<FrameworkMetric> metrics;
  final SystemsProfile profile;
  const _ProtocolGrid({required this.cols, required this.metrics, required this.profile});

  @override
  Widget build(BuildContext context) {
    final metricsFw = profile.proprietaryFrameworks.firstWhere((f) => f.id == 'metrics');
    final gemsgFw = profile.proprietaryFrameworks.firstWhere((f) => f.id == 'gemsg');
    final biosFw = profile.proprietaryFrameworks.firstWhere((f) => f.id == 'universal_bios');
    final items = [
      _ProtocolCard(
        title: metricsFw.name,
        subtitle: metricsFw.description,
        tone: TelemetryTone.validate,
        child: _MetricsBreakdown(metrics: metrics),
      ),
      _ProtocolCard(
        title: 'GEMSG',
        subtitle: gemsgFw.description,
        tone: TelemetryTone.active,
        child: _FrameworkComponentList(components: gemsgFw.components, tone: TelemetryTone.active),
      ),
      _ProtocolCard(
        title: 'UNIVERSAL BIOS',
        subtitle: biosFw.description,
        tone: TelemetryTone.human,
        child: _FrameworkComponentList(components: biosFw.components, tone: TelemetryTone.human),
      ),
    ];

    return GridView.count(
      crossAxisCount: cols,
      mainAxisSpacing: AppSpacing.lg,
      crossAxisSpacing: AppSpacing.lg,
      childAspectRatio: cols == 1 ? 1.05 : 1.15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items,
    );
  }
}

class _FrameworkComponentList extends StatelessWidget {
  final List<String> components;
  final TelemetryTone tone;
  const _FrameworkComponentList({required this.components, required this.tone});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Components', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: components.map((c) => TelemetryPill(label: c, tone: tone)).toList(growable: false),
        ),
        const Spacer(),
        Text(
          'Deterministic mapping: components → primitives → constraints → observable outputs',
          style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry),
        ),
      ],
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final TelemetryTone tone;
  final Widget child;
  const _ProtocolCard({required this.title, required this.subtitle, required this.tone, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final controller = context.read<AppController>();
    final c = switch (tone) {
      TelemetryTone.active => AppColors.accentCyan,
      TelemetryTone.validate => AppColors.accentEmerald,
      TelemetryTone.human => AppColors.accentAmber,
    };

    return RuntimeProbe(
      id: 'framework_protocol/${title.toLowerCase()}',
      child: MouseRegion(
        onEnter: (_) => controller.logInteraction(type: 'UI_HOVER', payload: {'target': 'protocol', 'id': title}),
        child: NeoPanel(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TelemetryPill(label: title, tone: tone),
                  const Spacer(),
                  Icon(Icons.bolt_rounded, color: c.withValues(alpha: 0.8), size: 18),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsBreakdown extends StatelessWidget {
  final List<FrameworkMetric> metrics;
  const _MetricsBreakdown({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final normalized = metrics.isEmpty
        ? const <double>[0.5, 0.6, 0.7, 0.55, 0.65]
        : metrics.map((m) => (m.value.clamp(0, 1) as num).toDouble()).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(
            painter: _RadarPainter(values: normalized),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Nodes', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: const [
            TelemetryPill(label: 'Magnitude', tone: TelemetryTone.active),
            TelemetryPill(label: 'Efficiency', tone: TelemetryTone.validate),
            TelemetryPill(label: 'Threshold', tone: TelemetryTone.validate),
            TelemetryPill(label: 'Indexes', tone: TelemetryTone.active),
            TelemetryPill(label: 'Ratios', tone: TelemetryTone.human),
          ],
        ),
        const Spacer(),
        Text(
          'Formula: Outcome = (Magnitude × Efficiency) / (Threshold × Risk)',
          style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry),
        ),
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;
  _RadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) * 0.42;
    final gridPaint = Paint()
      ..color = AppColors.panelStroke.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final valuePaint = Paint()
      ..color = AppColors.accentEmerald.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = AppColors.accentEmerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var ring = 1; ring <= 3; ring++) {
      final rr = r * (ring / 3);
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final a = (-pi / 2) + (2 * pi * i / values.length);
        final p = center + Offset(cos(a), sin(a)) * rr;
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final poly = Path();
    for (var i = 0; i < values.length; i++) {
      final a = (-pi / 2) + (2 * pi * i / values.length);
      final p = center + Offset(cos(a), sin(a)) * (r * values[i].clamp(0, 1));
      if (i == 0) {
        poly.moveTo(p.dx, p.dy);
      } else {
        poly.lineTo(p.dx, p.dy);
      }
      canvas.drawLine(center, center + Offset(cos(a), sin(a)) * r, gridPaint);
    }
    poly.close();
    canvas.drawPath(poly, valuePaint);
    canvas.drawPath(poly, outline);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.values != values;
}

class _GemsgMatrix extends StatelessWidget {
  const _GemsgMatrix();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final items = const [
      ('Growth', Icons.trending_up_rounded, TelemetryTone.active),
      ('Engagement', Icons.touch_app_rounded, TelemetryTone.human),
      ('Monetization', Icons.payments_rounded, TelemetryTone.validate),
      ('Support', Icons.support_agent_rounded, TelemetryTone.human),
      ('Governance/Security', Icons.shield_rounded, TelemetryTone.validate),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Drivers', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: AppSpacing.md),
        ...items.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Icon(e.$2, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(e.$1, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary))),
                TelemetryPill(label: 'mapped', tone: e.$3),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Matrix: drivers × constraints → roadmap invariants',
          style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry),
        ),
      ],
    );
  }
}

class _BiosMap extends StatelessWidget {
  const _BiosMap();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Guardrails', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: AppSpacing.md),
        _BiosRow(
          left: 'hardware constraints',
          right: 'precision tolerances',
          tone: TelemetryTone.validate,
        ),
        const SizedBox(height: AppSpacing.sm),
        _BiosRow(
          left: 'software backend',
          right: 'API contracts',
          tone: TelemetryTone.active,
        ),
        const SizedBox(height: AppSpacing.sm),
        _BiosRow(
          left: 'agent networks',
          right: 'policy + verification',
          tone: TelemetryTone.human,
        ),
        const Spacer(),
        Text(
          'BIOS premise: same rules, different substrates.',
          style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}

class _BiosRow extends StatelessWidget {
  final String left;
  final String right;
  final TelemetryTone tone;
  const _BiosRow({required this.left, required this.right, required this.tone});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(left, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
        Expanded(
          child: Text(right, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
        ),
        const SizedBox(width: AppSpacing.sm),
        TelemetryPill(label: 'locked', tone: tone),
      ],
    );
  }
}
