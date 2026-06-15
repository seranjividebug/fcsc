// lib/features/indicator_detail/presentation/widgets/generation_breakdown.dart
//
// "Breakdown" card for the Generation Capacity page (Energy / green theme).
// Tabs: By Capacity 2024 (MW) · By Production 2024 (GWh) · Growth Trend (MW).
// Green gradient bars matching the environment/energy palette.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class _Row {
  const _Row({required this.label, required this.fraction, required this.value});
  final String label;
  final double fraction;
  final double value;
}

class GenerationBreakdown extends ConsumerStatefulWidget {
  const GenerationBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<GenerationBreakdown> createState() =>
      _GenerationBreakdownState();
}

class _GenerationBreakdownState extends ConsumerState<GenerationBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  List<_Row> _fromTypes(List<({String label, double value})> items) {
    if (items.isEmpty) return const [];
    final max = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return items
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              value: e.value,
            ))
        .toList();
  }

  List<_Row> _trend() {
    final t = data.gcReTrend;
    if (t.isEmpty) return const [];
    final max = t.map((e) => e.mw).reduce((a, b) => a > b ? a : b);
    return t
        .map((e) => _Row(
              label: '${e.year} · ${NumberFormatter.full(e.mw)} MW',
              fraction: max > 0 ? e.mw / max : 0,
              value: e.mw,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final byCap = _fromTypes(data.gcByCapacity);
    final byProd = _fromTypes(data.gcByProduction);
    final trend = _trend();

    final tabs = <({String label, String unit, List<_Row> rows})>[
      if (byCap.isNotEmpty)
        (
          label: isAr ? 'حسب القدرة 2024' : 'By Capacity 2024',
          unit: 'MW',
          rows: byCap
        ),
      if (byProd.isNotEmpty)
        (
          label: isAr ? 'حسب الإنتاج 2024' : 'By Production 2024',
          unit: 'GWh',
          rows: byProd
        ),
      if (trend.isNotEmpty)
        (
          label: isAr ? 'اتجاه النمو' : 'Growth Trend',
          unit: 'MW',
          rows: trend
        ),
    ];
    if (tabs.isEmpty) return const SizedBox.shrink();
    if (_activeTab >= tabs.length) _activeTab = 0;
    final active = tabs[_activeTab];

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
                  for (int i = 0; i < active.rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _GenBar(row: active.rows[i], unit: active.unit),
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

class _GenBar extends StatelessWidget {
  const _GenBar({required this.row, required this.unit});
  final _Row row;
  final String unit;

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
          width: 78,
          child: Text(
            '${NumberFormatter.full(row.value)} $unit',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
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
