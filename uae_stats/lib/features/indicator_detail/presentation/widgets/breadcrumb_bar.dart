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

  /// Sub-category label. National Accounts is shown as "GDP" in the breadcrumb
  /// (all national-accounts indicators are GDP series); others use the
  /// capitalised, space-separated sub-category code.
  String get _subCategory => meta.subCategory == 'national_accounts'
      ? 'GDP'
      : _capitalise(meta.subCategory.replaceAll('_', ' '));

  String get _name => meta.name.en;

  /// Always show the full 3-segment breadcrumb (Category › Sub-category ›
  /// Name) for a consistent structure across modules — the last segment is the
  /// current page, even when it repeats the sub-category (e.g.
  /// "Demography › Population › Population").
  bool get _nameDuplicatesSubCategory => false;

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Category accent — Economy gold · Environment green · Demography blue.
  Color get _accent => switch (meta.category) {
        'economy' => AppColors.champagneGold,
        'environment' => AppColors.envGreen,
        _ => AppColors.demBlue,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
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
                // Home — icon only, tappable, goes home
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.home_rounded, size: 15, color: accent),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                // Category — tappable, goes home
                GestureDetector(
                  onTap: () => context.go(AppRoutes.home),
                  child: Text(
                    _category,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: accent,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                // Sub-category. Normally a tappable blue link, but when it is
                // also the last segment (name duplicates it) it becomes the
                // current page → grey, non-tappable.
                _nameDuplicatesSubCategory
                    ? Flexible(
                        child: Text(
                          _subCategory,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate400,
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: Text(
                          _subCategory,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                      ),
                // Indicator name — shown only when it differs from the
                // sub-category, so "Population › Population" collapses to
                // "Population".
                if (!_nameDuplicatesSubCategory) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('›',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.slate400)),
                  ),
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
              ],
            ),
          ),

        ],
      ),
    );
  }
}
