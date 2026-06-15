// lib/features/indicator_detail/presentation/widgets/indicator_chart.dart
//
// Chart section for the Indicator Detail screen.
// Manages: ChartType (line/bar/table) × ChartRange (2Y/5Y/10Y/MAX).
// Uses fl_chart for line and bar rendering.
// Data table rendered natively (Flutter Table widget).

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

enum _ChartType { line, bar, table }

enum _ChartRange { y3, y5 }

extension _RangeLabel on _ChartRange {
  String get label => switch (this) {
        _ChartRange.y3  => '3Y',
        _ChartRange.y5  => '5Y',
      };

  int? get years => switch (this) {
        _ChartRange.y3  => 3,
        _ChartRange.y5  => 5,
      };
}

// Line chart shows at most this many X-axis points to stay clutter-free.
const int _kMaxLinePoints = 5;

// Table view shows at most the latest N years to stay readable.
const int _kMaxTableYears = 15;

class IndicatorChart extends ConsumerStatefulWidget {
  const IndicatorChart({
    super.key,
    required this.allSeries,
    required this.indicatorName,
    this.indicatorId = '',
    this.unitCode = 'PS',
    this.unitLabel = '',
    this.accentColor = AppColors.demBlue,
    this.femaleSeries = const [],
    this.maleSeries = const [],
  });

  final List<DataPoint> allSeries;
  final String indicatorName;
  final String indicatorId;
  final String unitCode;

  /// Human-readable unit appended to chart tooltip values (e.g. "MW", "GWh").
  final String unitLabel;
  final Color accentColor;
  final List<DataPoint> femaleSeries;
  final List<DataPoint> maleSeries;

  @override
  ConsumerState<IndicatorChart> createState() => _IndicatorChartState();
}

class _IndicatorChartState extends ConsumerState<IndicatorChart> {
  _ChartType _type = _ChartType.line;
  late _ChartRange _range;

  @override
  void initState() {
    super.initState();
    _range = _defaultRange;
  }

  // Default range. Line view defaults to 5Y (≤5 points).
  _ChartRange get _defaultRange {
    final n = widget.allSeries.length;
    if (n <= 3) return _ChartRange.y3;
    return _ChartRange.y5;
  }

  // Which range chips to show based on data length (10Y and MAX removed).
  List<_ChartRange> get _visibleRanges {
    final n = widget.allSeries.length;
    if (n <= 3) return [_ChartRange.y3];
    return [_ChartRange.y3, _ChartRange.y5];
  }

  bool get _hasGender =>
      widget.femaleSeries.isNotEmpty && widget.maleSeries.isNotEmpty;

  /// Share (% distribution) indicators — chart values are percentages, so
  /// they render as "X.X%" rather than compact counts.
  static const _shareIds = {
    'labour_employed_age_gender',
    'labour_employed_education',
    'labour_economic_activity',
    'labour_employment_sector',
    'labour_unemployment_education',
    'labour_workforce_occupation',
    'labour_unemployment_age_gender',
  };

  bool get _isPercent => _shareIds.contains(widget.indicatorId);

  /// Decimal-valued indicators (mm / MCM) — one decimal place, no compaction.
  static const _decimalIds = {
    'ecology_rainfall',
    'ecology_produced_water',
    'energy_generation_capacity',
    'energy_renewable',
    'ecology_natural_reserves',
    'ecology_ramsar_wetlands',
  };
  bool get _isDecimal => _decimalIds.contains(widget.indicatorId);

  // Y-axis tick label. Counts always use compact K/M/B notation so labels
  // never wrap/clip in the narrow reserved axis width on mobile. Decimal
  // indicators (mm / MCM) compact only when large, else keep one decimal.
  String _fmtValue(double v) => _isPercent
      ? '${v.toStringAsFixed(1)}%'
      : _isDecimal
          ? (v.abs() >= 1000 ? NumberFormatter.axisTick(v) : v.toStringAsFixed(1))
          : NumberFormatter.axisTick(v);

