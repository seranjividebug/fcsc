// lib/features/indicator_detail/presentation/widgets/crop_breakdown.dart
//
// "Breakdown" card for the Crop Statistics page (Agriculture / green theme).
// Tabs: By Emirate (MT) · By Crop Type (MT) · By Area (Donum). Green bars.

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

class CropBreakdown extends ConsumerStatefulWidget {
  const CropBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<CropBreakdown> createState() => _CropBreakdownState();
}

class _CropBreakdownState extends ConsumerState<CropBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  List<_Row> _fromList(List<({String label, double value})> items) {
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

    final byEmirate = _fromList(data.cropByEmirate);
    final byType = _fromList(data.cropByType);
    final byArea = _fromList(data.cropByArea);

    final tabs = <({String label, String unit, List<_Row> rows})>[
      if (byEmirate.isNotEmpty)
        (label: isAr ? 'حسب الإمارة' : 'By Emirate', unit: 'MT', rows: byEmirate),
      if (byType.isNotEmpty)
        (
          label: isAr ? 'حسب نوع المحصول' : 'By Crop Type',
          unit: 'MT',
          rows: byType
        ),
      if (byArea.isNotEmpty)
        (label: isAr ? 'حسب المساحة' : 'By Area', unit: 'Donum', rows: byArea),
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
                    _CropBar(row: active.rows[i], unit: active.unit),
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

class _CropBar extends StatelessWidget {
  const _CropBar({required this.row, required this.unit});
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
          width: 88,
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
