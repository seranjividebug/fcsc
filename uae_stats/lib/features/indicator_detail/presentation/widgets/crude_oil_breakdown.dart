// lib/features/indicator_detail/presentation/widgets/crude_oil_breakdown.dart
//
// "Breakdown" card for the Crude Oil page (Energy / green theme).
// Tabs: By Trade Flow 2024 (000 bbl/d) · Top Production Years (000 bbl/d) ·
// Reserves Growth (Mn Bbl). Green gradient bars.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

const _flowNames = {
  'PR': 'Production',
  'EX': 'Exports',
  'IM': 'Imports',
};

class _Row {
  const _Row({required this.label, required this.fraction, required this.value});
  final String label;
  final double fraction;
  final double value;
}

class CrudeOilBreakdown extends ConsumerStatefulWidget {
  const CrudeOilBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<CrudeOilBreakdown> createState() => _CrudeOilBreakdownState();
}

class _CrudeOilBreakdownState extends ConsumerState<CrudeOilBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  List<_Row> _tradeFlow() {
    final flow = data.crudeOilTradeFlow;
    if (flow.isEmpty) return const [];
    const order = ['PR', 'EX', 'IM'];
    final entries = order
        .where(flow.containsKey)
        .map((k) => MapEntry(k, flow[k]!))
        .toList();
    if (entries.isEmpty) return const [];
    final max = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return entries
        .map((e) => _Row(
              label: _flowNames[e.key] ?? e.key,
              fraction: max > 0 ? e.value / max : 0,
              value: e.value,
            ))
        .toList();
  }

  List<_Row> _topProduction() {
    final s = data.crudeOilSeries('PR');
    if (s.isEmpty) return const [];
    final max = s.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final sorted = [...s]..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((p) => _Row(
              label: p.timePeriod,
              fraction: max > 0 ? p.value / max : 0,
              value: p.value,
            ))
        .toList();
  }

  List<_Row> _reservesGrowth() {
    final s = data.crudeOilSeries('RE');
    if (s.isEmpty) return const [];
    final max = s.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final sorted = [...s]..sort((a, b) => b.timePeriod.compareTo(a.timePeriod));
    return sorted
        .map((p) => _Row(
              label: p.timePeriod,
              fraction: max > 0 ? p.value / max : 0,
              value: p.value,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final flow = _tradeFlow();
    final prod = _topProduction();
    final reserves = _reservesGrowth();

    final tabs = <({String label, String unit, List<_Row> rows})>[
      if (flow.isNotEmpty)
        (
          label: isAr ? 'حسب تدفق التجارة 2024' : 'By Trade Flow 2024',
          unit: '000 bbl/d',
          rows: flow
        ),
      if (prod.isNotEmpty)
        (
          label: isAr ? 'أعلى سنوات الإنتاج' : 'Top Production Years',
          unit: '000 bbl/d',
          rows: prod
        ),
      if (reserves.isNotEmpty)
        (
          label: isAr ? 'نمو الاحتياطي' : 'Reserves Growth',
          unit: 'Mn Bbl',
          rows: reserves
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
                    _CrudeBar(row: active.rows[i], unit: active.unit),
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

class _CrudeBar extends StatelessWidget {
  const _CrudeBar({required this.row, required this.unit});
  final _Row row;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
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
