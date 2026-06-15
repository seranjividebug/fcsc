// Per-sector distribution table for Employment by Sector.
//
// Renders one row per sector with the latest year's Total share, the prior
// year's share, and the YoY change — sorted largest-first to match the FCSC
// source table. Values are read directly from the indicator dataset.

import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/indicator_data.dart';

class SectorDistributionTable extends StatelessWidget {
  const SectorDistributionTable({
    super.key,
    required this.data,
    required this.isAr,
  });

  final IndicatorData data;
  final bool isAr;

  // Sector code → display name (mirrors breakdown _sectorNames).
  static const _names = <String, String>{
    'PRI': 'Private Sector', 'PRH': 'Private Household', 'SHA': 'Shared',
    'LOC': 'Local Government', 'FED': 'Federal Government', 'FOR': 'Foreign',
    'NON': 'Non-profit Orgs', 'WIT': 'Without Establishment',
    'DIP': 'Diplomatic Authority', 'OTH': 'Other', 'NO_STA': 'Not Stated',
  };

  // Sub-1% values get a 2nd decimal (e.g. 0.85%), otherwise one decimal.
  int _dec(double v) => v < 1 ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final byLevel = data.byLevel;
    final years = <String>{};
    byLevel.forEach((_, s) {
      for (final p in s) {
        years.add(p.timePeriod);
      }
    });
    if (years.isEmpty) return const SizedBox.shrink();
    final sortedYears = years.toList()..sort();
    final curYear = sortedYears.last;
    final prevYear =
        sortedYears.length > 1 ? sortedYears[sortedYears.length - 2] : null;

