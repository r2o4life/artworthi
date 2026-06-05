import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/system_log.dart';
import 'package:portfoliox/core/state/app_state.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';
import 'package:portfoliox/widgets/neo/telemetry_sparkline.dart';
import 'package:portfoliox/widgets/observability/runtime_probe.dart';

class DashboardScaffold extends StatelessWidget {
  final PortfolioModule module;
  final PresentationMode mode;
  final bool telemetryExpanded;
  final bool xrayEnabled;
  final ValueChanged<PortfolioModule> onModuleSelected;
  final VoidCallback onToggleMode;
  final ValueChanged<bool> onTelemetryExpandedChanged;
  final VoidCallback onToggleXray;
  final Widget child;

  const DashboardScaffold({
    super.key,
    required this.module,
    required this.mode,
    required this.telemetryExpanded,
    required this.xrayEnabled,
    required this.onModuleSelected,
    required this.onToggleMode,
    required this.onTelemetryExpandedChanged,
    required this.onToggleXray,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 980;
    final isTablet = w >= 720;

    if (!isTablet) {
      return Column(
        children: [
          RuntimeProbe(
            id: 'chrome/telemetry_topbar',
            child: _TelemetryTopBar(
              expanded: telemetryExpanded,
              mode: mode,
              xrayEnabled: xrayEnabled,
              onToggleMode: onToggleMode,
              onToggleXray: onToggleXray,
              onExpandedChanged: onTelemetryExpandedChanged,
            ),
          ),
          Expanded(child: child),
          _BottomNav(module: module, onSelected: onModuleSelected),
        ],
      );
    }

    return Row(
      children: [
        RuntimeProbe(id: 'chrome/left_nav', child: _LeftNavRail(module: module, onSelected: onModuleSelected)),
        Expanded(
          child: Column(
            children: [
              RuntimeProbe(
                id: 'chrome/telemetry_topbar',
                child: _TelemetryTopBar(
                  expanded: telemetryExpanded,
                  mode: mode,
                  xrayEnabled: xrayEnabled,
                  onToggleMode: onToggleMode,
                  onToggleXray: onToggleXray,
                  onExpandedChanged: onTelemetryExpandedChanged,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: isDesktop ? AppSpacing.paddingXl : AppSpacing.paddingLg,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeftNavRail extends StatelessWidget {
  final PortfolioModule module;
  final ValueChanged<PortfolioModule> onSelected;
  const _LeftNavRail({required this.module, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return SizedBox(
      width: 104,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
        child: NeoPanel(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text('PX', style: t.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, letterSpacing: 2)),
              const SizedBox(height: AppSpacing.lg),
              _NavIcon(
                icon: Icons.blur_on_rounded,
                label: 'Core',
                selected: module == PortfolioModule.manifesto,
                onTap: () => onSelected(PortfolioModule.manifesto),
              ),
              _NavIcon(
                icon: Icons.hub_rounded,
                label: 'Lab',
                selected: module == PortfolioModule.frameworkLab,
                onTap: () => onSelected(PortfolioModule.frameworkLab),
              ),
              _NavIcon(
                icon: Icons.grid_view_rounded,
                label: 'Proof',
                selected: module == PortfolioModule.provenMatrix,
                onTap: () => onSelected(PortfolioModule.provenMatrix),
              ),
              _NavIcon(
                icon: Icons.account_tree_rounded,
                label: 'SDLC',
                selected: module == PortfolioModule.systemicSynthesis,
                onTap: () => onSelected(PortfolioModule.systemicSynthesis),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: TelemetryPill(label: 'deterministic', tone: TelemetryTone.validate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavIcon({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = selected ? AppColors.accentCyan : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.panelFillStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.accentCyan.withValues(alpha: 0.35) : AppColors.panelStroke,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label, style: t.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryTopBar extends StatelessWidget {
  final bool expanded;
  final PresentationMode mode;
  final bool xrayEnabled;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleXray;
  final ValueChanged<bool> onExpandedChanged;

  const _TelemetryTopBar({
    required this.expanded,
    required this.mode,
    required this.xrayEnabled,
    required this.onToggleMode,
    required this.onToggleXray,
    required this.onExpandedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<List<FrameworkMetric>>();
    final logs = context.watch<List<SystemLog>>();
    final t = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final isCompact = w < 720;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: NeoPanel(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: BoxConstraints(minHeight: expanded ? 120 : 56),
          child: Column(
            children: [
              Row(
                children: [
                  Text('telemetry', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.4)),
                  const SizedBox(width: AppSpacing.sm),
                  TelemetryPill(
                    label: mode == PresentationMode.editorial ? 'editorial view' : 'systems view',
                    tone: mode == PresentationMode.editorial ? TelemetryTone.human : TelemetryTone.active,
                    icon: mode == PresentationMode.editorial ? Icons.subject_rounded : Icons.layers_rounded,
                    onTap: onToggleMode,
                  ),
                    const SizedBox(width: AppSpacing.sm),
                    TelemetryPill(
                      label: xrayEnabled ? 'x-ray on' : 'x-ray off',
                      tone: xrayEnabled ? TelemetryTone.validate : TelemetryTone.human,
                      icon: Icons.grid_on_rounded,
                      onTap: onToggleXray,
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => onExpandedChanged(!expanded),
                    tooltip: expanded ? 'Collapse telemetry' : 'Expand telemetry',
                    style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
                    icon: Icon(
                      expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: isCompact
                      ? _TelemetryCompact(metrics: metrics, logs: logs)
                      : _TelemetryWide(metrics: metrics, logs: logs),
                ),
                secondChild: const SizedBox(height: 0, width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryWide extends StatelessWidget {
  final List<FrameworkMetric> metrics;
  final List<SystemLog> logs;
  const _TelemetryWide({required this.metrics, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: metrics
                .map(
                  (m) => TelemetrySparkline(
                    label: m.name,
                    value: m.value,
                    tone: _toneForMetric(m.id),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 5, child: _LogConsole(logs: logs)),
      ],
    );
  }
}

class _TelemetryCompact extends StatelessWidget {
  final List<FrameworkMetric> metrics;
  final List<SystemLog> logs;
  const _TelemetryCompact({required this.metrics, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: metrics
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: TelemetrySparkline(
                      label: m.name,
                      value: m.value,
                      tone: _toneForMetric(m.id),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _LogConsole(logs: logs),
      ],
    );
  }
}

class _LogConsole extends StatelessWidget {
  final List<SystemLog> logs;
  const _LogConsole({required this.logs});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return NeoPanel(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('console', style: t.textTheme.labelLarge?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.sm),
          ...logs.reversed.take(4).map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _renderLog(l),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodySmall?.copyWith(
                      color: _logColor(l.severity),
                      fontFamily: AppFonts.telemetry,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _renderLog(SystemLog l) {
    final ts = l.createdAt.toIso8601String().substring(11, 19);
    return '[$ts] ${l.message}';
  }

  Color _logColor(LogSeverity s) => switch (s) {
        LogSeverity.info => AppColors.textSecondary,
        LogSeverity.ok => AppColors.accentEmerald,
        LogSeverity.warn => AppColors.accentAmber,
        LogSeverity.err => AppColors.accentAmber,
      };
}

TelemetryTone _toneForMetric(String id) => switch (id) {
      'threshold' => TelemetryTone.validate,
      'magnitude' => TelemetryTone.active,
      'ratios' => TelemetryTone.human,
      _ => TelemetryTone.active,
    };

class _BottomNav extends StatelessWidget {
  final PortfolioModule module;
  final ValueChanged<PortfolioModule> onSelected;
  const _BottomNav({required this.module, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final idx = switch (module) {
      PortfolioModule.manifesto => 0,
      PortfolioModule.frameworkLab => 1,
      PortfolioModule.provenMatrix => 2,
      PortfolioModule.systemicSynthesis => 3,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: NeoPanel(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: idx,
          onDestinationSelected: (i) => onSelected(
            switch (i) {
              0 => PortfolioModule.manifesto,
              1 => PortfolioModule.frameworkLab,
              2 => PortfolioModule.provenMatrix,
              _ => PortfolioModule.systemicSynthesis,
            },
          ),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.blur_on_rounded, color: AppColors.textSecondary), selectedIcon: Icon(Icons.blur_on_rounded, color: AppColors.accentCyan), label: 'Core'),
            NavigationDestination(icon: Icon(Icons.hub_rounded, color: AppColors.textSecondary), selectedIcon: Icon(Icons.hub_rounded, color: AppColors.accentCyan), label: 'Lab'),
            NavigationDestination(icon: Icon(Icons.grid_view_rounded, color: AppColors.textSecondary), selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.accentCyan), label: 'Proof'),
            NavigationDestination(icon: Icon(Icons.account_tree_rounded, color: AppColors.textSecondary), selectedIcon: Icon(Icons.account_tree_rounded, color: AppColors.accentCyan), label: 'SDLC'),
          ],
        ),
      ),
    );
  }
}
