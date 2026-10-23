import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomSvgDivider extends StatelessWidget {
  const CustomSvgDivider({super.key, required this.image});
  final String image;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: SvgPicture.asset(image, fit: BoxFit.fitWidth),
      );
}
