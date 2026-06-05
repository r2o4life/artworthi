import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/models/portfolio_project.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/nav.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';
import 'package:portfoliox/widgets/observability/runtime_probe.dart';
import 'package:portfoliox/core/state/app_controller.dart';

class ProvenMatrixModule extends StatelessWidget {
  const ProvenMatrixModule({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final projects = context.watch<List<PortfolioProject>>();
    final profile = context.watch<SystemsProfile>();
    final w = MediaQuery.sizeOf(context).width;
    final cols = w >= 1100 ? 2 : 1;
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
                TelemetryPill(label: 'PROVEN MATRIX', tone: TelemetryTone.active, icon: Icons.grid_view_rounded),
                TelemetryPill(label: 'shipped systems', tone: TelemetryTone.validate),
                TelemetryPill(label: 'detail blades', tone: TelemetryTone.human),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Proven Matrix • ${profile.identity.name}', style: t.textTheme.headlineLarge?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Shipped systems + portfolio artifacts. Each card opens a blade with architecture breakdowns, SDLC timelines, and state maps.',
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.55),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (cols == 1)
              Column(
                children: [
                  for (var i = 0; i < projects.length; i++) ...[
                    _ProjectCard(project: projects[i], compact: isNarrow),
                    if (i != projects.length - 1) const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              )
            else
              GridView.builder(
                itemCount: projects.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.lg,
                  mainAxisSpacing: AppSpacing.lg,
                  childAspectRatio: 1.65,
                ),
                itemBuilder: (context, i) => _ProjectCard(project: projects[i], compact: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final PortfolioProject project;
  final bool compact;
  const _ProjectCard({required this.project, required this.compact});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final controller = context.read<AppController>();
    return RuntimeProbe(
      id: 'project_card/${project.id}',
      child: MouseRegion(
        onEnter: (_) => controller.logInteraction(type: 'UI_HOVER', payload: {'target': 'project_card', 'id': project.id}),
        child: InkWell(
          onTap: () {
            controller.logInteraction(type: 'UI_TAP', payload: {'target': 'open_project', 'id': project.id});
            context.push(AppRoutes.project.replaceFirst(':id', project.id));
          },
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: NeoPanel(
              padding: AppSpacing.paddingLg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(project.name, style: t.textTheme.titleLarge?.copyWith(color: AppColors.textPrimary)),
                      ),
                      const Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(project.tagline, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: project.primitives
                        .take(4)
                        .map((p) => TelemetryPill(label: p, tone: TelemetryTone.validate))
                        .toList(growable: false),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (!compact) const TelemetryPill(label: 'state machine', tone: TelemetryTone.active),
                      if (!compact) const SizedBox(width: AppSpacing.sm),
                      TelemetryPill(label: project.domain.split('/').first.trim().toLowerCase(), tone: TelemetryTone.human),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
