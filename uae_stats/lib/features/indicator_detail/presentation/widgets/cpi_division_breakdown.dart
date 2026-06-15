// lib/features/indicator_detail/presentation/widgets/cpi_division_breakdown.dart
//
// "CPI by Division" card for the CPI Annual page.
// Tabs: <cur> Index · <cur> Change · <prev> Index · <prev> Change.
// Index tabs show index points; Change tabs show YoY % (red when negative).

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

class CpiDivisionBreakdown extends ConsumerStatefulWidget {
  const CpiDivisionBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<CpiDivisionBreakdown> createState() =>
      _CpiDivisionBreakdownState();
}

class _CpiDivisionBreakdownState extends ConsumerState<CpiDivisionBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  /// Index tab: bars scaled to the max index, value = "NN.NN".
  List<_Row> _index(String year) {
    final divs = data.cpiDivisions('CPI_DIV_IDX', year);
    if (divs.isEmpty) return const [];
    final max = divs.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return divs
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: e.value.toStringAsFixed(2),
            ))
        .toList();
  }

  /// Change tab: bars scaled to max positive change; negatives short red stub.
  List<_Row> _change(String year) {
    final divs = data.cpiDivisions('CPI_DIV_CHG', year);
    if (divs.isEmpty) return const [];
    final pos = divs.where((e) => e.value > 0).map((e) => e.value);
    final maxPos = pos.isEmpty
        ? divs.map((e) => e.value.abs()).reduce((a, b) => a > b ? a : b)
        : pos.reduce((a, b) => a > b ? a : b);
    return divs
        .map((e) => _Row(
              label: e.label,
              fraction:
                  e.value >= 0 ? (maxPos > 0 ? e.value / maxPos : 0) : 0.06,
              valueText: NumberFormatter.percent(e.value),
              positive: e.value >= 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final cur = data.latestPeriod;
    final prev = (int.tryParse(cur) != null)
        ? '${int.parse(cur) - 1}'
        : cur;

    final tabs = <({String label, List<_Row> rows})>[
      (label: '$cur ${isAr ? "مؤشر" : "Index"}', rows: _index(cur)),
      (label: '$cur ${isAr ? "تغير" : "Change"}', rows: _change(cur)),
      (label: '$prev ${isAr ? "مؤشر" : "Index"}', rows: _index(prev)),
      (label: '$prev ${isAr ? "تغير" : "Change"}', rows: _change(prev)),
    ].where((t) => t.rows.isNotEmpty).toList();

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
                isAr ? 'المؤشر حسب القسم' : 'CPI by Division',
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
                    _CpiBar(row: rows[i]),
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

class _CpiBar extends StatelessWidget {
  const _CpiBar({required this.row});
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
          width: 116,
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
          width: 64,
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
