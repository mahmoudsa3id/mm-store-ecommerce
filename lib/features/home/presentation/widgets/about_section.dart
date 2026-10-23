import 'package:flutter/material.dart';
import '../../domain/entities/home_entity.dart';
import '../../../../core/constants/app_constants.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.about});
  final AboutEntity about;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.horizontalPadding,
      vertical: 10,
    ),
    child: Container(
      decoration: BoxDecoration(
        color: AppConstants.black,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: Image.network(
              about.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: AppConstants.black),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  about.title,
                  style: const TextStyle(
                    color: AppConstants.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  about.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
