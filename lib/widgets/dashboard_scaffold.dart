import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:portfoliox/nav.dart';
import 'package:portfoliox/core/models/framework_metric.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/core/models/system_log.dart';
import 'package:portfoliox/core/state/app_controller.dart';
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
    final scrollPadding = isTablet ? (isDesktop ? AppSpacing.paddingXl : AppSpacing.paddingLg) : const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0);

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
          Expanded(child: _DashboardScrollable(padding: scrollPadding, child: child)),
          _BottomNav(module: module, onSelected: onModuleSelected),
        ],
      );
    }

    return Row(
      children: [
        RuntimeProbe(
          id: 'chrome/left_nav',
          child: _LeftNavRail(
            module: module,
            mode: mode,
            xrayEnabled: xrayEnabled,
            onSelected: onModuleSelected,
            onToggleMode: onToggleMode,
            onToggleXray: onToggleXray,
          ),
        ),
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
                child: _DashboardScrollable(padding: scrollPadding, child: child),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardScrollable extends StatefulWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;
  const _DashboardScrollable({required this.padding, required this.child});

  @override
  State<_DashboardScrollable> createState() => _DashboardScrollableState();
}

class _DashboardScrollableState extends State<_DashboardScrollable> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final thumb = w >= 980;

    return Scrollbar(
      controller: _controller,
      thumbVisibility: thumb,
      child: SingleChildScrollView(
        controller: _controller,
        padding: widget.padding,
        physics: const BouncingScrollPhysics(),
        child: widget.child,
      ),
    );
  }
}

