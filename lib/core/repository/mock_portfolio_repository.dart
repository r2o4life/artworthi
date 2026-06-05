import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/portfolio_project.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/core/models/system_log.dart';
import 'package:portfoliox/core/repository/portfolio_repository.dart';

class MockPortfolioRepository implements PortfolioRepository {
  final _rng = Random(42); // Deterministic pseudo-random for repeatability.
  final _metricsCtrl = StreamController<List<FrameworkMetric>>.broadcast();
  final _projectsCtrl = StreamController<List<PortfolioProject>>.broadcast();
  final _logsCtrl = StreamController<List<SystemLog>>.broadcast();

  Timer? _ticker;
  late List<FrameworkMetric> _metrics;
  late List<PortfolioProject> _projects;
  final List<SystemLog> _logs = [];

  MockPortfolioRepository() {
    _metrics = _seedMetrics();
    _projects = _seedProjects();
    _seedInitialLogs();
    _pushAll();
    _ticker = Timer.periodic(const Duration(milliseconds: 900), (_) => _tick());
  }

  void _seedInitialLogs() {
    final now = DateTime.now();
    const p = SystemsProfileSeed.systemsProfileArturoRobertoGarcia;
    final slug = p.identity.name.toLowerCase().replaceAll(' ', '_');
    final lines = <String>[
      'hydrate: profile/$slug • ${p.identity.currentLocation}',
      'stack: ${p.technicalArchitectureStack.frontendFramework}/${p.technicalArchitectureStack.language} • ${p.technicalArchitectureStack.heavyLogicExecution}',
      'streams: ${p.technicalArchitectureStack.backendEcosystem}',
      'entities: ${p.corporateEntities.designStudio} • ${p.corporateEntities.parentEntity} • ${p.corporateEntities.holdingCompany}',
      'contact: ${p.contactAndSocials.email} • ${p.contactAndSocials.digitalHq}',
      'protocols: METRICS • GEMSG • Universal BIOS',
    ];
    for (var i = 0; i < lines.length; i++) {
      _logs.add(
        SystemLog(
          id: 'seed_${now.microsecondsSinceEpoch}_$i',
          channel: 'telemetry',
          message: lines[i],
          severity: LogSeverity.info,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Stream<List<FrameworkMetric>> watchMetrics() => _metricsCtrl.stream;

  @override
  Stream<List<PortfolioProject>> watchProjects() => _projectsCtrl.stream;

  @override
  Stream<List<SystemLog>> watchSystemLogs({int limit = 12}) => _logsCtrl.stream.map((items) {
    if (items.length <= limit) return items;
    return items.sublist(items.length - limit);
  });

  @override
  Future<PortfolioProject?> getProjectById(String id) async {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _tick() {
    final now = DateTime.now();

    _metrics = _metrics.map((m) {
      final drift = (_rng.nextDouble() - 0.5) * (m.max - m.min) * 0.04;
      final next = (m.value + drift).clamp(m.min, m.max);
      return m.copyWith(value: next, updatedAt: now);
    }).toList(growable: false);

    final severity = _rng.nextDouble();
    final s = severity < 0.68
        ? LogSeverity.info
        : severity < 0.84
            ? LogSeverity.ok
            : severity < 0.95
                ? LogSeverity.warn
                : LogSeverity.err;

    _logs.add(
      SystemLog(
        id: 'log_${now.microsecondsSinceEpoch}',
        channel: 'telemetry',
        message: _synthLogLine(s),
        severity: s,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (_logs.length > 64) _logs.removeRange(0, _logs.length - 64);

    _pushAll();
  }

  String _synthLogLine(LogSeverity s) {
    const p = SystemsProfileSeed.systemsProfileArturoRobertoGarcia;
    final info = [
      'thread scheduled: layout/resolve',
      'stream pulse: realtime adapter idle',
      'profile scope: ${p.identity.professionalTitle}',
      'protocol tick: METRICS/Threshold',
      'protocol tick: GEMSG/Governance',
      'protocol tick: Universal BIOS/Guardrails',
    ];
    final ok = [
      'validation passed: invariants stable',
      'determinism: seed lock acquired',
      'render budget: within threshold',
    ];
    final warn = [
      'intervention suggested: review thresholds',
      'governance: operator confirmation recommended',
      'signal drift: recalibrate indexes/ratios',
    ];
    final err = [
      'constraint violated: reconcile state delta',
      'guardrail trip: Universal BIOS boundary breach',
      'telemetry: replay mismatch detected',
    ];

    final base = switch (s) {
      LogSeverity.info => info[_rng.nextInt(info.length)],
      LogSeverity.ok => ok[_rng.nextInt(ok.length)],
      LogSeverity.warn => warn[_rng.nextInt(warn.length)],
      LogSeverity.err => err[_rng.nextInt(err.length)],
    };
    final hash = _rng.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$base • 0x$hash';
  }

  void _pushAll() {
    if (!_metricsCtrl.isClosed) _metricsCtrl.add(_metrics);
    if (!_projectsCtrl.isClosed) _projectsCtrl.add(_projects);
    if (!_logsCtrl.isClosed) _logsCtrl.add(List.unmodifiable(_logs));
  }

  List<FrameworkMetric> _seedMetrics() {
    final now = DateTime.now();
    return [
      FrameworkMetric(
        id: 'magnitude',
        name: 'Magnitude',
        description: 'Impact amplitude across user + business vectors',
        value: 0.74,
        min: 0,
        max: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FrameworkMetric(
        id: 'efficiency',
        name: 'Efficiency',
        description: 'Outcome per unit cognitive + compute load',
        value: 0.61,
        min: 0,
        max: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FrameworkMetric(
        id: 'threshold',
        name: 'Threshold',
        description: 'Guardrail tightness before state divergence',
        value: 0.82,
        min: 0,
        max: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FrameworkMetric(
        id: 'indexes',
        name: 'Indexes',
        description: 'Composite signals normalized to invariants',
        value: 0.56,
        min: 0,
        max: 1,
        createdAt: now,
        updatedAt: now,
      ),
      FrameworkMetric(
        id: 'ratios',
        name: 'Ratios',
        description: 'Trade-off balances: trust/velocity, risk/return',
        value: 0.68,
        min: 0,
        max: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  List<PortfolioProject> _seedProjects() {
    final now = DateTime.now();
    const p = SystemsProfileSeed.systemsProfileArturoRobertoGarcia;
    PortfolioProject proj({
      required String id,
      required String name,
      required String tagline,
      required String domain,
      required List<String> bullets,
      required List<String> primitives,
      required List<ProjectMilestone> milestones,
    }) => PortfolioProject(
      id: id,
      name: name,
      tagline: tagline,
      domain: domain,
      bullets: bullets,
      primitives: primitives,
      milestones: milestones,
      createdAt: now,
      updatedAt: now,
    );

    ProjectMilestone ms(int week, String phase, String title, String desc) => ProjectMilestone(
      id: '${phase.toLowerCase()}_$week',
      week: week,
      phase: phase,
      title: title,
      description: desc,
      createdAt: now,
      updatedAt: now,
    );

    final tipZero = p.shippedProvenMatrix.firstWhere((x) => x.title == 'TipZero');
    final bridgeBound = p.shippedProvenMatrix.firstWhere((x) => x.title == 'Bridge Bound Connect');
    final passingLane = p.shippedProvenMatrix.firstWhere((x) => x.title == 'Passing Lane');
    final hitl = p.shippedProvenMatrix.firstWhere((x) => x.title == 'Human in the Loop');

    return [
      proj(
        id: 'tipzero',
        name: tipZero.title,
        tagline: '${tipZero.type} • ${tipZero.platform}',
        domain: 'Fintech / Deterministic Calculation',
        bullets: [
          tipZero.coreEngineering,
          'State management: explicit reducers + bounded deltas (zero hidden side effects).',
          'Telemetry: deterministic replay to guarantee auditability.',
        ],
        primitives: ['sum', 'round', 'invariant', 'ledger', 'delta'],
        milestones: [
          ms(1, 'Discovery', 'Constraint inventory', 'Define calculation invariants, rounding laws, and failure surfaces.'),
          ms(2, 'Design', 'Interaction compiler', 'Model inputs as an explicit state machine; no implicit side-effects.'),
          ms(3, 'Build', 'Realtime engine', 'Stream-driven computation graph with deterministic ordering.'),
          ms(4, 'Ship', 'Audit mode', 'Session replays + log export to guarantee traceability.'),
        ],
      ),
      proj(
        id: 'bridgebound',
        name: bridgeBound.title,
        tagline: '${bridgeBound.type} • ${bridgeBound.platform}',
        domain: 'Education / Rule Systems',
        bullets: [
          bridgeBound.coreEngineering,
          'Rule engine: deterministic progression with explicit checkpoints and rollback.',
          'Feedback loops: bounded signals that map to testable outcomes.',
        ],
        primitives: ['predicate', 'graph', 'checkpoint', 'feedback', 'rollback'],
        milestones: [
          ms(1, 'Discovery', 'Curriculum primitives', 'Decompose domain into rule nodes and testable conditions.'),
          ms(2, 'Design', 'Feedback lattice', 'Specify intervention points and confidence thresholds.'),
          ms(3, 'Build', 'Deterministic navigation', 'Route-based progression with declarative guards.'),
          ms(4, 'Ship', 'Telemetry overlays', 'Expose learning state as an observable system.'),
        ],
      ),
      proj(
        id: 'passinglane',
        name: passingLane.title,
        tagline: '${passingLane.type} • ${passingLane.platform}',
        domain: 'Games / Simulation',
        bullets: [
          passingLane.coreEngineering,
          'Engine-first UX: gameplay loop as a deterministic simulation contract.',
          'Replayability: seed-driven runs for tuning and QA.',
        ],
        primitives: ['tick', 'seed', 'collision', 'score', 'trajectory'],
        milestones: [
          ms(1, 'Discovery', 'Simulation contract', 'Define time-step and physics constraints.'),
          ms(2, 'Design', 'Input grammar', 'Map gestures to discrete actions and transitions.'),
          ms(3, 'Build', 'Loop + renderer', 'Fixed timestep updates; GPU-friendly composition.'),
          ms(4, 'Ship', 'Replay + tuning', 'Deterministic captures for balancing and QA.'),
        ],
      ),
      proj(
        id: 'hitl',
        name: hitl.title,
        tagline: '${hitl.type} • ${hitl.platform}',
        domain: 'Experiment / Governance',
        bullets: [
          hitl.coreEngineering,
          'Intervention UX: explicit manual gates as first-class system primitives.',
          'Guardrails: thresholds + traceable causality per decision.',
        ],
        primitives: ['threshold', 'policy', 'operator', 'override', 'consent'],
        milestones: [
          ms(1, 'Discovery', 'Safety model', 'Define what must never happen; encode as invariants.'),
          ms(2, 'Design', 'Intervention UI', 'Human approval flows with strict state transitions.'),
          ms(3, 'Build', 'Policy engine', 'Composable rules + replayable event sourcing.'),
          ms(4, 'Ship', 'Governance report', 'Exportable audit summaries and decision maps.'),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_metricsCtrl.close());
    unawaited(_projectsCtrl.close());
    unawaited(_logsCtrl.close());
  }
}
