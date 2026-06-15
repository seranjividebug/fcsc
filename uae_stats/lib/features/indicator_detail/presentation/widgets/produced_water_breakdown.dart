// lib/features/indicator_detail/presentation/widgets/produced_water_breakdown.dart
//
// "Breakdown" card for the Produced Water page (Environment / green theme).
// Tabs: By Entity · By Water Source · Annual Volumes. Green gradient bars, MCM.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

const _entityNames = {
  'EAD': 'Dept of Energy — Abu Dhabi',
  'DEWA': 'Dubai (DEWA)',
  'SEWA': 'Sharjah (SEWA)',
  'EWE': 'Etihad Water & Electricity',
};

const _sourceNames = {
  'SW': 'Sea Water (Desalinated)',
  'SEA': 'Sea Water (Desalinated)',
  'DESAL': 'Sea Water (Desalinated)',
  'GW': 'Ground Water',
  'GROUND': 'Ground Water',
};

class _Row {
  const _Row({required this.label, required this.fraction, required this.value});
  final String label;
  final double fraction;
  final double value;
}

class ProducedWaterBreakdown extends ConsumerStatefulWidget {
  const ProducedWaterBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<ProducedWaterBreakdown> createState() =>
      _ProducedWaterBreakdownState();
}

class _ProducedWaterBreakdownState
    extends ConsumerState<ProducedWaterBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  String _pretty(String c) =>
      c.isEmpty ? c : c[0].toUpperCase() + c.substring(1).toLowerCase();

  List<_Row> _fromMap(Map<String, double> m, Map<String, String> names) {
    if (m.isEmpty) return const [];
    final entries = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = entries.first.value;
    return entries
        .map((e) => _Row(
              label: names[e.key.toUpperCase()] ?? _pretty(e.key),
              fraction: max > 0 ? e.value / max : 0,
              value: e.value,
            ))
        .toList();
  }

  List<_Row> _annualVolumes() {
    final s = data.uaeTotalSeries;
    if (s.isEmpty) return const [];
    final peakYear =
        s.reduce((a, b) => b.value > a.value ? b : a).timePeriod;
    final max = s.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final sorted = [...s]..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .map((p) => _Row(
              label: p.timePeriod == peakYear
                  ? '${p.timePeriod} (Peak)'
                  : p.timePeriod,
              fraction: max > 0 ? p.value / max : 0,
              value: p.value,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final byEntity = _fromMap(data.producedWaterByEntity, _entityNames);
    final bySource = _fromMap(data.producedWaterBySource, _sourceNames);
    final annual = _annualVolumes();

    final tabs = <({String label, List<_Row> rows})>[
      if (byEntity.isNotEmpty)
        (label: isAr ? 'حسب الجهة' : 'By Entity', rows: byEntity),
      if (bySource.isNotEmpty)
        (label: isAr ? 'حسب المصدر' : 'By Water Source', rows: bySource),
      if (annual.isNotEmpty)
        (label: isAr ? 'الكميات السنوية' : 'Annual Volumes', rows: annual),
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
                    _WaterBar(row: rows[i]),
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

class _WaterBar extends StatelessWidget {
  const _WaterBar({required this.row});
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
          width: 70,
          child: Text(
            '${row.value.toStringAsFixed(1)} MCM',
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
