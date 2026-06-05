import 'package:portfoliox/core/state/app_state.dart';

sealed class AppAction {
  const AppAction();
}

/// Internal action used to seed deterministic trajectory history.
class InitAction extends AppAction {
  const InitAction();
}

class SelectModule extends AppAction {
  final PortfolioModule module;
  const SelectModule(this.module);
}

class TogglePresentationMode extends AppAction {
  const TogglePresentationMode();
}

class SetTelemetryExpanded extends AppAction {
  final bool expanded;
  const SetTelemetryExpanded(this.expanded);
}

class FocusProject extends AppAction {
  final String? projectId;
  const FocusProject(this.projectId);
}

class ToggleTelemetryDrawer extends AppAction {
  const ToggleTelemetryDrawer();
}

class SetTelemetryDrawerOpen extends AppAction {
  final bool open;
  const SetTelemetryDrawerOpen(this.open);
}

class ToggleXRay extends AppAction {
  const ToggleXRay();
}

class SetXRayEnabled extends AppAction {
  final bool enabled;
  const SetXRayEnabled(this.enabled);
}