  /// Chart-card title shown above Line / Bar / Table, e.g.
  /// "Annual Population in the UAE (Persons)".
  String _chartCardTitle(bool isAr) {
    final base = isAr
        ? '${widget.indicatorName} السنوي في الإمارات'
        : 'Annual ${widget.indicatorName} in the UAE';
    final unit = (widget.unitLabel.isEmpty || _isPercent)
        ? ''
        : ' (${widget.unitLabel})';
    return '$base$unit';
  }

  /// Suffix appended to tooltip values, e.g. " MW". Empty for percent series.
  String get _unitSuffix =>
      (_isPercent || widget.unitLabel.isEmpty) ? '' : ' ${widget.unitLabel}';

  String _fmtValueFull(double v) => _isPercent
      ? '${v.toStringAsFixed(1)}%'
      : _isDecimal
          ? '${v.toStringAsFixed(1)}$_unitSuffix'
          : '${NumberFormatter.full(v)}$_unitSuffix';

  List<DataPoint> get _series {
    final all = widget.allSeries;
    if (all.isEmpty) return all;
    final n = _range.years;
    if (n == null || all.length <= n) return all;
    return all.sublist(all.length - n);
  }

  List<DataPoint> _slice(List<DataPoint> src) {
    if (src.isEmpty) return src;
    final n = _range.years;
    if (n == null || src.length <= n) return src;
    return src.sublist(src.length - n);
  }

  /// Caps a series to at most [_kMaxLinePoints] (last N points) so the line
  /// chart never renders more than 5 X-axis values.
  List<DataPoint> _capForLine(List<DataPoint> src) {
    if (src.length <= _kMaxLinePoints) return src;
    return src.sublist(src.length - _kMaxLinePoints);
  }

