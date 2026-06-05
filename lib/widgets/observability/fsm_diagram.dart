import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/theme.dart';

class FsmDiagram extends StatefulWidget {
  final String projectId;
  const FsmDiagram({super.key, required this.projectId});

  @override
  State<FsmDiagram> createState() => _FsmDiagramState();
}

class _FsmDiagramState extends State<FsmDiagram> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final model = _models[widget.projectId] ?? _models.values.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final nodes = model.nodes
            .map((n) => n.copyWith(px: Offset(n.pos.dx * w, n.pos.dy * h)))
            .toList(growable: false);
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _EdgePainter(nodes: nodes, edges: model.edges))),
            ...nodes.map((n) {
              final selected = _selected == n.id;
              return Positioned(
                left: n.px.dx - 46,
                top: n.px.dy - 22,
                child: _FsmNode(
                  id: n.id,
                  label: n.label,
                  selected: selected,
                  onTap: () {
                    setState(() => _selected = n.id);
                    context.read<AppController>().logInteraction(type: 'FSM_SELECT', payload: {'project': widget.projectId, 'node': n.id});
                  },
                ),
              );
            }),
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _Legend(selected: _selected, model: model),
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final String? selected;
  final _FsmModel model;
  const _Legend({required this.selected, required this.model});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final text = selected == null
        ? 'These labels (IDLE / INPUT / COMPUTE / AUDIT / EXPORT) are the case study’s deterministic pipeline ontology. In UIC v2.0 terms: INPUT ≈ intent-vector normalization, COMPUTE ≈ MECE operator execution, AUDIT ≈ trace emission, EXPORT ≈ deterministic artifact output. Tap a node to inspect its transition contract.'
        : (model.descriptions[selected] ?? 'No contract registered.');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelFillStrong.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.panelStroke.withValues(alpha: 0.8), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: SizedBox(
          width: 320,
          child: Text(
            text,
            style: t.textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, height: 1.45, fontFamily: AppFonts.telemetry),
          ),
        ),
      ),
    );
  }
}

class _FsmNode extends StatelessWidget {
  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FsmNode({required this.id, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        scale: selected ? 1.04 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? AppColors.accentCyan.withValues(alpha: 0.18) : AppColors.panelFillStrong.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.accentCyan.withValues(alpha: 0.85) : AppColors.panelStroke.withValues(alpha: 0.8), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            child: Text(label, style: t.textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontFamily: AppFonts.telemetry)),
          ),
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<_FsmNodeLayout> nodes;
  final List<_FsmEdge> edges;
  _EdgePainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final n in nodes) n.id: n};
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.accentEmerald.withValues(alpha: 0.55);
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.panelStroke.withValues(alpha: 0.6);

    for (final e in edges) {
      final a = byId[e.from];
      final b = byId[e.to];
      if (a == null || b == null) continue;
      final path = Path();
      final p1 = a.px;
      final p2 = b.px;
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final ctrl = mid + Offset(0, (p1.dy < p2.dy ? -1 : 1) * 28);
      path.moveTo(p1.dx, p1.dy);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, p2.dx, p2.dy);
      canvas.drawPath(path, faint);
      canvas.drawPath(path, paint);
      _arrow(canvas, p2, (p2 - ctrl).direction);
    }
  }

  void _arrow(Canvas canvas, Offset tip, double angle) {
    final p = Paint()..color = AppColors.accentEmerald.withValues(alpha: 0.8);
    const len = 7.5;
    final a1 = angle + 2.5;
    final a2 = angle - 2.5;
    final p1 = tip + Offset(len * cos(a1), len * sin(a1));
    final p2 = tip + Offset(len * cos(a2), len * sin(a2));
    canvas.drawLine(tip, p1, p);
    canvas.drawLine(tip, p2, p);
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) => oldDelegate.nodes != nodes || oldDelegate.edges != edges;
}

class _FsmNodeLayout {
  final String id;
  final String label;
  final Offset pos;
  final Offset px;
  const _FsmNodeLayout({required this.id, required this.label, required this.pos, required this.px});
  _FsmNodeLayout copyWith({Offset? px}) => _FsmNodeLayout(id: id, label: label, pos: pos, px: px ?? this.px);
}

class _FsmEdge {
  final String from;
  final String to;
  const _FsmEdge(this.from, this.to);
}

class _FsmModel {
  final List<_FsmNodeLayout> nodes;
  final List<_FsmEdge> edges;
  final Map<String, String> descriptions;
  const _FsmModel({required this.nodes, required this.edges, required this.descriptions});
}

final Map<String, _FsmModel> _models = {
  'tipzero': _FsmModel(
    nodes: const [
      _FsmNodeLayout(id: 'idle', label: 'IDLE', pos: Offset(0.18, 0.35), px: Offset.zero),
      _FsmNodeLayout(id: 'input', label: 'INPUT', pos: Offset(0.42, 0.2), px: Offset.zero),
      _FsmNodeLayout(id: 'compute', label: 'COMPUTE', pos: Offset(0.62, 0.35), px: Offset.zero),
      _FsmNodeLayout(id: 'audit', label: 'AUDIT', pos: Offset(0.78, 0.58), px: Offset.zero),
      _FsmNodeLayout(id: 'export', label: 'EXPORT', pos: Offset(0.52, 0.72), px: Offset.zero),
    ],
    edges: const [
      _FsmEdge('idle', 'input'),
      _FsmEdge('input', 'compute'),
      _FsmEdge('compute', 'audit'),
      _FsmEdge('audit', 'export'),
      _FsmEdge('export', 'idle'),
    ],
    descriptions: const {
      'idle': 'Invariant: no side effects. Await explicit user input. (R≈1: pixels should not move without ΔS)',
      'input': 'UIC: Build the unified intent vector ι⃗ (focus + kinetics + semantics + transit + exogenous). Clamp to a bounded action stream.',
      'compute': 'UIC: Apply exactly one MECE operator (CRUDPA‑XT). In-app this is the reducer step: deterministic math only.',
      'audit': 'Emit JSONL trace with action + latency + state snapshot (the replayable trajectory).',
      'export': 'Deterministic output: identical intent stream → identical artifact (pixels/logs).',
    },
  ),
  'passinglane': _FsmModel(
    nodes: const [
      _FsmNodeLayout(id: 'boot', label: 'BOOT', pos: Offset(0.2, 0.25), px: Offset.zero),
      _FsmNodeLayout(id: 'tick', label: 'TICK', pos: Offset(0.5, 0.18), px: Offset.zero),
      _FsmNodeLayout(id: 'collide', label: 'COLLIDE', pos: Offset(0.76, 0.32), px: Offset.zero),
      _FsmNodeLayout(id: 'score', label: 'SCORE', pos: Offset(0.72, 0.62), px: Offset.zero),
      _FsmNodeLayout(id: 'replay', label: 'REPLAY', pos: Offset(0.42, 0.72), px: Offset.zero),
    ],
    edges: const [
      _FsmEdge('boot', 'tick'),
      _FsmEdge('tick', 'collide'),
      _FsmEdge('collide', 'score'),
      _FsmEdge('score', 'tick'),
      _FsmEdge('score', 'replay'),
      _FsmEdge('replay', 'boot'),
    ],
    descriptions: const {
      'boot': 'Seed selection + fixed timestep contract.',
      'tick': 'Integrate inputs, advance simulation exactly one step.',
      'collide': 'Collision predicate → deterministic resolution.',
      'score': 'Update score ledger; persist trace for QA.',
      'replay': 'Rerun from seed + action stream; diff frame timings.',
    },
  ),
};
