// lib/features/indicator_detail/presentation/widgets/tourism_breakdown.dart
//
// "Guest & Revenue Breakdown" card for the Tourism Main Indicators page.
// Tabs: By Emirate · By Guest Origin · By Star Rating · Revenue Share.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class _Row {
  const _Row({
    required this.label,
    required this.fraction,
    required this.valueText,
  });
  final String label;
  final double fraction;
  final String valueText;
}

class TourismBreakdown extends ConsumerStatefulWidget {
  const TourismBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<TourismBreakdown> createState() => _TourismBreakdownState();
}

class _TourismBreakdownState extends ConsumerState<TourismBreakdown> {
  int _activeTab = 0;
  IndicatorData get data => widget.data;

  // Percent rows ("NN.N% of guests" / "% revenue").
  List<_Row> _pct(String measure, String suffix) {
    final rows = data.tmBreakdown(measure);
    if (rows.isEmpty) return const [];
    final max = rows.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return rows
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: '${e.value.toStringAsFixed(1)}% $suffix',
            ))
        .toList();
  }

  // Revenue-share rows ("AED N.NB (P%)").
  List<_Row> _revShare() {
    final rows = data.tmBreakdown('TM_REVSHARE');
    if (rows.isEmpty) return const [];
    final max = rows.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return rows
        .map((e) => _Row(
              label: e.label,
              fraction: max > 0 ? e.value / max : 0,
              valueText: e.pct != null
                  ? 'AED ${e.value.toStringAsFixed(1)}B (${e.pct!.toStringAsFixed(1)}%)'
                  : 'AED ${e.value.toStringAsFixed(1)}B',
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final guestsSuffix = isAr ? 'من الضيوف' : 'of guests';
    final revSuffix = isAr ? 'إيراد' : 'revenue';

    final byEmirate = _pct('TM_EMIRATE', guestsSuffix);
    final byOrigin = _pct('TM_ORIGIN', guestsSuffix);
    final byStar = _pct('TM_STAR', revSuffix);
    final revShare = _revShare();

    final tabs = <({String label, List<_Row> rows})>[
      if (byEmirate.isNotEmpty)
        (label: isAr ? 'حسب الإمارة' : 'By Emirate', rows: byEmirate),
      if (byOrigin.isNotEmpty)
        (label: isAr ? 'حسب جنسية الضيف' : 'By Guest Origin', rows: byOrigin),
      if (byStar.isNotEmpty)
        (label: isAr ? 'حسب التصنيف' : 'By Star Rating', rows: byStar),
      if (revShare.isNotEmpty)
        (label: isAr ? 'حصة الإيرادات' : 'Revenue Share', rows: revShare),
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
                isAr ? 'تصنيف الضيوف والإيرادات' : 'Guest & Revenue Breakdown',
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
                    _TourismBar(row: rows[i]),
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

class _TourismBar extends StatelessWidget {
  const _TourismBar({required this.row});
  final _Row row;

  @override
  Widget build(BuildContext context) {
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
          width: 96,
          child: Text(
            row.valueText,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              height: 1.15,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