class _LeftNavRail extends StatelessWidget {
  final PortfolioModule module;
  final PresentationMode mode;
  final bool xrayEnabled;
  final ValueChanged<PortfolioModule> onSelected;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleXray;
  const _LeftNavRail({
    required this.module,
    required this.mode,
    required this.xrayEnabled,
    required this.onSelected,
    required this.onToggleMode,
    required this.onToggleXray,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final profile = context.watch<SystemsProfile>();
    return SizedBox(
      width: 104,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
        child: NeoPanel(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              _HomeIngressMark(
                style: t.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary, letterSpacing: 2),
              ),
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
              const SizedBox(height: AppSpacing.md),
              _UtilityCluster(
                mode: mode,
                xrayEnabled: xrayEnabled,
                email: profile.contactAndSocials.email,
                digitalHq: profile.contactAndSocials.digitalHq,
                onToggleMode: onToggleMode,
                onToggleXray: onToggleXray,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 84),
                    child: const TelemetryPill(label: 'deterministic', tone: TelemetryTone.validate),
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

class _HomeIngressMark extends StatefulWidget {
  final TextStyle? style;
  const _HomeIngressMark({this.style});

  @override
  State<_HomeIngressMark> createState() => _HomeIngressMarkState();
}

class _HomeIngressMarkState extends State<_HomeIngressMark> {
  bool _hovering = false;

  bool _supportsHoverByPlatform() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final supportsHover = _supportsHoverByPlatform();

    final labelStyle = (widget.style ?? t.textTheme.titleMedium)?.copyWith(fontFamily: AppFonts.telemetry);
    final homeTextStyle = t.textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      fontFamily: AppFonts.telemetry,
      letterSpacing: 1.2,
    );

    void goHome() {
      context.read<AppController>().logInteraction(type: 'INGRESS', channel: 'chrome', payload: {'target': 'home'});
      context.go(AppRoutes.home);
    }

    final button = InkWell(
      onTap: goHome,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: supportsHover ? const EdgeInsets.all(12) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _hovering ? AppColors.panelFillStrong : Colors.transparent,
          borderRadius: BorderRadius.circular(supportsHover ? 16 : 999),
          border: Border.all(
            color: _hovering ? AppColors.accentCyan.withValues(alpha: 0.45) : AppColors.panelStroke,
            width: 1,
          ),
        ),
        child: supportsHover
            ? Text('A', style: labelStyle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('home', style: homeTextStyle),
                  const SizedBox(width: 8),
                  Icon(Icons.north_west_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
      ),
    );

    if (!supportsHover) return button;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          button,
          Positioned(
            left: 58,
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                opacity: _hovering ? 1 : 0,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  offset: _hovering ? Offset.zero : const Offset(-0.06, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.panelFillStrong.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.30), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentCyan.withValues(alpha: 0.10),
                          blurRadius: 18,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home_rounded, size: 14, color: AppColors.accentCyan),
                          const SizedBox(width: 8),
                          Text('home', style: t.textTheme.labelSmall?.copyWith(color: AppColors.textPrimary, fontFamily: AppFonts.telemetry, letterSpacing: 0.6)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UtilityCluster extends StatelessWidget {
  final PresentationMode mode;
  final bool xrayEnabled;
  final String email;
  final String digitalHq;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleXray;

  const _UtilityCluster({
    required this.mode,
    required this.xrayEnabled,
    required this.email,
    required this.digitalHq,
    required this.onToggleMode,
    required this.onToggleXray,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _UtilityIcon(
            icon: mode == PresentationMode.editorial ? Icons.subject_rounded : Icons.layers_rounded,
            label: mode == PresentationMode.editorial ? 'Editorial' : 'Systems',
            selected: true,
            onTap: () {
              context.read<AppController>().logInteraction(
                type: 'UTILITY_TOGGLE',
                channel: 'chrome',
                payload: {'kind': 'mode', 'next': mode == PresentationMode.editorial ? 'systems' : 'editorial'},
              );
              onToggleMode();
            },
          ),
          _XrayUtilityIcon(
            enabled: xrayEnabled,
            onToggle: () {
              context.read<AppController>().logInteraction(
                type: 'UTILITY_TOGGLE',
                channel: 'chrome',
                payload: {'kind': 'xray', 'next': (!xrayEnabled).toString()},
              );
              onToggleXray();
            },
          ),
          _UtilityIcon(
            icon: Icons.public_rounded,
            label: 'HQ',
            onTap: () => _launchEgress(
              context,
              label: 'digital_hq',
              kind: 'url',
              uri: Uri.parse(digitalHq),
            ),
          ),
          _UtilityIcon(
            icon: Icons.mail_rounded,
            label: 'Email',
            onTap: () => _launchEgress(
              context,
              label: 'email',
              kind: 'mailto',
              uri: Uri(scheme: 'mailto', path: email),
            ),
            onLongPress: () async {
              try {
                await Clipboard.setData(ClipboardData(text: email));
                context.read<AppController>().logInteraction(
                  type: 'UTILITY_COPY',
                  channel: 'chrome',
                  payload: {'kind': 'email', 'value': email},
                );
              } catch (e) {
                debugPrint('Failed to copy email: $e');
                context.read<AppController>().logInteraction(
                  type: 'UTILITY_COPY_ERROR',
                  channel: 'chrome',
                  payload: {'kind': 'email', 'error': e.toString()},
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _launchEgress(BuildContext context, {required String label, required String kind, required Uri uri}) async {
    context.read<AppController>().logInteraction(
      type: 'EGRESS',
      channel: 'egress',
      payload: {'kind': kind, 'label': label, 'uri': uri.toString()},
    );

    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        context.read<AppController>().logInteraction(
          type: 'EGRESS_FAILED',
          channel: 'egress',
          payload: {'label': label, 'uri': uri.toString()},
        );
      }
    } catch (e) {
      debugPrint('Failed to launch egress link ($label): $e');
      context.read<AppController>().logInteraction(
        type: 'EGRESS_ERROR',
        channel: 'egress',
        payload: {'label': label, 'uri': uri.toString(), 'error': e.toString()},
      );
    }
  }
}

class _UtilityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _UtilityIcon({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = selected ? AppColors.accentCyan : AppColors.textSecondary;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.panelFillStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accentCyan.withValues(alpha: 0.35) : AppColors.panelStroke, width: 1),
          ),
          child: Icon(icon, color: color, size: 18, semanticLabel: label),
        ),
      ),
    );
  }
}

class _XrayUtilityIcon extends StatefulWidget {
  final bool enabled;
  final VoidCallback onToggle;
  const _XrayUtilityIcon({required this.enabled, required this.onToggle});

  @override
  State<_XrayUtilityIcon> createState() => _XrayUtilityIconState();
}

class _XrayUtilityIconState extends State<_XrayUtilityIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _XrayUtilityIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.enabled) {
      if (_pulse.isAnimating) return;
      _pulse
        ..stop()
        ..value = 0;
      // Perpetual “XRAY active” render loop: visible even in dense UI.
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            if (!enabled) return child!;

            // NOTE: The old implementation relied heavily on *outer* glow (shadows)
            // which can get visually lost (or clipped) inside dense panels.
            // This version pushes the signal *into* the button (animated fill +
            // border) while still retaining the dashed ring.
            final t = Curves.easeInOutCubic.transform(_pulse.value);
            final ringAlpha = (0.55 + (t * 0.35)).clamp(0.0, 1.0);
            final borderAlpha = (0.55 + (t * 0.40)).clamp(0.0, 1.0);
            final fillAlpha = (0.08 + (t * 0.10)).clamp(0.0, 1.0);
            final borderWidth = 1.3 + (t * 1.0);

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1 + (t * 0.06),
                  child: CustomPaint(
                    painter: _DashedRingPainter(
                      color: AppColors.accentCyan.withValues(alpha: ringAlpha),
                      rotationT: t,
                    ),
                    child: const SizedBox(width: 52, height: 52),
                  ),
                ),
                _XrayActiveButton(
                  t: t,
                  borderAlpha: borderAlpha,
                  fillAlpha: fillAlpha,
                  borderWidth: borderWidth,
                  onTap: widget.onToggle,
                ),
              ],
            );
          },
          child: _UtilityIcon(
            icon: Icons.grid_on_rounded,
            label: enabled ? 'XRAY on' : 'XRAY off',
            selected: enabled,
            onTap: widget.onToggle,
          ),
        ),
        Positioned(
          left: -26,
          right: -26,
          top: -34,
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = Curves.easeInOutCubic.transform(_pulse.value);
                final y = enabled ? (0.0 - (t * 2.5)) : 6.0;
                final opacity = enabled ? (0.78 + (t * 0.22)) : 0.0;
                return Transform.translate(
                  offset: Offset(0, y),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    opacity: opacity,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.panelFillStrong.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.40 + (t * 0.20)), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentCyan.withValues(alpha: 0.14 + (t * 0.08)),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.accentCyan.withValues(alpha: 0.75 + (t * 0.25)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'XRAY active • tap to exit',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontFamily: AppFonts.telemetry,
                                      letterSpacing: 0.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _XrayActiveButton extends StatelessWidget {
  final double t;
  final double borderAlpha;
  final double fillAlpha;
  final double borderWidth;
  final VoidCallback onTap;

  const _XrayActiveButton({
    required this.t,
    required this.borderAlpha,
    required this.fillAlpha,
    required this.borderWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fill = AppColors.accentCyan.withValues(alpha: fillAlpha);
    final border = AppColors.accentCyan.withValues(alpha: borderAlpha);
    final iconColor = Color.lerp(AppColors.textPrimary, AppColors.accentCyan, 0.55 + (t * 0.25))!;

    return Tooltip(
      message: 'XRAY',
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.panelFillStrong, fill, 0.9)!,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: borderWidth),
            boxShadow: [
              // Keep the glow mostly *inside* the button silhouette.
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.18 + (t * 0.18)),
                blurRadius: 10 + (t * 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(Icons.grid_on_rounded, color: iconColor, size: 18, semanticLabel: 'XRAY on'),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double rotationT;
  const _DashedRingPainter({required this.color, required this.rotationT});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color;

    // Draw a dashed circle with a gentle rotation to read as “live”.
    const dashCount = 20;
    final dashAngle = (2 * 3.141592653589793) / dashCount;
    final gap = dashAngle * 0.45;
    final sweep = dashAngle - gap;
    final rotation = rotationT * (2 * 3.141592653589793);

    for (var i = 0; i < dashCount; i++) {
      final start = rotation + (i * dashAngle);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => oldDelegate.color != color || oldDelegate.rotationT != rotationT;
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
                  _XrayTelemetryPill(enabled: xrayEnabled, onTap: onToggleXray),
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

class _XrayTelemetryPill extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _XrayTelemetryPill({required this.enabled, required this.onTap});

  @override
  State<_XrayTelemetryPill> createState() => _XrayTelemetryPillState();
}

class _XrayTelemetryPillState extends State<_XrayTelemetryPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 980));
    _sync();
  }

  @override
  void didUpdateWidget(covariant _XrayTelemetryPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  void _sync() {
    if (widget.enabled) {
      if (!_c.isAnimating) {
        _c
          ..stop()
          ..value = 0
          ..repeat(reverse: true);
      }
    } else {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final strokeAlpha = widget.enabled ? (0.55 + (t * 0.35)).clamp(0.0, 1.0) : 0.0;
        final glowAlpha = widget.enabled ? (0.18 + (t * 0.12)).clamp(0.0, 1.0) : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: glowAlpha),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              if (widget.enabled)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.accentCyan.withValues(alpha: strokeAlpha), width: 1.2 + (t * 0.8)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      child: TelemetryPill(
        label: widget.enabled ? 'x-ray on' : 'x-ray off',
        tone: widget.enabled ? TelemetryTone.validate : TelemetryTone.human,
        icon: Icons.grid_on_rounded,
        onTap: widget.onTap,
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
