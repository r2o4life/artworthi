import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:portfoliox/core/state/app_controller.dart';
import 'package:portfoliox/core/state/app_state.dart';
import 'package:portfoliox/core/models/systems_profile.dart';
import 'package:portfoliox/theme.dart';
import 'package:portfoliox/widgets/neo/neo_panel.dart';
import 'package:portfoliox/widgets/neo/telemetry_pill.dart';

class ManifestoModule extends StatelessWidget {
  const ManifestoModule({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SystemsProfile>();
    final mode = context.select((AppController c) => c.state.mode);
    final t = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= 980;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: isWide ? 7 : 10,
              child: NeoPanel(
                padding: isWide ? AppSpacing.paddingXl : AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: const [
                        TelemetryPill(label: 'CORE MANIFESTO', tone: TelemetryTone.active, icon: Icons.blur_on_rounded),
                        TelemetryPill(label: 'positioning engine', tone: TelemetryTone.validate),
                        TelemetryPill(label: 'blackbox → light', tone: TelemetryTone.human),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${profile.identity.name} • ${profile.identity.professionalTitle}',
                      style: t.textTheme.displaySmall?.copyWith(color: AppColors.textPrimary, height: 1.02, letterSpacing: -0.8),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '"${profile.identity.corePhilosophy}"',
                      style: t.textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary, height: 1.55),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${profile.identity.yearsOfExperience}+ years • ${profile.identity.currentLocation}',
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: mode == PresentationMode.editorial
                          ? _EditorialFooter(key: const ValueKey('editorial'))
                          : const _SystemsOverlay(key: ValueKey('systems')),
                    ),
                  ],
                ),
              ),
            ),
            if (isWide) ...[
              const SizedBox(width: AppSpacing.lg),
              const Expanded(flex: 3, child: _SideTelemetry()),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditorialFooter extends StatelessWidget {
  const _EditorialFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Editorial view: craft-first narrative with deliberate signals.',
          style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: const [
            TelemetryPill(label: 'systems-ready', tone: TelemetryTone.active),
            TelemetryPill(label: 'human trust', tone: TelemetryTone.human),
            TelemetryPill(label: 'deterministic UX', tone: TelemetryTone.validate),
          ],
        ),
      ],
    );
  }
}

class _SystemsOverlay extends StatelessWidget {
  const _SystemsOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Systems architecture view', style: t.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The prose above resolves into deterministic layers: inputs → primitives → constraints → outputs. '
            'Every UI transition is a reducible state delta.',
            style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.55),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              TelemetryPill(label: 'inputs', tone: TelemetryTone.human, icon: Icons.keyboard_alt_outlined),
              TelemetryPill(label: 'reducers', tone: TelemetryTone.active, icon: Icons.tune_rounded),
              TelemetryPill(label: 'invariants', tone: TelemetryTone.validate, icon: Icons.verified_rounded),
              TelemetryPill(label: 'streams', tone: TelemetryTone.active, icon: Icons.stream_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideTelemetry extends StatelessWidget {
  const _SideTelemetry();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SystemsProfile>();
    final t = Theme.of(context);
    return NeoPanel(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Landing matrix', style: t.textTheme.titleMedium?.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _KeyValue(label: 'studio', value: profile.corporateEntities.designStudio),
          _KeyValue(label: 'entity', value: profile.corporateEntities.parentEntity),
          _KeyValue(label: 'holding', value: profile.corporateEntities.holdingCompany),
          _KeyValue.link(
            label: 'email',
            value: profile.contactAndSocials.email,
            uri: Uri(scheme: 'mailto', path: profile.contactAndSocials.email),
            egressKind: 'mailto',
          ),
          _KeyValue.link(
            label: 'digital HQ',
            value: profile.contactAndSocials.digitalHq,
            uri: Uri.parse(profile.contactAndSocials.digitalHq),
            egressKind: 'url',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Toggle via telemetry bar →', style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final Uri? uri;
  final String? egressKind;

  const _KeyValue({required this.label, required this.value}) : uri = null, egressKind = null;

  const _KeyValue.link({required this.label, required this.value, required this.uri, required this.egressKind});

  Future<void> _onTap(BuildContext context) async {
    final link = uri;
    if (link == null) return;

    context.read<AppController>().logInteraction(
      type: 'EGRESS',
      channel: 'egress',
      payload: {'kind': egressKind, 'label': label, 'uri': link.toString()},
    );

    try {
      final ok = await launchUrl(link, mode: LaunchMode.externalApplication);
      if (!ok) {
        context.read<AppController>().logInteraction(
          type: 'EGRESS_FAILED',
          channel: 'egress',
          payload: {'label': label, 'uri': link.toString()},
        );
      }
    } catch (e) {
      debugPrint('Failed to launch egress link ($label): $e');
      context.read<AppController>().logInteraction(
        type: 'EGRESS_ERROR',
        channel: 'egress',
        payload: {'label': label, 'uri': link.toString(), 'error': e.toString()},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isLink = uri != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: t.textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.0)),
          ),
          Flexible(
            child: InkWell(
              onTap: isLink ? () => _onTap(context) : null,
              borderRadius: BorderRadius.circular(10),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.labelSmall?.copyWith(
                    color: isLink ? AppColors.accentCyan : AppColors.textPrimary,
                    fontFamily: AppFonts.telemetry,
                    decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                    decorationColor: isLink ? AppColors.accentCyan : null,
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
