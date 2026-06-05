import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:portfoliox/core/state/app_controller.dart';

/// Wrap any widget to expose its global bounding box into the X-Ray overlay.
class RuntimeProbe extends StatefulWidget {
  final String id;
  final Widget child;
  const RuntimeProbe({super.key, required this.id, required this.child});

  @override
  State<RuntimeProbe> createState() => _RuntimeProbeState();
}

class _RuntimeProbeState extends State<RuntimeProbe> {
  final _key = GlobalKey();
  Size? _lastSize;
  Offset? _lastOffset;
  bool _measureScheduled = false;
  int _lastExogenousLogMs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant RuntimeProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      _measure();
    });
  }

  void _measure() {
    if (!mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;

    Size size;
    Offset offset;
    try {
      size = ro.size;
      offset = ro.localToGlobal(Offset.zero);
    } catch (e) {
      // Can happen transiently during route transitions / overlay transforms.
      // In UIC terms this is an O_X (exogenous) host interference event.
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (mounted && nowMs - _lastExogenousLogMs > 800) {
        _lastExogenousLogMs = nowMs;
        try {
          context.read<AppController>().logInteraction(
            type: 'O_X_EXOGENOUS',
            payload: {
              'source': 'RuntimeProbe.measure',
              'probe': widget.id,
              'error': e.toString(),
            },
          );
        } catch (_) {
          // Best-effort only.
        }
      }
      return;
    }
    if (_lastSize == size && _lastOffset == offset) return;
    _lastSize = size;
    _lastOffset = offset;
    if (!mounted) return;
    context.read<AppController>().upsertProbeRect(widget.id, offset & size);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _scheduleMeasure();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
