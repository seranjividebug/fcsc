// lib/features/indicator_detail/presentation/widgets/gdp_quarter_breakdown.dart
//
// "Breakdown" card for the Quarterly GDP (Current) page — a By Quarter view of
// the latest available year's four quarters as horizontal gold progress bars.
// Sector / Oil-vs-Non-Oil / Top-Growth tabs are intentionally deferred until
// the quarterly sector data source is wired (no fabricated values).
//
// Data comes straight from the quarterly series (timePeriod like "2025-Q3").

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class GdpQuarterBreakdown extends ConsumerWidget {
  const GdpQuarterBreakdown({super.key, required this.data});
  final IndicatorData data;

  /// Year (e.g. "2024") → its quarter points, for the latest year that
  /// publishes all four quarters (falls back to the latest year present).
  List<DataPoint> _latestYearQuarters() {
    final series = data.uaeTotalSeries.where((p) => p.timePeriod.contains('-Q'));
    final byYear = <String, List<DataPoint>>{};
    for (final p in series) {
      final yr = p.timePeriod.split('-').first;
      (byYear[yr] ??= []).add(p);
    }
    if (byYear.isEmpty) return const [];
    final years = byYear.keys.toList()..sort();
    // Prefer the latest year with 4 quarters, else the latest year.
    String target = years.last;
    for (final y in years.reversed) {
      if ((byYear[y]?.length ?? 0) >= 4) {
        target = y;
        break;
      }
    }
    final qs = byYear[target] ?? const [];
    // Sort by value descending to match the reference (largest quarter first).
    final sorted = [...qs]..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  String _quarterLabel(String timePeriod) {
    final dash = timePeriod.indexOf('-');
    if (dash <= 0) return timePeriod;
    return '${timePeriod.substring(dash + 1)} ${timePeriod.substring(0, dash)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final quarters = _latestYearQuarters();
    if (quarters.isEmpty) return const SizedBox.shrink();

    final maxVal =
        quarters.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: AppColors.shadowCard,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                isAr ? 'التصنيف' : 'Breakdown',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
            ),
            // Single active tab styled like the app's gold-underline tabs.
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.silver, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                margin: const EdgeInsets.only(right: 18),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: AppColors.champagneGold, width: 2.5),
                  ),
                ),
                child: Text(
                  isAr ? 'حسب الربع' : 'By Quarter',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  for (int i = 0; i < quarters.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _QuarterBar(
                      label: _quarterLabel(quarters[i].timePeriod),
                      fraction: maxVal > 0 ? quarters[i].value / maxVal : 0,
                      valueText: NumberFormatter.full(quarters[i].value),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuarterBar extends StatelessWidget {
  const _QuarterBar({
    required this.label,
    required this.fraction,
    required this.valueText,
  });
  final String label;
  final double fraction;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 10, color: AppColors.pearlGray),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.02, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
