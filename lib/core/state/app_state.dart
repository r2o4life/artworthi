enum PortfolioModule { manifesto, frameworkLab, provenMatrix, systemicSynthesis }

enum PresentationMode { editorial, systems }

class AppState {
  final PortfolioModule module;
  final PresentationMode mode;
  final bool telemetryExpanded;
  final bool telemetryDrawerOpen;
  final bool xrayEnabled;
  final String? focusedProjectId;

  const AppState({
    required this.module,
    required this.mode,
    required this.telemetryExpanded,
    required this.telemetryDrawerOpen,
    required this.xrayEnabled,
    required this.focusedProjectId,
  });

  const AppState.initial()
      : module = PortfolioModule.manifesto,
        mode = PresentationMode.editorial,
        telemetryExpanded = true,
        telemetryDrawerOpen = false,
        xrayEnabled = false,
        focusedProjectId = null;

  AppState copyWith({
    PortfolioModule? module,
    PresentationMode? mode,
    bool? telemetryExpanded,
    bool? telemetryDrawerOpen,
    bool? xrayEnabled,
    String? focusedProjectId,
  }) => AppState(
    module: module ?? this.module,
    mode: mode ?? this.mode,
    telemetryExpanded: telemetryExpanded ?? this.telemetryExpanded,
    telemetryDrawerOpen: telemetryDrawerOpen ?? this.telemetryDrawerOpen,
    xrayEnabled: xrayEnabled ?? this.xrayEnabled,
    focusedProjectId: focusedProjectId,
  );
}
