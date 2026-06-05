// lib/features/indicator_detail/presentation/widgets/data_table_section.dart
//
// Stats summary chips row (5Y Min / Max / Avg / Growth) + full data table.
// Section: padding 20px sides, gap between chips 10px.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class DataTableSection extends ConsumerWidget {
  const DataTableSection({super.key, required this.data});
  final IndicatorData data;

  bool get _hasGender =>
      data.byGender.containsKey('M') && data.byGender.containsKey('F');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats chips ────────────────────────────────────────────────
        _StatsChipsRow(data: data, isAr: isAr),

        // ── Data table section ─────────────────────────────────────────
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              isAr ? 'البيانات التفصيلية' : 'Detailed Data',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.slate900,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: (data.isRainfall || data.isProducedWater)
              // Decimal-valued national trend (mm / MCM).
              ? _FullDataTable(
                  series: data.uaeTotalSeries,
                  isAr: isAr,
                  isDecimal: true,
                )
              : data.isLivestock
              // Livestock head counts by gender (Female / Male / Total).
              ? _GenderDataTable(
                  total: data.uaeTotalSeries,
                  male: data.livestockGenderSeries('M'),
                  female: data.livestockGenderSeries('F'),
                  isAr: isAr,
                )
              : data.isEmployedEducation
              // University Degree+ share by gender (Male/Female/Total),
              // consistent with the hero KPI — not the 100% distribution row.
              ? _GenderDataTable(
                  total: data.universityShareSeries('_T'),
                  male: data.universityShareSeries('M'),
                  female: data.universityShareSeries('F'),
                  isAr: isAr,
                  isPercent: true,
                )
              : data.isEmploymentSector
                  // Private Sector share by gender (Male/Female/Total).
                  ? _GenderDataTable(
                      total: data.sectorShareSeries('PRI', '_T'),
                      male: data.sectorShareSeries('PRI', 'M'),
                      female: data.sectorShareSeries('PRI', 'F'),
                      isAr: isAr,
                      isPercent: true,
                    )
                  : (data.isEconomicActivity ||
                          data.isTopCategoryShare ||
                          data.meta.id == 'labour_unemployment_age_gender')
                      // % distribution — show the headline-category trend
                      // (top occupation / education, or Youth 15–34 share).
                      ? _FullDataTable(
                          series: data.uaeTotalSeries,
                          isAr: isAr,
                          isPercent: true)
                  : _hasGender
                      ? _GenderDataTable(
                          total: data.uaeTotalSeries,
                          male: data.byGender['M']!,
                          female: data.byGender['F']!,
                          isAr: isAr,
                        )
                      : _FullDataTable(series: data.uaeTotalSeries, isAr: isAr),
        ),
      ],
    );
  }
}

// ─── Stats chips row ──────────────────────────────────────────────────────────

class _StatsChipsRow extends StatelessWidget {
  const _StatsChipsRow({required this.data, required this.isAr});
  final IndicatorData data;
  final bool isAr;

  // Use 3Y slice when ≤3 data points available, else 5Y
  static int _sliceN(List<DataPoint> series) =>
      series.length <= 3 ? 3 : 5;