    final rows = <_SectorRow>[];
    byLevel.forEach((code, series) {
      double? cur, prev;
      for (final p in series) {
        if (p.timePeriod == curYear) cur = p.value;
        if (prevYear != null && p.timePeriod == prevYear) prev = p.value;
      }
      if (cur == null || cur == 0) return; // skip empty sectors
      rows.add(_SectorRow(
        label: _names[code.toUpperCase()] ?? code,
        current: cur,
        previous: prev,
      ));
    });
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => b.current.compareTo(a.current));

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.slate600,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(isAr ? 'القطاع' : 'SECTOR', style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(curYear,
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(prevYear ?? '—',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? 'س/س' : 'YoY',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = e.key;
            final r = e.value;
            final yoy = (r.previous != null && r.previous != 0)
                ? ((r.current - r.previous!) / r.previous!) * 100
                : null;
            return Container(
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r.current.toStringAsFixed(_dec(r.current))}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      r.previous != null
                          ? '${r.previous!.toStringAsFixed(_dec(r.previous!))}%'
                          : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _YoYBadge(yoy: yoy),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SectorRow {
  const _SectorRow(
      {required this.label, required this.current, this.previous});
  final String label;
  final double current;
  final double? previous;
}

/// Light pill showing the YoY change with an up/down arrow (green/red).
class _YoYBadge extends StatelessWidget {
  const _YoYBadge({required this.yoy});
  final double? yoy;

  @override
  Widget build(BuildContext context) {
    if (yoy == null) {
      return const Text('—',
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400));
    }
    final up = yoy! >= 0;
    final fg = up ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final bg = up ? const Color(0xFFE7F8EF) : const Color(0xFFFDECEC);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12, color: fg),
            const SizedBox(width: 2),
            Text(
              '${yoy!.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category × gender table (Category | Total | Male | Female) ───────────────

/// Per-category distribution with Total / Male / Female % columns for the
/// latest year. Rows are sorted by Total descending. Used by Unemployment by
/// Education (and any % distribution that publishes a gender split).
class CategoryGenderTable extends StatelessWidget {
  const CategoryGenderTable({
    super.key,
    required this.data,
    required this.isAr,
    required this.headerLabel,
  });

  final IndicatorData data;
  final bool isAr;
  final String headerLabel;

  // Education-level code → display name.
  static const _names = <String, String>{
    'ILLIT': 'Illiterate', 'RANDW': 'Read & Write', 'PRI': 'Primary',
    'LSEC': 'Lower Secondary', 'SEC': 'Upper Secondary',
    'PSNT': 'Post-Sec Non-Tert.', 'SCTE': 'Short-Cycle Tertiary',
    'BACH': 'Bachelor', 'HDIP': 'Higher Diploma', 'MAST': 'Master',
    'DOCT': 'Doctoral',
  };

  @override
  Widget build(BuildContext context) {
    final byLevel = data.byLevel; // Total series per level
    if (byLevel.isEmpty) return const SizedBox.shrink();
    final male = data.latestCategoryByGender('M');
    final female = data.latestCategoryByGender('F');

    final rows = <_CatRow>[];
    byLevel.forEach((code, series) {
      if (series.isEmpty) return;
      final c = code.toUpperCase();
      final total = series.last.value;
      if (total == 0) return;
      rows.add(_CatRow(
        label: _names[c] ?? code,
        total: total,
        male: male[c],
        female: female[c],
      ));
    });
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => b.total.compareTo(a.total));

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.slate600,
    );
    String pct(double? v) => v == null ? '—' : '${v.toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    flex: 5, child: Text(headerLabel, style: headerStyle)),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? 'الإجمالي' : 'TOTAL',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? 'ذكور' : 'MALE',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? 'إناث' : 'FEMALE',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = e.key;
            final r = e.value;
            return Container(
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      pct(r.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      pct(r.male),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      pct(r.female),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CatRow {
  const _CatRow(
      {required this.label, required this.total, this.male, this.female});
  final String label;
  final double total;
  final double? male;
  final double? female;
}

// ─── Occupation distribution table (Group | %2024 | Vs 2023 | ΔPP) ────────────

/// Per-occupation distribution for Labor Force by Occupation. Columns: latest
/// year %, YoY change vs prior year (relative %), and ΔPP (the raw
/// percentage-point change). Sorted by latest value descending. All figures
/// computed from the raw dataset; rounded only for display.
class OccupationDistributionTable extends StatelessWidget {
  const OccupationDistributionTable(
      {super.key, required this.data, required this.isAr});
  final IndicatorData data;
  final bool isAr;

  static const _names = <String, String>{
    'MAN': 'Managers', 'PROF': 'Professionals',
    'TECH': 'Technicians', 'CLER': 'Clerical',
    'SERV': 'Service & Sales', 'SKIL': 'Skilled Agriculture',
    'CRAF': 'Craft & Trade', 'PLAN': 'Plant Operators',
    'ELEM': 'Elementary', 'NO_STA': 'Not Stated',
  };

  @override
  Widget build(BuildContext context) {
    final byLevel = data.byLevel;
    final years = <String>{};
    byLevel.forEach((_, s) {
      for (final p in s) {
        years.add(p.timePeriod);
      }
    });
    if (years.isEmpty) return const SizedBox.shrink();
    final sortedYears = years.toList()..sort();
    final curYear = sortedYears.last;
    final prevYear =
        sortedYears.length > 1 ? sortedYears[sortedYears.length - 2] : null;

    final rows = <_OccRow>[];
    byLevel.forEach((code, series) {
      double? cur, prev;
      for (final p in series) {
        if (p.timePeriod == curYear) cur = p.value;
        if (prevYear != null && p.timePeriod == prevYear) prev = p.value;
      }
      if (cur == null || cur == 0) return;
      rows.add(_OccRow(
        label: _names[code.toUpperCase()] ?? code,
        current: cur,
        previous: prev,
      ));
    });
    if (rows.isEmpty) return const SizedBox.shrink();
    rows.sort((a, b) => b.current.compareTo(a.current));

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.slate600,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(isAr ? 'المجموعة المهنية' : 'OCCUPATION GROUP',
                      style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? '% $curYear' : '% $curYear',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(isAr ? 'مقابل $prevYear' : 'VS $prevYear',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                const Expanded(
                  flex: 2,
                  child: Text('ΔPP',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = e.key;
            final r = e.value;
            // YoY (relative %) and ΔPP (absolute percentage-point change).
            final yoy = (r.previous != null && r.previous != 0)
                ? ((r.current - r.previous!) / r.previous!) * 100
                : null;
            final dpp = r.previous != null ? r.current - r.previous! : null;
            return Container(
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r.current.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(flex: 2, child: _YoYBadge(yoy: yoy)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dpp == null
                          ? '—'
                          : '${dpp >= 0 ? '+' : '−'}${dpp.abs().toStringAsFixed(1)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dpp == null
                            ? AppColors.slate400
                            : (dpp >= 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626)),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OccRow {
  const _OccRow(
      {required this.label, required this.current, this.previous});
  final String label;
  final double current;
  final double? previous;
}
