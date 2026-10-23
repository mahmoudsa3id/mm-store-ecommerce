import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PremiumLottie extends StatelessWidget {
  const PremiumLottie({
    super.key,
    required this.asset,
    this.width = 160,
    this.height = 160,
    this.repeat = true,
  });

  final String asset;
  final double width;
  final double height;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        asset,
        repeat: repeat,
        animate: true,
        fit: BoxFit.contain,
        renderCache: RenderCache.drawingCommands,
      ),
    );
  }
}
