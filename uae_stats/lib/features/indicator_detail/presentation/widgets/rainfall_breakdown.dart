// lib/features/indicator_detail/presentation/widgets/rainfall_breakdown.dart
//
// "Breakdown" card for the Annual Rainfall page (Environment / green theme).
// Tabs: By Station · By Season · By Month. Green gradient bars, mm values.
// By Station uses the live per-station data; Season/Month use merged RF_* rows.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

const _stationNames = {
  'ADWS': 'Abu Dhabi Airport',
  'AAWS': 'Al Ain Airport',
  'DUWS': 'Dubai Airport',
  'SHWS': 'Sharjah Airport',
  'RKWS': 'Ras Al Khaimah',
  'FJWS': 'Fujairah Airport',
  'AJWS': 'Ajman',
  'UQWS': 'Umm Al Quwain',
};

class _Row {
  const _Row({required this.label, required this.fraction, required this.value});
  final String label;
  final double fraction;
  final double value;
}

class RainfallBreakdown extends ConsumerStatefulWidget {
  const RainfallBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<RainfallBreakdown> createState() => _RainfallBreakdownState();
}

class _RainfallBreakdownState extends ConsumerState<RainfallBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  String _prettify(String code) {
    final c = code.replaceAll('_', ' ');
    return c.isEmpty ? code : c[0].toUpperCase() + c.substring(1).toLowerCase();
  }

  List<_Row> _byStation() {
    final m = data.rainfallByStation;
    if (m.isEmpty) return const [];
    final entries = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value;
    return entries
        .map((e) => _Row(
              label: _stationNames[e.key.toUpperCase()] ?? _prettify(e.key),
              fraction: max > 0 ? e.value / max : 0,
              value: e.value,
            ))
        .toList();
  }

  List<_Row> _fromMeasure(String measure) {
    final items = data.rfBreakdown(measure);
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

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final byStation = _byStation();
    final bySeason = _fromMeasure('RF_SEASON');
    final byMonth = _fromMeasure('RF_MONTH');

    final tabs = <({String label, List<_Row> rows})>[
      if (byStation.isNotEmpty)
        (label: isAr ? 'حسب المحطة' : 'By Station', rows: byStation),
      if (bySeason.isNotEmpty)
        (label: isAr ? 'حسب الفصل' : 'By Season', rows: bySeason),
      if (byMonth.isNotEmpty)
        (label: isAr ? 'حسب الشهر' : 'By Month', rows: byMonth),
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
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? AppColors.envGreen
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
                    _RainBar(row: rows[i]),
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

class _RainBar extends StatelessWidget {
  const _RainBar({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
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
          width: 72,
          child: Text(
            '${row.value.toStringAsFixed(1)} mm',
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