  /// Series for the Table view — latest [_kMaxTableYears] years only.
  /// Independent of the range chips so long histories stay readable.
  List<DataPoint> get _tableSeries {
    final all = widget.allSeries;
    if (all.length <= _kMaxTableYears) return all;
    return all.sublist(all.length - _kMaxTableYears);
  }


  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // ── Section title ─────────────────────────────────────────────
        // Sits between the hero card and the Line/Bar/Table selector; visible
        // for all chart views. Matches the app's section-title styling.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            isAr ? 'الاتجاه الزمني' : 'Period Trend',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.slate900,
            ),
          ),
        ),

        // ── Chart type toggle ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ChartTypeToggle(
            selected: _type,
            accentColor: widget.accentColor,
            isAr: isAr,
            onChanged: (t) => setState(() => _type = t),
          ),
        ),

        const SizedBox(height: 0),

        // ── Chart / Table ─────────────────────────────────────────────
        if (_type == _ChartType.table) ...[
          // Table view (inside chart area, same padding as chart card)
          const SizedBox(height: 12),
          // Same chart-card title as Line / Bar, for consistency.
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 20, 10),
            child: Text(
              _chartCardTitle(isAr),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.slate600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DataTableCard(
                series: _tableSeries,
                isPercent: _isPercent,
                isDecimal: _isDecimal),
          ),
        ] else ...[
          // Line or Bar chart card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                boxShadow: AppColors.shadowCard,
              ),
              padding: const EdgeInsets.fromLTRB(10, 16, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      _chartCardTitle(isAr),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Chart
                  SizedBox(
                    height: 210,
                    child: _type == _ChartType.line
                        ? _buildLineChart()
                        : _buildBarChart(),
                  ),

                  // Gender legend (only for multi-series)
                  if (_hasGender && _type == _ChartType.line) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: widget.accentColor, label: isAr ? 'الإجمالي' : 'Total'),
                        const SizedBox(width: 14),
                        _LegendDot(color: const Color(0xFFC8973A), label: isAr ? 'إناث' : 'Female'),
                        const SizedBox(width: 14),
                        _LegendDot(color: const Color(0xFF1A6FA8), label: isAr ? 'ذكور' : 'Male'),
                      ],
                    ),
                  ],

                  // Range chips
                  const SizedBox(height: 14),
                  _RangeChips(
                    selected: _range,
                    visible: _visibleRanges,
                    accentColor: widget.accentColor,
                    isAr: isAr,
                    onChanged: (r) => setState(() => _range = r),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Y-axis interval helper ───────────────────────────────────────────────

  /// Computes a clean interval that yields ~4 labels for the given y-range.
  double _yInterval(double minY, double maxY) {
    final range = maxY - minY;
    if (range <= 0) return 1;
    final rawStep = range / 4;
    const steps = <double>[
      1, 2, 5, 10, 20, 25, 50, 100, 200, 250, 500,
      1000, 2000, 2500, 5000, 10000, 20000, 25000, 50000,
      100000, 200000, 250000, 500000,
      1e6, 2e6, 2.5e6, 5e6, 1e7, 2e7, 2.5e7, 5e7, 1e8,
    ];
    double best = steps.last;
    for (final s in steps) {
      if (s >= rawStep) { best = s; break; }
    }
    return best;
  }

  // ─── Line Chart ────────────────────────────────────────────────────────────

  Widget _buildLineChart() {
    // Line view is capped at 5 X-axis points to stay clutter-free.
    final series = _capForLine(_series);
    if (series.isEmpty) return const _EmptyChart();

    final fSeries = _capForLine(_slice(widget.femaleSeries));
    final mSeries = _capForLine(_slice(widget.maleSeries));

    List<FlSpot> toSpots(List<DataPoint> pts) => pts
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final spots = toSpots(series);
    final fSpots = toSpots(fSeries);
    final mSpots = toSpots(mSeries);

    final allValues = [
      ...series.map((p) => p.value),
      if (_hasGender) ...fSeries.map((p) => p.value),
      if (_hasGender) ...mSeries.map((p) => p.value),
    ];
    final minVal = allValues.reduce((a, b) => a < b ? a : b);
    final maxVal = allValues.reduce((a, b) => a > b ? a : b);
    final pad = (maxVal - minVal) * 0.15;
    final chartMinY = (minVal - pad).clamp(0.0, double.infinity);
    final chartMaxY = maxVal + pad;
    final yInterval = _yInterval(chartMinY.toDouble(), chartMaxY);

    LineChartBarData bar(List<FlSpot> s, Color c, {bool fill = false, bool dashed = false}) =>
        LineChartBarData(
          spots: s,
          isCurved: true,
          curveSmoothness: 0.35,
          color: c,
          barWidth: fill ? 3 : 2.5,
          isStrokeCapRound: true,
          dashArray: dashed ? [6, 3] : null,
          belowBarData: BarAreaData(
            show: fill,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.0)],
            ),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: fill ? 5 : 4,
              color: c,
              strokeWidth: 2,
              strokeColor: AppColors.white,
            ),
          ),
        );

    // Keep X bounds on exact integers so the bottom axis emits one tick per
    // year (0,1,2,…) — fractional bounds make fl_chart step ticks off-integer
    // and produced duplicate edge labels. clipData.none() lets the first/last
    // dot markers paint past the plot edge without being clipped, so we get the
    // breathing room without fractional padding.
    final lastX = (spots.length - 1).toDouble();
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: lastX,
        minY: chartMinY.toDouble(),
        maxY: chartMaxY,
        clipData: const FlClipData.none(),
        lineBarsData: [
          bar(spots, widget.accentColor, fill: true),
          if (_hasGender) bar(fSpots, const Color(0xFFC8973A), dashed: true),
          if (_hasGender) bar(mSpots, const Color(0xFF1A6FA8), dashed: true),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.pearlGray,
            strokeWidth: 1,
          ),
        ),
        // Restore the X (bottom) and Y (left) axis lines.
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: AppColors.silver, width: 1),
            bottom: BorderSide(color: AppColors.silver, width: 1),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: yInterval,
              getTitlesWidget: (val, meta) {
                // Skip labels that coincide with axis min/max to avoid clipping
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    _fmtValue(val),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, meta) {
                // The plot is padded (minX<0, maxX>lastX) so the dots aren't
                // clipped. fl_chart then emits fractional ticks at the padded
                // edges which round to the first/last index → duplicate year
                // labels (e.g. "2020 2020"). Render ONLY exact-integer ticks.
                if ((val - val.roundToDouble()).abs() > 0.001) {
                  return const SizedBox.shrink();
                }
                final idx = val.round();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    series[idx].timePeriod,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.white,
            tooltipRoundedRadius: 12,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            tooltipBorder:
                const BorderSide(color: AppColors.silver, width: 1),
            getTooltipItems: (spots) => spots.map((spot) {
              final idx = spot.x.round();
              if (idx < 0 || idx >= series.length) return null;
              final pt = series[idx];
              String deltaLine = '';
              if (idx > 0) {
                final prev = series[idx - 1];
                if (prev.value != 0) {
                  final delta =
                      ((pt.value - prev.value) / prev.value) * 100;
                  deltaLine =
                      '\n${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% vs ${prev.timePeriod}';
                }
              }
              return LineTooltipItem(
                pt.timePeriod,
                const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.04,
                ),
                children: [
                  TextSpan(
                    text: '\n${_fmtValueFull(pt.value)}',
                    style: const TextStyle(
                      color: AppColors.slate900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (deltaLine.isNotEmpty)
                    TextSpan(
                      text: deltaLine,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
    );
  }

  // ─── Bar Chart ─────────────────────────────────────────────────────────────

  Widget _buildBarChart() {
    final series = _series;
    if (series.isEmpty) return const _EmptyChart();

    final maxY = series.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final barW = _barWidth(series.length);
    final yInterval = _yInterval(0, maxY * 1.12);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.12,
        barGroups: series.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: widget.accentColor.withValues(alpha: 0.85),
                width: barW,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.pearlGray,
            strokeWidth: 1,
          ),
        ),
        // Restore the X (bottom) and Y (left) axis lines.
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: AppColors.silver, width: 1),
            bottom: BorderSide(color: AppColors.silver, width: 1),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: yInterval,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    _fmtValue(val),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text(
                    series[idx].timePeriod,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.white,
            tooltipRoundedRadius: 12,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            tooltipBorder:
                const BorderSide(color: AppColors.silver, width: 1),
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final pt = series[group.x];
              // YoY delta vs the previous year — mirrors the line tooltip.
              String deltaLine = '';
              if (group.x > 0) {
                final prev = series[group.x - 1];
                if (prev.value != 0) {
                  final delta = ((pt.value - prev.value) / prev.value) * 100;
                  deltaLine =
                      '\n${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}% vs ${prev.timePeriod}';
                }
              }
              return BarTooltipItem(
                '${pt.timePeriod}\n',
                const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: _fmtValueFull(pt.value),
                    style: const TextStyle(
                      color: AppColors.slate900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (deltaLine.isNotEmpty)
                    TextSpan(
                      text: deltaLine,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      duration: const Duration(milliseconds: 350),
    );
  }

  double _barWidth(int count) {
    if (count <= 3) return 44;
    if (count <= 5) return 32;
    if (count <= 8) return 22;
    if (count <= 10) return 16;
    return 12;
  }
}

// ─── Chart type toggle ────────────────────────────────────────────────────────

class _ChartTypeToggle extends StatelessWidget {
  const _ChartTypeToggle({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
    this.isAr = false,
  });
  final _ChartType selected;
  final Color accentColor;
  final ValueChanged<_ChartType> onChanged;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pearlGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            icon: Icons.show_chart_rounded,
            label: isAr ? 'خطي' : 'Line',
            active: selected == _ChartType.line,
            accentColor: accentColor,
            onTap: () => onChanged(_ChartType.line),
          ),
          const SizedBox(width: 3),
          _Tab(
            icon: Icons.bar_chart_rounded,
            label: isAr ? 'أعمدة' : 'Bar',
            active: selected == _ChartType.bar,
            accentColor: accentColor,
            onTap: () => onChanged(_ChartType.bar),
          ),
          const SizedBox(width: 3),
          _Tab(
            icon: Icons.table_rows_outlined,
            label: isAr ? 'جدول' : 'Table',
            active: selected == _ChartType.table,
            accentColor: accentColor,
            onTap: () => onChanged(_ChartType.table),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 36,
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: Color(0x1E0F172A),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? accentColor : AppColors.slate600,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? accentColor : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Range chips ──────────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  const _RangeChips({
    required this.selected,
    required this.accentColor,
    required this.onChanged,
    this.visible,
    this.isAr = false,
  });
  final _ChartRange selected;
  final Color accentColor;
  final ValueChanged<_ChartRange> onChanged;
  final List<_ChartRange>? visible;
  final bool isAr;

  String _label(_ChartRange r) => isAr
      ? switch (r) {
          _ChartRange.y3  => '٣ س',
          _ChartRange.y5  => '٥ س',
        }
      : r.label;

  @override
  Widget build(BuildContext context) {
    final ranges = visible ?? _ChartRange.values;
    // Horizontal segmented control: a single pearl-gray track with one
    // equal-width segment per range. The active segment fills with the accent.
    return Container(
      height: 36,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pearlGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final r in ranges) ...[
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(r),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 28,
                  decoration: BoxDecoration(
                    color: r == selected ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _label(r),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: r == selected
                          ? AppColors.white
                          : AppColors.slate600,
                    ),
                  ),
                ),
              ),
            ),
            if (r != ranges.last) const SizedBox(width: 3),
          ],
        ],
      ),
    );
  }
}

