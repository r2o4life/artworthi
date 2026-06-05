import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/models/portfolio_project.dart';
import 'package:portfoliox/core/repository/portfolio_repository.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';
import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/widgets/observability/fsm_diagram.dart';
import 'package:portfoliox/widgets/observability/runtime_probe.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  const ProjectDetailPage({super.key, required this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  PortfolioProject? _project;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = context.read<PortfolioRepository>();
      final p = await repo.getProjectById(widget.projectId);
      if (mounted) setState(() => _project = p);
    } catch (e) {
      // Logged at call sites in repositories; keep UI deterministic.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final xrayEnabled = context.select((AppController c) => c.state.xrayEnabled);

    return Scaffold(
      // Keep the detail blade fully deterministic and high-contrast.
      // Transparent scaffolds can reveal the browser's white canvas during route
      // transitions on web/desktop, which triggers contrast warnings.
      backgroundColor: AppColors.obsidian,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.cyberObsidian),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<AppController>().logInteraction(type: 'UI_TAP', payload: {'target': 'back_from_project', 'id': widget.projectId});
                        context.pop();
                      },
                      style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, overlayColor: Colors.transparent),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _project?.name ?? 'Project',
                        style: t.textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const TelemetryPill(label: 'detail blade', tone: TelemetryTone.active),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: RuntimeProbe(
                    id: 'project_detail/${widget.projectId}',
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _loading
                          ? NeoPanel(
                              padding: AppSpacing.paddingLg,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    'Loading case study…',
                                    style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry),
                                  ),
                                ],
                              ),
                            )
                          : _project == null
                              ? NeoPanel(
                                  padding: AppSpacing.paddingLg,
                                  child: Text(
                                    'No project found for id: ${widget.projectId}',
                                    style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                  ),
                                )
                              : _ProjectDetail(project: _project!, xrayEnabled: xrayEnabled),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  final PortfolioProject project;
  final bool xrayEnabled;
  const _ProjectDetail({required this.project, required this.xrayEnabled});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;
        final left = _DetailLeftPanel(project: project, xrayEnabled: xrayEnabled);
        final right = _DetailRightPanel(project: project, scrollInternally: !isNarrow);

        if (isNarrow) {
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: AppSpacing.lg),
                right,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: left),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 5, child: right),
          ],
        );
      },
    );
  }
}

class _DetailLeftPanel extends StatelessWidget {
  final PortfolioProject project;
  final bool xrayEnabled;
  const _DetailLeftPanel({required this.project, required this.xrayEnabled});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: xrayEnabled
            ? SizedBox(
                key: const ValueKey('fsm'),
                height: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TelemetryPill(label: 'FSM DIAGRAM', tone: TelemetryTone.validate, icon: Icons.account_tree_rounded),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('inputs → primitives → constraints → outputs', style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontFamily: AppFonts.telemetry), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(child: RuntimeProbe(id: 'fsm/${project.id}', child: FsmDiagram(projectId: project.id))),
                  ],
                ),
              )
            : SingleChildScrollView(
                key: const ValueKey('detail'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.tagline, style: t.textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary, height: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Text(project.domain, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: project.primitives.map((p) => TelemetryPill(label: p, tone: TelemetryTone.validate)).toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...project.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.circle, size: 6, color: AppColors.accentCyan)),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text(b, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.5))),
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

class _DetailRightPanel extends StatelessWidget {
  final PortfolioProject project;
  final bool scrollInternally;
  const _DetailRightPanel({required this.project, required this.scrollInternally});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SDLC timeline', style: t.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          if (scrollInternally)
            Expanded(
              child: ListView.builder(
                itemCount: project.milestones.length,
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.only(bottom: i == project.milestones.length - 1 ? 0 : AppSpacing.md),
                  child: _MilestoneTile(milestone: project.milestones[i]),
                ),
              ),
            )
          else
            ...project.milestones.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _MilestoneTile(milestone: m),
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final ProjectMilestone milestone;
  const _MilestoneTile({required this.milestone});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tone = switch (milestone.phase) {
      'Discovery' => TelemetryTone.human,
      'Design' => TelemetryTone.active,
      'Build' => TelemetryTone.validate,
      'Ship' => TelemetryTone.validate,
      _ => TelemetryTone.active,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            TelemetryPill(label: 'W${milestone.week}', tone: tone),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${milestone.phase} • ${milestone.title}', style: t.textTheme.titleSmall?.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(milestone.description, style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
