import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobile = 2,
    this.tablet = 3,
    this.desktop = 5,
    this.spacing = 12,
    this.childAspectRatio = 1,
  });

  final List<Widget> children;
  final int mobile;
  final int tablet;
  final int desktop;
  final double spacing;
  final double childAspectRatio;

  int _columns(double width) {
    if (width >= 1100) return desktop;
    if (width >= 700) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns(constraints.maxWidth),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}
