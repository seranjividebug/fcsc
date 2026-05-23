// lib/features/indicator_detail/presentation/widgets/breadcrumb_bar.dart
//
// Breadcrumb row: "Demography › Vitals › Births" (40px, white bg, pearl border)
// Tappable segments navigate back to Home.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';

class BreadcrumbBar extends StatelessWidget {
  const BreadcrumbBar({
    super.key,
    required this.meta,
  });

  final IndicatorMeta meta;

  String get _category => _capitalise(meta.category);
  String get _subCategory => _capitalise(meta.subCategory.replaceAll('_', ' '));
  String get _name => meta.name.en;

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.pearlGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb chain — shrinks before source label does
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category — tappable, goes home
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: Text(
                    _category,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.emiratesGreen,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                // Sub-category — tappable, goes home
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: Text(
                    _subCategory,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.emiratesGreen,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                // Indicator name — not tappable (current page)
                Flexible(
                  child: Text(
                    _name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right: data source (always visible)
          Text(
            'Source: ${meta.sourceCode}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
