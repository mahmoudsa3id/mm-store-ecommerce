import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class PremiumPanel extends StatefulWidget {
  const PremiumPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  State<PremiumPanel> createState() => _PremiumPanelState();
}

class _PremiumPanelState extends State<PremiumPanel> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        margin: widget.margin,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: AppConstants.surfaceGlass,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: hovered
                ? AppConstants.gold.withValues(alpha: .45)
                : AppConstants.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: hovered ? .38 : .24),
              blurRadius: hovered ? 32 : 20,
              offset: const Offset(0, 12),
            ),
            if (hovered) AppConstants.goldGlow,
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
