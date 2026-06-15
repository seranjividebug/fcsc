// lib/features/indicator_detail/presentation/widgets/movement_breakdown.dart
//
// "Movement Breakdown" card for the Aircraft Movement page.
// Tabs (data-driven): By Emirate · By Arrivals · By Growth · By Departures.
// Horizontal gold bars over a light track; right-aligned "flights" / "%".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class _Row {
  const _Row({
    required this.label,
    required this.fraction,
    required this.valueText,
    this.positive,
  });
  final String label;
  final double fraction;
  final String valueText;
  final bool? positive;
}

class MovementBreakdown extends ConsumerStatefulWidget {
  const MovementBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<MovementBreakdown> createState() => _MovementBreakdownState();
}

class _MovementBreakdownState extends ConsumerState<MovementBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  List<_Row> _counts(List<({String label, double value})> items, String unit) {
    if (items.isEmpty) return const [];
    final max = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return items
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: '${NumberFormatter.full(e.value)} $unit',
            ))
        .toList();
  }

  List<_Row> _growth() {
    final g = data.aircraftEmirateGrowth;
    if (g.isEmpty) return const [];
    final max = g.map((r) => r.growth.abs()).reduce((a, b) => a > b ? a : b);
    return g
        .map((r) => _Row(
              label: r.label,
              fraction: max > 0 ? r.growth.abs() / max : 0,
              valueText: NumberFormatter.percent(r.growth),
              positive: r.growth >= 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final byEmirate = _counts(data.aircraftByEmirate(), isAr ? 'رحلة' : 'flights');
    final byArrivals =
        _counts(data.aircraftByEmirate(level: 'ARR'), isAr ? 'وصول' : 'arrivals');
    final byDepartures = _counts(
        data.aircraftByEmirate(level: 'DEP'), isAr ? 'مغادرة' : 'departures');
    final byGrowth = _growth();

    final tabs = <({String label, List<_Row> rows})>[
      if (byEmirate.isNotEmpty)
        (label: isAr ? 'حسب الإمارة' : 'By Emirate', rows: byEmirate),
      if (byArrivals.isNotEmpty)
        (label: isAr ? 'حسب الوصول' : 'By Arrivals', rows: byArrivals),
      if (byGrowth.isNotEmpty)
        (label: isAr ? 'حسب النمو' : 'By Growth', rows: byGrowth),
      if (byDepartures.isNotEmpty)
        (label: isAr ? 'حسب المغادرة' : 'By Departures', rows: byDepartures),
    ];
    if (tabs.isEmpty) return const SizedBox.shrink();
    if (_activeTab >= tabs.length) _activeTab = 0;
    final rows = tabs[_activeTab].rows;

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
                isAr ? 'تصنيف الحركة' : 'Movement Breakdown',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.silver, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: tabs.asMap().entries.map((e) {
                    final active = e.key == _activeTab;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = e.key),
                      behavior: HitTestBehavior.opaque,
                      // Right gap sits OUTSIDE the underline so the underline
                      // only spans the label width, not the inter-tab spacing.
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: active
                                    ? AppColors.champagneGold
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            tabs[e.key].label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              color: active
                                  ? AppColors.slate900
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  for (int i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _MovementBar(row: rows[i]),
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

class _MovementBar extends StatelessWidget {
  const _MovementBar({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    final valueColor = row.positive == null
        ? AppColors.slate900
        : (row.positive! ? AppColors.success : AppColors.error);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            row.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
              height: 1.15,
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
                  widthFactor: row.fraction.clamp(0.02, 1.0),
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
          width: 112,
          child: Text(
            row.valueText,
            textAlign: TextAlign.right,
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