  @override
  Widget build(BuildContext context) {
    final series = data.uaeTotalSeries;
    final n = _sliceN(series);
    final slice = series.length > n ? series.sublist(series.length - n) : series;
    final vals = slice.map((p) => p.value).toList();
    final label = '${n}Y';
    final pct = data.isEmployedEducation ||
        data.isEmploymentSector ||
        data.isTopCategoryShare ||
        data.meta.id == 'labour_unemployment_age_gender'; // share → format %
    final dec = data.isRainfall || data.isProducedWater; // mm / MCM → 1 decimal
    String fmtVal(double v) => pct
        ? '${v.toStringAsFixed(1)}%'
        : dec
            ? v.toStringAsFixed(1)
            : NumberFormatter.compact(v);

    double min = 0, max = 0, avg = 0, growth = 0;
    String minYear = '', maxYear = '';

    if (vals.isNotEmpty) {
      min = vals.reduce((a, b) => a < b ? a : b);
      max = vals.reduce((a, b) => a > b ? a : b);
      avg = vals.reduce((a, b) => a + b) / vals.length;
      if (vals.first != 0) {
        growth = ((vals.last - vals.first) / vals.first) * 100;
      }
      minYear = slice[vals.indexOf(min)].timePeriod;
      maxYear = slice[vals.indexOf(max)].timePeriod;
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return switch (index) {
            0 => _StatChip(
                overline: isAr ? 'أدنى $label' : '$label MIN',
                value: fmtVal(min),
                caption: minYear,
              ),
            1 => _StatChip(
                overline: isAr ? 'أعلى $label' : '$label MAX',
                value: fmtVal(max),
                caption: maxYear,
              ),
            2 => _StatChip(
                overline: isAr ? 'متوسط $label' : '$label AVG',
                value: fmtVal(avg),
                caption: isAr ? 'سنوي' : 'annual',
              ),
            _ => _StatChip(
                overline: isAr ? 'نمو $label' : '$label GROWTH',
                value: NumberFormatter.percent(growth),
                caption: isAr ? 'إجمالي' : 'total',
                valueColor: AppColors.success,
              ),
          };
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.overline,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String overline;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            overline,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.63,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.slate900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full data table (all available data) ─────────────────────────────────────

class _FullDataTable extends StatelessWidget {
  const _FullDataTable(
      {required this.series,
      required this.isAr,
      this.isPercent = false,
      this.isDecimal = false});
  final List<DataPoint> series;
  final bool isAr;
  final bool isPercent;
  final bool isDecimal;

  String _fmtV(double v) => isPercent
      ? '${v.toStringAsFixed(1)}%'
      : isDecimal
          ? v.toStringAsFixed(1)
          : NumberFormatter.full(v);

  @override
  Widget build(BuildContext context) {
    // Deduplicate by timePeriod — keep last entry per period (most specific)
    final seen = <String>{};
    final unique = series.reversed
        .where((p) => seen.add(p.timePeriod))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(isAr ? 'السنة' : 'YEAR',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                Expanded(
                  child: Text(isAr ? 'القيمة' : 'VALUE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                SizedBox(
                  width: 60,
                  child: Text(isAr ? 'س/س' : 'YoY',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
              ],
            ),
          ),

          // ── Data rows ───────────────────────────────────────────────────
          ...unique.asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            // YoY: compare to next item (which is the previous year, since reversed)
            double? yoy;
            if (idx < unique.length - 1) {
              final prev = unique[idx + 1].value;
              if (prev != 0) yoy = ((pt.value - prev) / prev) * 100;
            }

            final isOdd = idx.isOdd;

            return Container(
              color: isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Year — fixed width, left aligned
                  SizedBox(
                    width: 48,
                    child: Text(
                      pt.timePeriod,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // Value — flex, center aligned
                  Expanded(
                    child: Text(
                      _fmtV(pt.value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // YoY badge — fixed width, center aligned
                  SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.center,
                      child: yoy == null
                          ? const Text('—',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400))
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: yoy >= 0
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${yoy >= 0 ? '↑' : '↓'} ${yoy.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: yoy >= 0
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
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

// ─── Gender data table (Year | Male | Female | Total) ─────────────────────────

class _GenderDataTable extends StatelessWidget {
  const _GenderDataTable({
    required this.total,
    required this.male,
    required this.female,
    required this.isAr,
    this.isPercent = false,
  });

  final List<DataPoint> total;
  final List<DataPoint> male;
  final List<DataPoint> female;
  final bool isAr;

  /// When true, cell values are % shares rendered as "X.X%".
  final bool isPercent;

  String _fmt(double v) =>
      isPercent ? '${v.toStringAsFixed(1)}%' : NumberFormatter.full(v);

  @override
  Widget build(BuildContext context) {
    final maleMap = {for (final p in male) p.timePeriod: p.value};
    final femaleMap = {for (final p in female) p.timePeriod: p.value};

    final seen = <String>{};
    final rows = total.reversed.where((p) => seen.add(p.timePeriod)).toList();

    const headerStyle = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      letterSpacing: 0.4, color: AppColors.slate600,
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
                SizedBox(width: 44, child: Text(isAr ? 'السنة' : 'YEAR', style: headerStyle)),
                Expanded(child: Text(isAr ? 'ذكور' : 'MALE', textAlign: TextAlign.right, style: headerStyle)),
                Expanded(child: Text(isAr ? 'إناث' : 'FEMALE', textAlign: TextAlign.right, style: headerStyle)),
                Expanded(child: Text(isAr ? 'الإجمالي' : 'TOTAL', textAlign: TextAlign.right, style: headerStyle)),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            final m = maleMap[pt.timePeriod];
            final f = femaleMap[pt.timePeriod];
            return Container(
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(pt.timePeriod,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ),
                  Expanded(
                    child: Text(
                      m != null ? _fmt(m) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f != null ? _fmt(f) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _fmt(pt.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.demBlue,
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
