import 'dart:math';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';

class SystemicSynthesisModule extends StatelessWidget {
  const SystemicSynthesisModule({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final profile = context.watch<SystemsProfile>();
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 980 ? 2 : 1;
    final isNarrow = w < 720;

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
                TelemetryPill(label: 'SYSTEMIC SYNTHESIS', tone: TelemetryTone.active, icon: Icons.account_tree_rounded),
                TelemetryPill(label: 'SDLC + structural systems', tone: TelemetryTone.validate),
                TelemetryPill(label: 'hardware-augmented paradigms', tone: TelemetryTone.human),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('The same deterministic rules.', style: t.textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Whether you are designing a backend, an API ecosystem, or a physical framework, '
              'the method is identical: define primitives → encode constraints → validate invariants → ship with telemetry.',
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.55),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (cols == 1)
              Column(
                children: [
                  _SdlcPipelineCard(softwareMethodology: profile.sdlcParadigms.softwareMethodology, compact: isNarrow),
                  const SizedBox(height: AppSpacing.lg),
                  _HardwareAugmentedCard(hardwareAugmentedSdlc: profile.sdlcParadigms.hardwareAugmentedSdlc, compact: isNarrow),
                ],
              )
            else
              GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                // Wide layouts can safely constrain height. Narrow layouts use Column above.
                childAspectRatio: 1.55,
                children: [
                  _SdlcPipelineCard(softwareMethodology: profile.sdlcParadigms.softwareMethodology, compact: false),
                  _HardwareAugmentedCard(hardwareAugmentedSdlc: profile.sdlcParadigms.hardwareAugmentedSdlc, compact: false),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SdlcPipelineCard extends StatelessWidget {
  final String softwareMethodology;
  final bool compact;
  const _SdlcPipelineCard({required this.softwareMethodology, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final chartH = compact ? 120.0 : 150.0;
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TelemetryPill(label: 'Software lifecycle pipeline', tone: TelemetryTone.validate),
              const Spacer(),
              Icon(Icons.route_rounded, color: AppColors.accentEmerald.withValues(alpha: 0.85), size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: chartH, child: CustomPaint(painter: _PipelinePainter(), child: const SizedBox.expand())),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Discovery → Spec → Design → Build → Test → Release → Observe',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry, height: 1.35),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            softwareMethodology,
            maxLines: compact ? 6 : 4,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              TelemetryPill(label: 'sprints', tone: TelemetryTone.active),
              TelemetryPill(label: 'automated tests', tone: TelemetryTone.validate),
              TelemetryPill(label: 'decentralized deploy', tone: TelemetryTone.human),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.accentEmerald.withValues(alpha: 0.7);
    final dot = Paint()..color = AppColors.textPrimary.withValues(alpha: 0.85);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.panelStroke.withValues(alpha: 0.5);

    final nodes = 7;
    final gap = size.width / (nodes + 1);
    final y = size.height * 0.55;

    final path = Path();
    for (var i = 0; i < nodes; i++) {
      final x = gap * (i + 1);
      final dy = sin(i * 0.9) * (size.height * 0.12);
      if (i == 0) {
        path.moveTo(x, y + dy);
      } else {
        path.lineTo(x, y + dy);
      }
    }
    canvas.drawPath(path, faint);
    canvas.drawPath(path, paint);

    for (var i = 0; i < nodes; i++) {
      final x = gap * (i + 1);
      final dy = sin(i * 0.9) * (size.height * 0.12);
      canvas.drawCircle(Offset(x, y + dy), 4.2, dot);
      canvas.drawCircle(Offset(x, y + dy), 7.5, Paint()..color = AppColors.accentEmerald.withValues(alpha: 0.14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HardwareAugmentedCard extends StatelessWidget {
  final String hardwareAugmentedSdlc;
  final bool compact;
  const _HardwareAugmentedCard({required this.hardwareAugmentedSdlc, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final chartH = compact ? 120.0 : 150.0;
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TelemetryPill(label: 'Hardware-augmented SDLC', tone: TelemetryTone.human),
              const Spacer(),
              Icon(Icons.precision_manufacturing_rounded, color: AppColors.accentAmber.withValues(alpha: 0.9), size: 18),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: chartH, child: CustomPaint(painter: _JoineryPainter(), child: const SizedBox.expand())),
          const SizedBox(height: AppSpacing.md),
          Text(
            hardwareAugmentedSdlc,
            maxLines: compact ? 7 : null,
            overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              TelemetryPill(label: 'tolerances', tone: TelemetryTone.validate),
              TelemetryPill(label: 'interfaces', tone: TelemetryTone.active),
              TelemetryPill(label: 'energy matrices', tone: TelemetryTone.human),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoineryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.panelStroke.withValues(alpha: 0.6);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = AppColors.accentCyan.withValues(alpha: 0.55);

    final rectA = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.14, size.height * 0.32, size.width * 0.42, size.height * 0.38),
      const Radius.circular(18),
    );
    final rectB = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.44, size.height * 0.20, size.width * 0.42, size.height * 0.52),
      const Radius.circular(18),
    );
    canvas.drawRRect(rectA, stroke);
    canvas.drawRRect(rectB, stroke);

    final join = Path()
      ..moveTo(size.width * 0.44, size.height * 0.45)
      ..lineTo(size.width * 0.56, size.height * 0.45);
    canvas.drawPath(join, glow);
    canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.45), 4.5, Paint()..color = AppColors.accentAmber.withValues(alpha: 0.9));
    canvas.drawCircle(Offset(size.width * 0.56, size.height * 0.45), 4.5, Paint()..color = AppColors.accentEmerald.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
