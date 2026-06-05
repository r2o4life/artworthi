import 'package:flutter/material.dart';

import 'package:portfoliox/theme.dart';

class NeoPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const NeoPanel({super.key, required this.child, this.padding = AppSpacing.paddingMd});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelFill,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.panelStroke, width: 1),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
