import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/state/app_actions.dart';
import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/core/state/app_state.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/dashboard_scaffold.dart';
import 'package:portfoliox/widgets/modules/framework_lab_module.dart';
import 'package:portfoliox/widgets/modules/manifesto_module.dart';
import 'package:portfoliox/widgets/modules/proven_matrix_module.dart';
import 'package:portfoliox/widgets/modules/systemic_synthesis_module.dart';
import 'package:portfoliox/widgets/observability/runtime_probe.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final s = controller.state;

    Widget child = switch (s.module) {
      PortfolioModule.manifesto => const ManifestoModule(),
      PortfolioModule.frameworkLab => const FrameworkLabModule(),
      PortfolioModule.provenMatrix => const ProvenMatrixModule(),
      PortfolioModule.systemicSynthesis => const SystemicSynthesisModule(),
    };

    child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) {
        final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.01, 0.02), end: Offset.zero).animate(fade),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(s.module), child: child),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.cyberObsidian),
        child: SafeArea(
          child: RuntimeProbe(
            id: 'home/dashboard_scaffold',
            child: DashboardScaffold(
              module: s.module,
              mode: s.mode,
              telemetryExpanded: s.telemetryExpanded,
              xrayEnabled: s.xrayEnabled,
              onModuleSelected: (m) {
                controller.logInteraction(type: 'UI_NAV', payload: {'target': 'module', 'value': m.name});
                controller.dispatch(SelectModule(m));
              },
              onToggleMode: () {
                controller.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'presentation_mode'});
                controller.dispatch(const TogglePresentationMode());
              },
              onTelemetryExpandedChanged: (v) {
                controller.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'telemetry_expanded', 'value': v});
                controller.dispatch(SetTelemetryExpanded(v));
              },
              onToggleXray: () {
                controller.logInteraction(type: 'UI_TOGGLE', payload: {'target': 'xray', 'enabled': !s.xrayEnabled});
                controller.dispatch(const ToggleXRay());
              },
              child: RuntimeProbe(id: 'home/module_${s.module.name}', child: child),
            ),
          ),
        ),
      ),
    );
  }
}
