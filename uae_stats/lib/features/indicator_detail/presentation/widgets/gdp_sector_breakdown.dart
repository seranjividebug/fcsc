// lib/features/indicator_detail/presentation/widgets/gdp_sector_breakdown.dart
//
// "Sector Breakdown" card for the GDP (Current Prices) page — a standalone
// component shown BELOW the existing Overall / By Level breakdown. Four tabs:
//   • 2024 Sectors   — latest-year GDP value per ISIC sector (desc)
//   • Oil vs Non-Oil — non-oil aggregate vs leading sectors
//   • Top Growth     — sectors ranked by 2015→2024 cumulative growth
//   • 2015–2024      — same growth view, period-labelled
// Each row is a horizontal gold progress bar over a light track, scaled to the
// largest value in the active tab. All data is computed from [IndicatorData].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

/// One bar row: label, proportional gold bar, right-aligned value string.
class _BarRow {
  const _BarRow({
    required this.label,
    required this.fraction,
    required this.valueText,
    this.positive,
  });
  final String label;
  final double fraction; // 0..1 of the tab's max
  final String valueText;
  final bool? positive; // for growth: tints the value (green/red)
}

class GdpSectorBreakdown extends ConsumerStatefulWidget {
  const GdpSectorBreakdown({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<GdpSectorBreakdown> createState() =>
      _GdpSectorBreakdownState();
}

class _GdpSectorBreakdownState extends ConsumerState<GdpSectorBreakdown> {
  int _activeTab = 0;

  IndicatorData get data => widget.data;

  // ISIC short names. Two variants: the generic sector name and the
  // Oil-vs-Non-Oil framing (e.g. B → "Mining & Oil", G → "Trade & Svc.").
  static const _names = <String, ({String en, String ar})>{
    'A':  (en: 'Agriculture',            ar: 'الزراعة'),
    'B':  (en: 'Mining & Quarrying',     ar: 'التعدين والمحاجر'),
    'C':  (en: 'Manufacturing',          ar: 'الصناعة التحويلية'),
    'DE': (en: 'Electricity & Water',    ar: 'الكهرباء والمياه'),
    'F':  (en: 'Construction',           ar: 'الإنشاءات'),
    'G':  (en: 'Wholesale & Retail Trade', ar: 'تجارة الجملة والتجزئة'),
    'H':  (en: 'Transportation & Storage', ar: 'النقل والتخزين'),
    'I':  (en: 'Accommodation & Food',   ar: 'الإقامة والطعام'),
    'J':  (en: 'Information & Comm.',    ar: 'المعلومات والاتصالات'),
    'K':  (en: 'Financial & Insurance',  ar: 'المال والتأمين'),
    'L':  (en: 'Real Estate',            ar: 'العقارات'),
    'MN': (en: 'Professional Services',  ar: 'الأنشطة المهنية'),
    'O':  (en: 'Public Administration',  ar: 'الإدارة العامة'),
    'P':  (en: 'Education',              ar: 'التعليم'),
    'Q':  (en: 'Health & Social Work',   ar: 'الصحة والعمل الاجتماعي'),
    'RS': (en: 'Arts & Other Services',  ar: 'الفنون وخدمات أخرى'),
    'T':  (en: 'Households as Employers', ar: 'الأسر كأرباب عمل'),
  };

  // Oil-vs-Non-Oil framing labels.
  static const _oilNames = <String, ({String en, String ar})>{
    '_TNO': (en: 'Non-Oil GDP', ar: 'الناتج غير النفطي'),
    'B':    (en: 'Mining & Oil', ar: 'التعدين والنفط'),
    'G':    (en: 'Trade & Svc.', ar: 'التجارة والخدمات'),
    'K':    (en: 'Finance', ar: 'المال'),
    'C':    (en: 'Manufacturing', ar: 'الصناعة'),
    'F':    (en: 'Construction', ar: 'الإنشاءات'),
  };

  String _name(String code, bool isAr, {bool oil = false}) {
    // Oil-vs-Non-Oil framing labels take priority for that tab.
    if (oil) {
      final o = _oilNames[code.toUpperCase()];
      if (o != null) return isAr ? o.ar : o.en;
    }
    // Prefer a name embedded in the data (e.g. Quarterly GDP sector names from
    // the SDMX structure); fall back to the ISIC code map, then the raw code.
    final embedded = data.gdpSectorLabel(code);
    if (embedded != null) return embedded;
    final m = _names[code.toUpperCase()];
    return m == null ? code : (isAr ? m.ar : m.en);
  }

  // ─── Tab data builders ──────────────────────────────────────────────────

  List<_BarRow> _sectors2024(bool isAr) {
    final sectors = data.gdpSectorsLatest;
    if (sectors.isEmpty) return const [];
    final max = sectors.first.value;
    return sectors
        .take(8)
        .map((s) => _BarRow(
              label: _name(s.code, isAr),
              fraction: max > 0 ? s.value / max : 0,
              valueText: NumberFormatter.full(s.value),
            ))
        .toList();
  }

  List<_BarRow> _oilVsNonOil(bool isAr) {
    final rows = data.gdpOilVsNonOil;
    if (rows.isEmpty) return const [];
    final max = rows.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    return rows
        .take(6)
        .map((r) => _BarRow(
              label: _name(r.code, isAr, oil: true),
              fraction: max > 0 ? r.value / max : 0,
              valueText: NumberFormatter.full(r.value),
            ))
        .toList();
  }

  List<_BarRow> _byQuarter(bool isAr) {
    final qs = [...data.gdpQuarterly];
    if (qs.isEmpty) return const [];
    final max = qs.map((q) => q.value).reduce((a, b) => a > b ? a : b);
    // Chronological order (Q1→Q4) for display.
    qs.sort((a, b) => a.label.compareTo(b.label));
    return qs
        .map((q) => _BarRow(
              label: q.label,
              fraction: max > 0 ? q.value / max : 0,
              valueText: NumberFormatter.full(q.value),
            ))
        .toList();
  }

  /// Per-year YoY growth of the annual GDP total (newest year first), for the
  /// "Annual Growth" tab. Bars are scaled to the largest POSITIVE growth so a
  /// strong year reads as the longest bar; a negative year (decline) shows a
  /// short red stub rather than a misleadingly-full bar.
  List<_BarRow> _annualGrowth(bool isAr) {
    final s = data.gdpAnnualTotalSeries;
    if (s.length < 2) return const [];
    final rows = <({String year, double g})>[];
    for (var i = 1; i < s.length; i++) {
      final prev = s[i - 1].value;
      if (prev == 0) continue;
      rows.add((year: s[i].timePeriod, g: (s[i].value - prev) / prev * 100));
    }
    if (rows.isEmpty) return const [];
    final positives = rows.where((r) => r.g > 0).map((r) => r.g);
    final maxPos = positives.isEmpty
        ? rows.map((r) => r.g.abs()).reduce((a, b) => a > b ? a : b)
        : positives.reduce((a, b) => a > b ? a : b);
    rows.sort((a, b) => b.year.compareTo(a.year)); // newest first
    return rows
        .map((r) => _BarRow(
              label: r.year,
              // Positive: proportional to the strongest year. Negative: a short
              // fixed red stub so declines never read as top performers.
              fraction: r.g >= 0
                  ? (maxPos > 0 ? r.g / maxPos : 0)
                  : 0.06,
              valueText: NumberFormatter.percent(r.g),
              positive: r.g >= 0,
            ))
        .toList();
  }

  List<_BarRow> _topGrowth(bool isAr) {
    final g = data.gdpSectorGrowth;
    if (g.isEmpty) return const [];
    final max =
        g.map((r) => r.growth.abs()).reduce((a, b) => a > b ? a : b);
    return g
        .take(8)
        .map((r) => _BarRow(
              label: _name(r.code, isAr),
              fraction: max > 0 ? r.growth.abs() / max : 0,
              valueText: NumberFormatter.percent(r.growth),
              positive: r.growth >= 0,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    final hasSectors = data.gdpSectorsLatest.isNotEmpty;
    final hasQuarters = data.gdpQuarterly.isNotEmpty;

    // Render whenever there's any GDP breakdown data (sectors and/or quarters).
    if (!data.isGdpIsic || (!hasSectors && !hasQuarters)) {
      return const SizedBox.shrink();
    }

    // Period label for the cumulative-growth tabs.
    final g = data.gdpSectorGrowth;
    final periodLabel = g.isEmpty
        ? '2015–2024'
        : '${g.first.fromYear}–${g.first.toYear}';

    final isQuarterlyConstant = data.meta.id == 'gdp_quarterly_constant';
    final hasAnnualGrowth = data.gdpAnnualTotalSeries.length >= 2;

    final tabs = <({String label, List<_BarRow> Function() rows})>[
      if (isQuarterlyConstant) ...[
        // GDP Breakdown: Quarters / Oil vs Non-Oil / Annual Growth.
        if (hasQuarters)
          (label: isAr ? 'الأرباع' : 'Quarters',
           rows: () => _byQuarter(isAr)),
        if (hasSectors)
          (label: isAr ? 'نفطي مقابل غير نفطي' : 'Oil vs Non-Oil',
           rows: () => _oilVsNonOil(isAr)),
        if (hasAnnualGrowth)
          (label: isAr ? 'النمو السنوي' : 'Annual Growth',
           rows: () => _annualGrowth(isAr)),
      ] else ...[
        // Sector tabs only when sector data is present.
        if (hasSectors)
          (label: hasQuarters
                  ? (isAr ? 'حسب القطاع' : 'By Sector')
                  : (isAr ? 'قطاعات $periodLabel' : '2024 Sectors'),
           rows: () => _sectors2024(isAr)),
        if (hasQuarters)
          (label: isAr ? 'حسب الربع' : 'By Quarter',
           rows: () => _byQuarter(isAr)),
        if (hasSectors)
          (label: isAr ? 'نفطي مقابل غير نفطي' : 'Oil vs Non-Oil',
           rows: () => _oilVsNonOil(isAr)),
        if (hasSectors)
          (label: isAr ? 'الأعلى نمواً' : 'Top Growth',
           rows: () => _topGrowth(isAr)),
      ],
    ];

    if (tabs.isEmpty) return const SizedBox.shrink();

    if (_activeTab >= tabs.length) _activeTab = 0;
    final rows = tabs[_activeTab].rows();

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
            // ── Title ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                isQuarterlyConstant
                    ? (isAr ? 'تصنيف الناتج المحلي' : 'GDP Breakdown')
                    : (isAr ? 'تصنيف القطاعات' : 'Sector Breakdown'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
            ),

            // ── Tab bar (gold underline on active) ──────────────────────
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

            // ── Bars ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: rows.isEmpty
                  ? Text(
                      isAr ? 'لا توجد بيانات' : 'No data available',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.slate400),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          _SectorBar(row: rows[i]),
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

class _SectorBar extends StatelessWidget {
  const _SectorBar({required this.row});
  final _BarRow row;

  @override
  Widget build(BuildContext context) {
    final valueColor = row.positive == null
        ? AppColors.slate900
        : (row.positive! ? AppColors.success : AppColors.error);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label
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
        // Bar over track
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
                      // Negative growth → red bar; otherwise gold.
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
        // Value
        SizedBox(
          width: 72,
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
