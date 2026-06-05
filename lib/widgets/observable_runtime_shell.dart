import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/observability/perf_monitor.dart';
import 'package:portfoliox/core/observability/runtime_event.dart';
import 'package:portfoliox/core/state/app_actions.dart';
import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';
import 'package:portfoliox/widgets/observability/xray_overlay.dart';

class ObservableRuntimeShell extends StatefulWidget {
  final Widget child;
  const ObservableRuntimeShell({super.key, required this.child});

  @override
  State<ObservableRuntimeShell> createState() => _ObservableRuntimeShellState();
}

class _ObservableRuntimeShellState extends State<ObservableRuntimeShell> {
  PerfMonitor? _monitor;
  Timer? _replayTimer;
  bool _booted = false;
  bool _xrayGuideCollapsed = false;
  bool _uicExpanded = true;

  /// Deterministic boundary clamp: never allow XRAY guide to exceed viewport.
  /// This is the UI equivalent of UIC's boundary normalization: overflow is
  /// treated as an exogenous disturbance and absorbed by a bounded container
  /// (scroll), instead of letting layout explode.
  double _xrayGuideMaxHeightFor(BuildContext context) {
    final media = MediaQuery.of(context);
    final top = media.padding.top + AppSpacing.lg;
    final bottom = AppSpacing.lg;
    final h = media.size.height - top - bottom;
    // Ensure a sensible minimum so the panel remains usable.
    return h.clamp(260.0, 920.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_booted) return;
    _booted = true;
    final c = context.read<AppController>();
    _monitor = PerfMonitor(onUpdate: c.setPerf)..start();
  }

  @override
  void dispose() {
    _replayTimer?.cancel();
    _replayTimer = null;
    _monitor?.stop();
    _monitor = null;
    super.dispose();
  }

