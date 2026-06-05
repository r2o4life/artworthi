import 'dart:convert';
import 'dart:ui';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:portfoliox/core/observability/perf_metrics.dart';
import 'package:portfoliox/core/observability/runtime_event.dart';
import 'package:portfoliox/core/state/app_actions.dart';
import 'package:portfoliox/core/state/app_state.dart';
import 'package:portfoliox/core/models/systems_profile.dart';

class AppController extends ChangeNotifier {
  AppState _state;
  AppState get state => _state;

  final List<RuntimeEvent> _events = <RuntimeEvent>[];
  List<RuntimeEvent> get events => List.unmodifiable(_events);

  final Map<String, Rect> _probes = <String, Rect>{};
  Map<String, Rect> get probes => Map.unmodifiable(_probes);

  PerfMetrics _perf = const PerfMetrics.empty();
  PerfMetrics get perf => _perf;

  final List<TrajectoryStep> _trajectory = <TrajectoryStep>[];
  List<TrajectoryStep> get trajectory => List.unmodifiable(_trajectory);

  int _cursor = -1;
  int get cursor => _cursor;

  bool _replayPaused = false;
  bool get replayPaused => _replayPaused;

  bool get canStepBack => _cursor > 0;
  bool get canStepForward => _cursor >= 0 && _cursor < _trajectory.length - 1;

  final SystemsProfile? profile;

  AppController({AppState initial = const AppState.initial(), this.profile}) : _state = initial {
    // Seed trajectory with initial state so replay always has a baseline.
    _appendTrajectory(action: const InitAction(), state: initial, latencyMicros: 0);

    final p = profile;
    if (p != null) {
      _appendEvent(
        RuntimeEvent(
          id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
          type: 'PROFILE_HYDRATE',
          channel: 'profile',
          payload: {
            'name': p.identity.name,
            'title': p.identity.professionalTitle,
            'years': p.identity.yearsOfExperience,
            'location': p.identity.currentLocation,
            'studio': p.corporateEntities.designStudio,
            'studio_url': p.corporateEntities.designStudioUrl,
            'entity': p.corporateEntities.parentEntity,
            'holding': p.corporateEntities.holdingCompany,
            'hq': p.contactAndSocials.digitalHq,
            'linkedin': p.contactAndSocials.linkedin,
          },
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void dispatch(AppAction action) {
    final sw = Stopwatch()..start();
    final next = _reduce(_state, action);
    sw.stop();
    if (identical(next, _state)) return;

    _state = next;
    _appendTrajectory(action: action, state: next, latencyMicros: sw.elapsedMicroseconds);
    _appendEvent(
      RuntimeEvent(
        id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
        type: 'STATE_CHANGE',
        channel: 'reducer',
        payload: {
          'action': action.runtimeType.toString(),
          'latency_us': sw.elapsedMicroseconds,
          'state': {
            'module': next.module.name,
            'mode': next.mode.name,
            'telemetryExpanded': next.telemetryExpanded,
            'telemetryDrawerOpen': next.telemetryDrawerOpen,
            'xrayEnabled': next.xrayEnabled,
            'focusedProjectId': next.focusedProjectId,
          },
        },
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void logInteraction({required String type, required Map<String, Object?> payload, String channel = 'runtime'}) {
    _appendEvent(RuntimeEvent(
      id: 'evt_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      channel: channel,
      payload: payload,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void _appendEvent(RuntimeEvent e) {
    _events.add(e);
    if (_events.length > 400) _events.removeRange(0, _events.length - 400);
    debugPrint(const JsonEncoder.withIndent(null).convert(e.toJson()));
  }

  void clearRuntimeLog() {
    _events.clear();
    notifyListeners();
  }

  void upsertProbeRect(String id, Rect rect) {
    _probes[id] = rect;
    notifyListeners();
  }

  void setPerf(PerfMetrics metrics) {
    _perf = metrics;
    notifyListeners();
  }

  void setReplayPaused(bool paused) {
    _replayPaused = paused;
    notifyListeners();
  }

  void stepBack() {
    if (!canStepBack) return;
    _cursor -= 1;
    _state = _trajectory[_cursor].state;
    notifyListeners();
  }

  void stepForward() {
    if (!canStepForward) return;
    _cursor += 1;
    _state = _trajectory[_cursor].state;
    notifyListeners();
  }

  void rewindToStart() {
    if (_trajectory.isEmpty) return;
    _cursor = 0;
    _state = _trajectory[_cursor].state;
    notifyListeners();
  }

  void jumpTo(int index) {
    if (_trajectory.isEmpty) return;
    final clamped = index.clamp(0, _trajectory.length - 1);
    _cursor = clamped;
    _state = _trajectory[_cursor].state;
    notifyListeners();
  }

  void _appendTrajectory({required AppAction action, required AppState state, required int latencyMicros}) {
    // If we time-travelled, then took a new action, truncate the future.
    if (_cursor >= 0 && _cursor < _trajectory.length - 1) {
      _trajectory.removeRange(_cursor + 1, _trajectory.length);
    }

    _trajectory.add(
      TrajectoryStep(
        index: _trajectory.length,
        action: action,
        state: state,
        createdAt: DateTime.now(),
        latencyMicros: latencyMicros,
      ),
    );

    if (_trajectory.length > 260) {
      final overflow = _trajectory.length - 260;
      _trajectory.removeRange(0, overflow);
      for (var i = 0; i < _trajectory.length; i++) {
        _trajectory[i] = _trajectory[i].copyWith(index: i);
      }
      _cursor = (_cursor - overflow).clamp(-1, _trajectory.length - 1);
    }

    _cursor = _trajectory.length - 1;
  }

  AppState _reduce(AppState s, AppAction a) {
    return switch (a) {
      SelectModule(:final module) => s.copyWith(module: module, focusedProjectId: null),
      TogglePresentationMode() => s.copyWith(
          mode: s.mode == PresentationMode.editorial ? PresentationMode.systems : PresentationMode.editorial,
        ),
      SetTelemetryExpanded(:final expanded) => s.copyWith(telemetryExpanded: expanded),
      FocusProject(:final projectId) => s.copyWith(focusedProjectId: projectId),
      ToggleTelemetryDrawer() => s.copyWith(telemetryDrawerOpen: !s.telemetryDrawerOpen),
      SetTelemetryDrawerOpen(:final open) => s.copyWith(telemetryDrawerOpen: open),
      ToggleXRay() => s.copyWith(xrayEnabled: !s.xrayEnabled),
      SetXRayEnabled(:final enabled) => s.copyWith(xrayEnabled: enabled),
      _ => s,
    };
  }
}
