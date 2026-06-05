import 'dart:convert';

import 'package:portfoliox/core/state/app_actions.dart';
import 'package:portfoliox/core/state/app_state.dart';

class RuntimeEvent {
  final String id;
  final String type;
  final String channel;
  final Map<String, Object?> payload;
  final DateTime createdAt;

  const RuntimeEvent({required this.id, required this.type, required this.channel, required this.payload, required this.createdAt});

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type,
        'channel': channel,
        'ts': createdAt.toIso8601String(),
        'payload': payload,
      };

  String toJsonLine() => jsonEncode(toJson());
}

class TrajectoryStep {
  final int index;
  final AppAction action;
  final AppState state;
  final DateTime createdAt;
  final int latencyMicros;

  const TrajectoryStep({required this.index, required this.action, required this.state, required this.createdAt, required this.latencyMicros});

  TrajectoryStep copyWith({int? index}) => TrajectoryStep(
        index: index ?? this.index,
        action: action,
        state: state,
        createdAt: createdAt,
        latencyMicros: latencyMicros,
      );

  Map<String, Object?> toJson() => {
        'i': index,
        'action': action.runtimeType.toString(),
        'ts': createdAt.toIso8601String(),
        'latency_us': latencyMicros,
        'state': {
          'module': state.module.name,
          'mode': state.mode.name,
          'telemetryExpanded': state.telemetryExpanded,
          'telemetryDrawerOpen': state.telemetryDrawerOpen,
          'xrayEnabled': state.xrayEnabled,
          'focusedProjectId': state.focusedProjectId,
        },
      };
}
