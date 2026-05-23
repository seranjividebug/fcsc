// lib/features/indicator_detail/presentation/widgets/data_table_section.dart
//
// Stats summary chips row (5Y Min / Max / Avg / Growth) + full data table.
// Section: padding 20px sides, gap between chips 10px.

import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';

class DataTableSection extends StatelessWidget {
  const DataTableSection({super.key, required this.data});
  final IndicatorData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats chips ────────────────────────────────────────────────
        _StatsChipsRow(data: data),

        // ── Data table section ─────────────────────────────────────────
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Detailed Data',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.slate900,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _FullDataTable(series: data.uaeTotalSeries),
        ),
      ],
    );
  }
}

// ─── Stats chips row ──────────────────────────────────────────────────────────

class _StatsChipsRow extends StatelessWidget {
  const _StatsChipsRow({required this.data});
  final IndicatorData data;

  @override
  Widget build(BuildContext context) {
    final series = data.uaeTotalSeries;
    final fiveSlice = series.length > 5
        ? series.sublist(series.length - 5)
        : series;
    final fiveVals = fiveSlice.map((p) => p.value).toList();

    double min = 0, max = 0, avg = 0, growth = 0;
    String minYear = '', maxYear = '';

    if (fiveVals.isNotEmpty) {
      min = fiveVals.reduce((a, b) => a < b ? a : b);
      max = fiveVals.reduce((a, b) => a > b ? a : b);
      avg = fiveVals.reduce((a, b) => a + b) / fiveVals.length;
      if (fiveVals.first != 0) {
        growth = ((fiveVals.last - fiveVals.first) / fiveVals.first) * 100;
      }
      final minIdx = fiveVals.indexOf(min);
      final maxIdx = fiveVals.indexOf(max);
      minYear = fiveSlice[minIdx].timePeriod;
      maxYear = fiveSlice[maxIdx].timePeriod;
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
                overline: '5Y MIN',
                value: NumberFormatter.compact(min),
                caption: minYear,
              ),
            1 => _StatChip(
                overline: '5Y MAX',
                value: NumberFormatter.compact(max),
                caption: maxYear,
              ),
            2 => _StatChip(
                overline: '5Y AVG',
                value: NumberFormatter.compact(avg),
                caption: 'annual',
              ),
            _ => _StatChip(
                overline: '5Y GROWTH',
                value: NumberFormatter.percent(growth),
                caption: 'total',
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
  });

  final String overline;
  final String value;
  final String caption;

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
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              fontFeatures: [FontFeature.tabularFigures()],
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
  const _FullDataTable({required this.series});
  final List<DataPoint> series;

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
            child: const Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text('YEAR',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                Expanded(
                  child: Text('VALUE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Text('YoY',
                      textAlign: TextAlign.right,
                      style: TextStyle(
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
                    width: 56,
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
                  // Value — flex, right aligned
                  Expanded(
                    child: Text(
                      NumberFormatter.full(pt.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // YoY badge — fixed width, right aligned
                  SizedBox(
                    width: 96,
                    child: Align(
                      alignment: Alignment.centerRight,
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

          // ── Footer ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.pearlGray)),
            ),
            child: const Text(
              'Data from Federal Competitiveness and Statistics Centre (FCSC). '
              'Values represent official registered figures for the UAE.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.slate400,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
