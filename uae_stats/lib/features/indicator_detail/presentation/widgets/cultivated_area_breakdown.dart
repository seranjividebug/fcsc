// lib/features/indicator_detail/presentation/widgets/cultivated_area_breakdown.dart
//
// "Breakdown" card for the Agricultural Cultivated Area page (green theme).
// Tabs: Overall · By Emirate · Top Growth. Donum values; growth in %.

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
    this.valueColor,
  });
  final String label;
  final double fraction;
  final String valueText;
  final Color? valueColor;
}

class CultivatedAreaBreakdown extends ConsumerStatefulWidget {
  const CultivatedAreaBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<CultivatedAreaBreakdown> createState() =>
      _CultivatedAreaBreakdownState();
}

class _CultivatedAreaBreakdownState
    extends ConsumerState<CultivatedAreaBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  List<_Row> _overall() {
    final s = data.uaeTotalSeries;
    if (s.isEmpty) return const [];
    final latest = s.last;
    return [
      _Row(
        label: 'Total Cultivated Area',
        fraction: 1.0,
        valueText: '${NumberFormatter.compact(latest.value)} Donum',
      ),
    ];
  }

  List<_Row> _byEmirate() {
    final items = data.cropAreaByEmirate;
    if (items.isEmpty) return const [];
    final max = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return items
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: '${NumberFormatter.compact(e.value)} Donum',
            ))
        .toList();
  }

  List<_Row> _topGrowth() {
    final items = data.cropAreaEmirateGrowth;
    if (items.isEmpty) return const [];
    final maxAbs =
        items.map((e) => e.pct.abs()).reduce((a, b) => a > b ? a : b);
    return items.map((e) {
      final positive = e.pct >= 0;
      final sign = positive ? '+' : '';
      return _Row(
        label: e.label,
        fraction: maxAbs > 0 ? e.pct.abs() / maxAbs : 0,
        valueText: '$sign${e.pct.toStringAsFixed(1)}%',
        valueColor: positive ? AppColors.success : AppColors.error,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final overall = _overall();
    final byEmirate = _byEmirate();
    final topGrowth = _topGrowth();

    final tabs = <({String label, List<_Row> rows})>[
      if (overall.isNotEmpty)
        (label: isAr ? 'الإجمالي' : 'Overall', rows: overall),
      if (byEmirate.isNotEmpty)
        (label: isAr ? 'حسب الإمارة' : 'By Emirate', rows: byEmirate),
      if (topGrowth.isNotEmpty)
        (label: isAr ? 'أعلى نمو' : 'Top Growth', rows: topGrowth),
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
                isAr ? 'التصنيف' : 'Breakdown',
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
                    final sel = e.key == _activeTab;
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = e.key),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(right: 18),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: sel
                                  ? AppColors.envGreen
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
                                sel ? FontWeight.w700 : FontWeight.w500,
                            color:
                                sel ? AppColors.envGreen : AppColors.slate600,
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
                    _AreaBar(row: rows[i]),
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

class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF24432B), Color(0xFF6FBF7F)],
                      ),
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
          width: 92,
          child: Text(
            row.valueText,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: row.valueColor ?? AppColors.slate900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
