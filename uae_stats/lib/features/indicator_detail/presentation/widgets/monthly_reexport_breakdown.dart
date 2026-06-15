// lib/features/indicator_detail/presentation/widgets/monthly_reexport_breakdown.dart
//
// "Re-Export Breakdown" card for the Monthly Re-Exports page.
// Tabs (data-driven): Top Destinations · By Region · Monthly Growth.
// Destination/region values shown in "B AED" (billions); growth in "%".

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

class MonthlyReExportBreakdown extends ConsumerStatefulWidget {
  const MonthlyReExportBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<MonthlyReExportBreakdown> createState() =>
      _MonthlyReExportBreakdownState();
}

class _MonthlyReExportBreakdownState
    extends ConsumerState<MonthlyReExportBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  /// Value (AED millions) → "<n.n>B AED".
  String _billions(double mn) => '${(mn / 1000).toStringAsFixed(1)}B AED';

  List<_Row> _amounts(List<({String label, double value})> items) {
    if (items.isEmpty) return const [];
    final max = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return items
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: _billions(e.value),
            ))
        .toList();
  }

  List<_Row> _growth() {
    final g = data.monthlyReExportGrowth;
    if (g.isEmpty) return const [];
    final pos = g.where((r) => r.growth > 0).map((r) => r.growth);
    final maxPos = pos.isEmpty
        ? g.map((r) => r.growth.abs()).reduce((a, b) => a > b ? a : b)
        : pos.reduce((a, b) => a > b ? a : b);
    return g
        .take(12)
        .map((r) => _Row(
              label: r.label,
              fraction:
                  r.growth >= 0 ? (maxPos > 0 ? r.growth / maxPos : 0) : 0.06,
              valueText: NumberFormatter.percent(r.growth),
              positive: r.growth >= 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final dest = _amounts(data.monthlyReExportDestinations);
    final region = _amounts(data.monthlyReExportRegions);
    final growth = _growth();

    final tabs = <({String label, List<_Row> rows})>[
      if (dest.isNotEmpty)
        (label: isAr ? 'أهم الوجهات' : 'Top Destinations', rows: dest),
      if (region.isNotEmpty)
        (label: isAr ? 'حسب المنطقة' : 'By Region', rows: region),
      if (growth.isNotEmpty)
        (label: isAr ? 'النمو الشهري' : 'Monthly Growth', rows: growth),
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
                isAr ? 'تصنيف إعادة التصدير' : 'Re-Export Breakdown',
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
                      child: Container(
                        margin: const EdgeInsets.only(right: 18),
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
                    _MreBar(row: rows[i]),
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

class _MreBar extends StatelessWidget {
  const _MreBar({required this.row});
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
          width: 104,
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
                      color: row.positive == false
                          ? AppColors.error
                          : AppColors.champagneGold,
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
          width: 84,
          child: Text(
            row.valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