  void _toggleAutoReplay(AppController c) {
    final shouldRun = _replayTimer == null;
    if (!shouldRun) {
      _replayTimer?.cancel();
      _replayTimer = null;
      c.setReplayPaused(true);
      c.logInteraction(type: 'REPLAY_STOP', payload: {'cursor': c.cursor});
      return;
    }

    c.setReplayPaused(false);
    c.logInteraction(type: 'REPLAY_START', payload: {'cursor': c.cursor});
    _replayTimer = Timer.periodic(const Duration(milliseconds: 320), (_) {
      if (!mounted) return;
      if (c.replayPaused) return;
      if (c.canStepForward) {
        c.stepForward();
      } else {
        c.setReplayPaused(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // This shell renders ABOVE the app's Navigator (because it's in
    // MaterialApp.builder). That means it does NOT automatically have access to
    // the Navigator's Overlay/Material ancestors.
    //
    // Tooltips (IconButton.tooltip), InkWell, menus, etc. require a Material +
    // Overlay above them.
    //
    // Also note: Overlay(initialEntries: ...) only applies entries once; the
    // OverlayEntry will NOT rebuild just because this widget rebuilds. So we
    // bind the OverlayEntry's builder to AppController via ListenableBuilder.
    final c = context.read<AppController>();

    return Material(
      type: MaterialType.transparency,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (overlayContext) {
              return ListenableBuilder(
                listenable: c,
                builder: (context, _) {
                  final s = c.state;
                  final w = MediaQuery.sizeOf(overlayContext).width;
                  final drawerW = (w * 0.92).clamp(320.0, 560.0);

                   // When XRAY is enabled we slightly dim the underlying app so the
                   // grid/probes read clearly, but we keep enough contrast that
                   // intentional UI (like the case-study FSM diagram) doesn’t look
                   // like “ghost artifacts”.
                   final child = AnimatedOpacity(
                     duration: const Duration(milliseconds: 220),
                     curve: Curves.easeOutCubic,
                     opacity: s.xrayEnabled ? 0.52 : 1,
                     child: widget.child,
                   );

                  return Stack(
                    children: [
                      child,
                      if (s.xrayEnabled) const Positioned.fill(child: XRayOverlay()),
                       if (s.xrayEnabled)
                         Positioned(
                           right: AppSpacing.lg,
                           top: MediaQuery.paddingOf(overlayContext).top + AppSpacing.lg,
                           child: _XrayExitBeacon(
                             onExit: () {
                               c.dispatch(const ToggleXRay());
                               c.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'xray', 'enabled': false, 'source': 'exit_beacon'});
                             },
                           ),
                         ),
                       if (s.xrayEnabled)
                         Positioned(
                           left: AppSpacing.lg,
                           top: MediaQuery.paddingOf(overlayContext).top + AppSpacing.lg,
                            bottom: AppSpacing.lg,
                           child: _XRayGuidePanel(
                             collapsed: _xrayGuideCollapsed,
                              uicExpanded: _uicExpanded,
                              maxHeight: _xrayGuideMaxHeightFor(overlayContext),
                             onToggleCollapsed: () {
                               setState(() => _xrayGuideCollapsed = !_xrayGuideCollapsed);
                               c.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'xray_guide', 'collapsed': !_xrayGuideCollapsed});
                             },
                              onToggleUic: () {
                                setState(() => _uicExpanded = !_uicExpanded);
                                c.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'xray_guide_uic', 'expanded': !_uicExpanded});
                              },
                           ),
                         ),
                      Positioned(
                        right: 0,
                        top: MediaQuery.paddingOf(overlayContext).top + 120,
                        child: _TelemetryEdgeBadge(
                          open: s.telemetryDrawerOpen,
                          onTap: () {
                            c.logInteraction(type: 'UI_TAP', payload: {'target': 'telemetry_badge'});
                            c.dispatch(const ToggleTelemetryDrawer());
                          },
                        ),
                      ),
                      _TelemetryDrawer(
                        width: drawerW,
                        open: s.telemetryDrawerOpen,
                        onClose: () => c.dispatch(const SetTelemetryDrawerOpen(false)),
                        onPause: () {
                          c.setReplayPaused(!c.replayPaused);
                          c.logInteraction(type: 'REPLAY_PAUSE_TOGGLE', payload: {'paused': c.replayPaused, 'cursor': c.cursor});
                        },
                        onRewind: () {
                          c.rewindToStart();
                          c.setReplayPaused(true);
                          c.logInteraction(type: 'REPLAY_REWIND', payload: {'cursor': c.cursor});
                        },
                        onStepBack: () {
                          c.stepBack();
                          c.setReplayPaused(true);
                          c.logInteraction(type: 'REPLAY_STEP_BACK', payload: {'cursor': c.cursor});
                        },
                        onStepForward: () {
                          c.stepForward();
                          c.setReplayPaused(true);
                          c.logInteraction(type: 'REPLAY_STEP_FORWARD', payload: {'cursor': c.cursor});
                        },
                        onAutoReplay: () => _toggleAutoReplay(c),
                        onClear: c.clearRuntimeLog,
                        onToggleXray: () {
                          c.dispatch(const ToggleXRay());
                          c.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'xray', 'enabled': !s.xrayEnabled});
                        },
                        onScrub: (i) {
                          c.jumpTo(i);
                          c.setReplayPaused(true);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _XrayExitBeacon extends StatefulWidget {
  final VoidCallback onExit;
  const _XrayExitBeacon({required this.onExit});

  @override
  State<_XrayExitBeacon> createState() => _XrayExitBeaconState();
}

class _XrayExitBeaconState extends State<_XrayExitBeacon> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = Curves.easeInOutCubic.transform(_c.value);
        final borderA = (0.55 + (v * 0.35)).clamp(0.0, 1.0);
        final glowA = (0.22 + (v * 0.18)).clamp(0.0, 1.0);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onExit,
            child: NeoPanel(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accentCyan.withValues(alpha: borderA), width: 1.4 + (v * 0.8)),
                  boxShadow: [
                    BoxShadow(color: AppColors.accentCyan.withValues(alpha: glowA), blurRadius: 22 + (v * 12), spreadRadius: 0),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, size: 16, color: AppColors.accentCyan),
                      const SizedBox(width: 8),
                      Text('XRAY ON', style: t.textTheme.labelMedium?.copyWith(color: AppColors.textPrimary, fontFamily: AppFonts.telemetry, letterSpacing: 1.1)),
                      const SizedBox(width: 10),
                      Text('tap to exit', style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry)),
                      const SizedBox(width: 10),
                      Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TelemetryEdgeBadge extends StatelessWidget {
  final bool open;
  final VoidCallback onTap;
  const _TelemetryEdgeBadge({required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // On Flutter web/desktop, Overlay + InkWell can occasionally feel flaky
    // (gesture arena + hit-test interactions). GestureDetector with explicit
    // opaque hit-testing is the most deterministic path.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          final c = context.read<AppController>();
          c.logInteraction(type: 'UI_POINTER_DOWN', payload: {'target': 'telemetry_badge'});
        },
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.panelFillStrong.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              border: Border.all(color: AppColors.panelStroke.withValues(alpha: 0.85), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(open ? Icons.terminal_rounded : Icons.bolt_rounded, color: AppColors.accentCyan, size: 18),
                const SizedBox(width: 8),
                Text('telemetry', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary, fontFamily: AppFonts.telemetry, letterSpacing: 0.8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XRayGuidePanel extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final bool uicExpanded;
  final VoidCallback onToggleUic;
  final double maxHeight;

  const _XRayGuidePanel({required this.collapsed, required this.onToggleCollapsed, required this.uicExpanded, required this.onToggleUic, required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final panelW = (w * 0.92).clamp(280.0, 520.0);
    final focusedProjectId = context.select<AppController, String?>((c) => c.state.focusedProjectId);

    // When a case study is open we want the guide to be less dominant and more
    // likely to coexist with right-side telemetry.
    final effectiveMaxWidth = focusedProjectId == null ? panelW : panelW.clamp(280.0, 460.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: collapsed ? 210 : effectiveMaxWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: NeoPanel(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const TelemetryPill(label: 'XRAY GUIDE', tone: TelemetryTone.validate, icon: Icons.visibility_rounded),
                  const Spacer(),
                  IconButton(
                    onPressed: onToggleCollapsed,
                    tooltip: collapsed ? 'Expand' : 'Collapse',
                    style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
                    icon: Icon(collapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (collapsed) ...[
                const SizedBox(height: 6),
                Text(
                  'Grid • probes • perf.\n'
                  'Expand for ontology.',
                  style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What you’re seeing', style: t.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, height: 1.2)),
                          const SizedBox(height: 6),
                          _GuideLine(dotColor: AppColors.accentCyan, title: 'Cyan grid = coordinate frame', body: 'A stable reference so motion, layout shifts, and alignment errors become obvious.'),
                          _GuideLine(dotColor: AppColors.accentAmber, title: 'Amber boxes = probes', body: 'These are real widget bounds measured at runtime from `RuntimeProbe(id: ...)` wrappers.'),
                          _GuideLine(dotColor: AppColors.accentEmerald, title: 'Emerald crosshair/rings = centering bias', body: 'A quick way to spot off-center composition and inconsistent spacing systems.'),
                          _GuideLine(dotColor: AppColors.textSecondary, title: 'XRAY • perf HUD', body: 'Frame timing summary (build/raster/total) + number of active probes.'),
                          const SizedBox(height: AppSpacing.md),
                          Text('Ontology (why XRAY exists)', style: t.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, height: 1.2)),
                          const SizedBox(height: 6),
                          Text(
                            'The portfolio is treated as a deterministic state machine. XRAY makes the “contract” visible: what went in, what the system computed, and what it rendered.',
                            style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _OntologyRow(label: 'Inputs', value: 'taps • scroll • route changes • time'),
                          _OntologyRow(label: 'Primitives', value: 'actions • reducers • streams • probes'),
                          _OntologyRow(label: 'Constraints', value: 'layout • theme • invariants • perf budgets'),
                          _OntologyRow(label: 'Outputs', value: 'pixels • logs • trace trajectory'),
                          const SizedBox(height: AppSpacing.md),
                          _UicPanel(expanded: uicExpanded, onToggle: onToggleUic),
                          if (focusedProjectId != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text('Case-study FSM (IDLE → INPUT → COMPUTE → EXPORT)', style: t.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, height: 1.2)),
                            const SizedBox(height: 6),
                            Text(
                              'Those faint words are not rendering artifacts—they’re the case study’s explicit runtime pipeline ontology. In XRAY mode, the left panel swaps from editorial narrative to a finite-state machine diagram.',
                              style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _OntologyRow(label: 'IDLE', value: 'No side effects. Await an explicit trigger.'),
                            _OntologyRow(label: 'INPUT', value: 'Normalize input into a bounded action stream.'),
                            _OntologyRow(label: 'COMPUTE', value: 'Pure reducer step: deterministic math only.'),
                            _OntologyRow(label: 'AUDIT', value: 'Emit trace: action + latency + state snapshot.'),
                            _OntologyRow(label: 'EXPORT', value: 'Deterministic output: identical stream → identical artifact.'),
                            const SizedBox(height: 6),
                            Text(
                              'Tip: tap a node in the FSM diagram to read its “transition contract” in the legend.',
                              style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Text('How to use it (fast)', style: t.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary, height: 1.2)),
                          const SizedBox(height: 6),
                          Text(
                            '1) Open telemetry → toggle XRAY.\n'
                            '2) Scroll a case study: watch probe rectangles update deterministically.\n'
                            '3) Use replay controls to step the reducer trajectory and correlate events → state → pixels.',
                            style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String body;
  const _GuideLine({required this.dotColor, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: DecoratedBox(
              decoration: BoxDecoration(color: dotColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(99)),
              child: const SizedBox(width: 8, height: 8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.textTheme.labelLarge?.copyWith(color: AppColors.textPrimary, height: 1.25)),
                const SizedBox(height: 2),
                Text(body, style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OntologyRow extends StatelessWidget {
  final String label;
  final String value;
  const _OntologyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(label.toUpperCase(), style: t.textTheme.labelSmall?.copyWith(color: AppColors.accentCyan, fontFamily: AppFonts.telemetry, letterSpacing: 1.0)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(value, style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35))),
        ],
      ),
    );
  }
}

class _UicPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  const _UicPanel({required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return NeoPanel(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TelemetryPill(label: 'UIC v2.0', tone: TelemetryTone.active, icon: Icons.memory_rounded),
              const Spacer(),
              IconButton(
                onPressed: onToggle,
                tooltip: expanded ? 'Hide spec' : 'Show spec',
                style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
                icon: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 6),
            Text(
              'Closed-loop deterministic interaction compiler. Every boundary event is normalized into a single intent vector ι⃗, then mapped to exactly one MECE operator (CRUDPA‑XT).',
              style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Intent vector ι⃗ (what crossed the boundary)', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            _OntologyRow(label: 'ω_focus', value: 'Where it happened (grid address / coordinate frame)'),
            _OntologyRow(label: 'V_kinetic', value: 'How it moved (velocity / trajectory / frequency)'),
            _OntologyRow(label: 'σ_semantic', value: 'What it carried (text / bytes / structured payload)'),
            _OntologyRow(label: 'τ_transit', value: 'How long ingress took (loading/hydration/transit)'),
            _OntologyRow(label: 'ξ_exogenous', value: 'What interfered (layout shifts / host overrides / extensions)'),
            const SizedBox(height: AppSpacing.sm),
            Text('MECE operator space Ψ_Crudpa‑XT (what we do with it)', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            _GuideLine(dotColor: AppColors.accentCyan, title: 'O_C / O_R / O_U / O_D', body: 'Main-thread schema mutations (create/read/update/delete).'),
            _GuideLine(dotColor: AppColors.accentAmber, title: 'O_X (exogenous)', body: 'Host interference. In telemetry, look for `O_X_EXOGENOUS` emitted by probes during transient transforms.'),
            _GuideLine(dotColor: AppColors.accentEmerald, title: 'O_P / O_A / O_T', body: 'Off-thread process/automate/transit. In this build they’re conceptual placeholders; transit is visible as loading/hydration states.'),
            const SizedBox(height: AppSpacing.sm),
            Text('Invariant checklist (what “stable” means here)', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            _GuideLine(dotColor: AppColors.textSecondary, title: 'T (threshold)', body: 'Frame budget: build+raster should stay under refresh constraints (see perf HUD).'),
            _GuideLine(dotColor: AppColors.textSecondary, title: 'R (ratio)', body: 'No repaint without state: replay lets you correlate events → state → pixels.'),
            _GuideLine(dotColor: AppColors.textSecondary, title: 'E (efficiency)', body: 'Inputs should not generate redundant state changes (watch for many UI_* without STATE_CHANGE).'),
          ],
        ],
      ),
    );
  }
}

class _TelemetryDrawer extends StatefulWidget {
  final double width;
  final bool open;
  final VoidCallback onClose;
  final VoidCallback onPause;
  final VoidCallback onRewind;
  final VoidCallback onStepBack;
  final VoidCallback onStepForward;
  final VoidCallback onAutoReplay;
  final VoidCallback onClear;
  final VoidCallback onToggleXray;
  final ValueChanged<int> onScrub;

  const _TelemetryDrawer({
    required this.width,
    required this.open,
    required this.onClose,
    required this.onPause,
    required this.onRewind,
    required this.onStepBack,
    required this.onStepForward,
    required this.onAutoReplay,
    required this.onClear,
    required this.onToggleXray,
    required this.onScrub,
  });

  @override
  State<_TelemetryDrawer> createState() => _TelemetryDrawerState();
}

class _TelemetryDrawerState extends State<_TelemetryDrawer> {
  final _scroll = ScrollController();
  bool _jumpScheduled = false;

  @override
  void didUpdateWidget(covariant _TelemetryDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open) {
      _scheduleJumpToBottom();
    }
  }

  void _scheduleJumpToBottom() {
    if (_jumpScheduled) return;
    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      _jumpToBottom();
    });
  }

  void _jumpToBottom() {
    if (!mounted || !_scroll.hasClients) return;
    try {
      final max = _scroll.position.maxScrollExtent;
      if (max.isFinite) _scroll.jumpTo(max);
    } catch (_) {
      // Ignore transient scroll attachment/layout exceptions.
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final s = c.state;
    final open = widget.open;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      top: MediaQuery.paddingOf(context).top + AppSpacing.lg,
      bottom: AppSpacing.lg,
      right: open ? AppSpacing.lg : -(widget.width + AppSpacing.lg),
      width: widget.width,
      child: NeoPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const TelemetryPill(label: 'OBSERVABLE RUNTIME', tone: TelemetryTone.active, icon: Icons.terminal_rounded),
                const SizedBox(width: AppSpacing.sm),
                TelemetryPill(
                  label: s.xrayEnabled ? 'x-ray ON' : 'x-ray OFF',
                  tone: s.xrayEnabled ? TelemetryTone.validate : TelemetryTone.human,
                  icon: Icons.grid_on_rounded,
                  onTap: widget.onToggleXray,
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onClose,
                  tooltip: 'Close',
                  style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _ReplayHeader(
              paused: c.replayPaused,
              canBack: c.canStepBack,
              canForward: c.canStepForward,
              onPause: widget.onPause,
              onRewind: widget.onRewind,
              onStepBack: widget.onStepBack,
              onStepForward: widget.onStepForward,
              onAutoReplay: widget.onAutoReplay,
              cursor: c.cursor,
              length: c.trajectory.length,
              onScrub: widget.onScrub,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.panelFill.withValues(alpha: 0.7),
                    border: Border.all(color: AppColors.panelStroke.withValues(alpha: 0.6), width: 1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: _TerminalLog(scroll: _scroll),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'events: ${c.events.length} • trajectory: ${c.trajectory.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry),
                  ),
                ),
                TextButton(
                  onPressed: widget.onClear,
                  style: TextButton.styleFrom(foregroundColor: AppColors.textPrimary),
                  child: const Text('clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayHeader extends StatelessWidget {
  final bool paused;
  final bool canBack;
  final bool canForward;
  final VoidCallback onPause;
  final VoidCallback onRewind;
  final VoidCallback onStepBack;
  final VoidCallback onStepForward;
  final VoidCallback onAutoReplay;
  final int cursor;
  final int length;
  final ValueChanged<int> onScrub;

  const _ReplayHeader({
    required this.paused,
    required this.canBack,
    required this.canForward,
    required this.onPause,
    required this.onRewind,
    required this.onStepBack,
    required this.onStepForward,
    required this.onAutoReplay,
    required this.cursor,
    required this.length,
    required this.onScrub,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final max = (length - 1).clamp(0, 999999);
    final value = cursor.clamp(0, max);

    Widget iconBtn({required IconData icon, required String tooltip, required VoidCallback onPressed, bool enabled = true}) {
      return IconButton(
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
        icon: Icon(icon, color: enabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
      );
    }

    return NeoPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Text('replay', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(width: AppSpacing.sm),
              TelemetryPill(label: paused ? 'paused' : 'live', tone: paused ? TelemetryTone.human : TelemetryTone.validate),
              const Spacer(),
              iconBtn(icon: Icons.fast_rewind_rounded, tooltip: 'Rewind to start', onPressed: onRewind),
              iconBtn(icon: Icons.skip_previous_rounded, tooltip: 'Step back', onPressed: onStepBack, enabled: canBack),
              iconBtn(icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded, tooltip: paused ? 'Unpause' : 'Pause', onPressed: onPause),
              iconBtn(icon: Icons.skip_next_rounded, tooltip: 'Step forward', onPressed: onStepForward, enabled: canForward),
              iconBtn(icon: Icons.movie_filter_rounded, tooltip: 'Auto replay', onPressed: onAutoReplay),
            ],
          ),
          Row(
            children: [
              Text('#$value', style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 0,
                    max: max.toDouble(),
                    onChanged: max == 0 ? null : (v) => onScrub(v.round()),
                    activeColor: AppColors.accentCyan,
                    inactiveColor: AppColors.panelStroke,
                  ),
                ),
              ),
              Text('max:$max', style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TerminalLog extends StatelessWidget {
  final ScrollController scroll;
  const _TerminalLog({required this.scroll});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final t = Theme.of(context);
    final events = c.events;

    return _TerminalLogList(scroll: scroll, events: events, textStyle: t.textTheme.bodySmall?.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.92), fontFamily: AppFonts.telemetry, height: 1.35));
  }
}

class _TerminalLogList extends StatefulWidget {
  final ScrollController scroll;
  final List<RuntimeEvent> events;
  final TextStyle? textStyle;
  const _TerminalLogList({required this.scroll, required this.events, required this.textStyle});

  @override
  State<_TerminalLogList> createState() => _TerminalLogListState();
}

class _TerminalLogListState extends State<_TerminalLogList> {
  bool _jumpScheduled = false;

  @override
  void didUpdateWidget(covariant _TerminalLogList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length != oldWidget.events.length) _scheduleJump();
  }

  void _scheduleJump() {
    if (_jumpScheduled) return;
    _jumpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpScheduled = false;
      if (!mounted || !widget.scroll.hasClients) return;
      try {
        final max = widget.scroll.position.maxScrollExtent;
        if (max.isFinite) widget.scroll.jumpTo(max);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we auto-scroll on first paint.
    _scheduleJump();

    return ListView.builder(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      itemCount: widget.events.length,
      itemBuilder: (context, i) {
        final e = widget.events[i];
        final line = e.toJsonLine();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: widget.textStyle,
          ),
        );
      },
    );
  }
}
