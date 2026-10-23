import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_route_names.dart';

class HomeSearch extends StatelessWidget {
  const HomeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: () => context.pushNamed(AppRouteNames.search),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppConstants.surfaceElevated,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppConstants.border),
            boxShadow: const [AppConstants.shadow],
          ),
          child: const Row(
            children: [
              SizedBox(width: 14),
              Icon(Icons.search_rounded, color: AppConstants.gold),
              SizedBox(width: 8),
              Text(
                'ابحث عن منتج أو قسم...',
                style: TextStyle(
                  color: AppConstants.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