// ─── Inline data table (shown when Table tab is active) ───────────────────────

class _DataTableCard extends ConsumerWidget {
  const _DataTableCard(
      {required this.series, this.isPercent = false, this.isDecimal = false});
  final List<DataPoint> series;
  final bool isPercent;
  final bool isDecimal;

  String _fmtValueFull(double v) => isPercent
      ? '${v.toStringAsFixed(1)}%'
      : isDecimal
          ? v.toStringAsFixed(1)
          : NumberFormatter.full(v);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    // Show newest first
    final rows = series.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // Header
          Container(
            color: AppColors.pearlGray,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(isAr ? 'السنة' : 'YEAR',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.slate600)),
                ),
                Expanded(
                  child: Text(isAr ? 'القيمة' : 'VALUE',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.slate600)),
                ),
                SizedBox(
                  width: 72,
                  child: Text(isAr ? 'س/س' : 'YOY',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.slate600)),
                ),
              ],
            ),
          ),

          // Data rows
          ...rows.asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            // Find YoY (compare against NEXT item — which is previous year)
            double? yoy;
            if (idx < rows.length - 1) {
              final prevVal = rows[idx + 1].value;
              if (prevVal != 0) {
                yoy = ((pt.value - prevVal) / prevVal) * 100;
              }
            }

            return Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      pt.timePeriod,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _fmtValueFull(pt.value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    child: Center(
                      child: yoy == null
                          ? const Text('—',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.slate400))
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: yoy >= 0
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${yoy >= 0 ? '↑' : '↓'} ${yoy.abs().round()}%',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
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

// ─── Legend dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate600)),
      ],
    );
  }
}

// ─── Empty chart ──────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No data available',
        style: TextStyle(color: AppColors.slate400, fontSize: 14),
      ),
    );
  }
}
