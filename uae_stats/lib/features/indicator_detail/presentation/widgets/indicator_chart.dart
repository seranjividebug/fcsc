// lib/features/indicator_detail/presentation/widgets/indicator_chart.dart
//
// Chart section for the Indicator Detail screen.
// Manages: ChartType (line/bar/table) × ChartRange (2Y/5Y/10Y/MAX).
// Uses fl_chart for line and bar rendering.
// Data table rendered natively (Flutter Table widget).

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';

enum _ChartType { line, bar, table }

enum _ChartRange { y3, y5, y10, max }

extension _RangeLabel on _ChartRange {
  String get label => switch (this) {
        _ChartRange.y3  => '3Y',
        _ChartRange.y5  => '5Y',
        _ChartRange.y10 => '10Y',
        _ChartRange.max => 'MAX',
      };

  int? get years => switch (this) {
        _ChartRange.y3  => 3,
        _ChartRange.y5  => 5,
        _ChartRange.y10 => 10,
        _ChartRange.max => null,
      };
}

class IndicatorChart extends StatefulWidget {
  const IndicatorChart({
    super.key,
    required this.allSeries,
    required this.indicatorName,
    this.indicatorId = '',
    this.unitCode = 'PS',
    this.accentColor = AppColors.demBlue,
    this.femaleSeries = const [],
    this.maleSeries = const [],
  });

  final List<DataPoint> allSeries;
  final String indicatorName;
  final String indicatorId;
  final String unitCode;
  final Color accentColor;
  final List<DataPoint> femaleSeries;
  final List<DataPoint> maleSeries;

  @override
  State<IndicatorChart> createState() => _IndicatorChartState();
}

class _IndicatorChartState extends State<IndicatorChart> {
  _ChartType _type = _ChartType.line;
  late _ChartRange _range;

  @override
  void initState() {
    super.initState();
    _range = _defaultRange;
  }

  // Indicators with long history use 10Y default; short data uses 3Y; rest 5Y
  _ChartRange get _defaultRange {
    final id = widget.indicatorId;
    final n = widget.allSeries.length;
    if (id == 'health_hospital_beds' || id == 'health_clinics_centers' ||
        id == 'hospitals') return _ChartRange.y10;
    if (id == 'health_professionals') return _ChartRange.max;
    if (n <= 3) return _ChartRange.y3;
    return _ChartRange.y5;
  }

  // Which range chips to show based on data length
  List<_ChartRange> get _visibleRanges {
    final n = widget.allSeries.length;
    if (n <= 3) return [_ChartRange.y3, _ChartRange.max];
    if (n <= 5) return [_ChartRange.y3, _ChartRange.y5, _ChartRange.max];
    if (n >= 10) return [_ChartRange.y5, _ChartRange.y10, _ChartRange.max];
    return [_ChartRange.y3, _ChartRange.y5, _ChartRange.max];
  }

  // Section title based on indicator type
  String get _sectionTitle {
    final id = widget.indicatorId;
    if (id == 'health_hospital_beds' || id == 'hospitals') return 'Historical Trend';
    if (id == 'health_clinics_centers') return 'Growth Trend';
    if (id == 'health_professionals') return 'Workforce Trend';
    final n = widget.allSeries.length;
    if (n <= 3) return '3-Year Trend';
    return '5-Year Trend';
  }

  bool get _hasGender =>
      widget.femaleSeries.isNotEmpty && widget.maleSeries.isNotEmpty;

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

  String get _chartSubLabel {
    final s = _series;
    if (s.isEmpty) return '';
    final genderTag = _hasGender ? ' · By Gender' : '';
    return '${s.first.timePeriod} — ${s.last.timePeriod} · Source: FCSC$genderTag';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _sectionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.slate900,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(Icons.open_in_full_rounded,
                        size: 17, color: AppColors.slate600),
                    SizedBox(width: 4),
                    Text(
                      'Expand',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Chart type toggle ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ChartTypeToggle(
            selected: _type,
            accentColor: widget.accentColor,
            onChanged: (t) => setState(() => _type = t),
          ),
        ),

        const SizedBox(height: 0),

        // ── Chart / Table ─────────────────────────────────────────────
        if (_type == _ChartType.table) ...[
          // Table view (inside chart area, same padding as chart card)
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _DataTableCard(series: _series),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Annual ${widget.indicatorName} in the UAE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _chartSubLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.slate400),
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
                        _LegendDot(color: widget.accentColor, label: 'Total'),
                        const SizedBox(width: 14),
                        _LegendDot(color: const Color(0xFFC8973A), label: 'Female'),
                        const SizedBox(width: 14),
                        _LegendDot(color: const Color(0xFF1A6FA8), label: 'Male'),
                      ],
                    ),
                  ],

                  // Range chips
                  const SizedBox(height: 14),
                  _RangeChips(
                    selected: _range,
                    visible: _visibleRanges,
                    accentColor: widget.accentColor,
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

  // ─── Line Chart ────────────────────────────────────────────────────────────

  Widget _buildLineChart() {
    final series = _series;
    if (series.isEmpty) return const _EmptyChart();

    final fSeries = _slice(widget.femaleSeries);
    final mSeries = _slice(widget.maleSeries);

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
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.12;

    LineChartBarData _bar(List<FlSpot> s, Color c, {bool fill = false, bool dashed = false}) =>
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

    return LineChart(
      LineChartData(
        minY: (minY - pad).clamp(0, double.infinity),
        maxY: maxY + pad,
        clipData: const FlClipData.all(),
        lineBarsData: [
          _bar(spots, widget.accentColor, fill: true),
          if (_hasGender) _bar(fSpots, const Color(0xFFC8973A), dashed: true),
          if (_hasGender) _bar(mSpots, const Color(0xFF1A6FA8), dashed: true),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.pearlGray,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  NumberFormatter.compact(val),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.slate400),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
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
                    text: '\n${NumberFormatter.full(pt.value)}',
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
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.pearlGray,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (val, meta) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  NumberFormatter.compact(val),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.slate400),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.round();
                if (idx < 0 || idx >= series.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
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
              return BarTooltipItem(
                '${pt.timePeriod}\n',
                const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: NumberFormatter.full(pt.value),
                    style: const TextStyle(
                      color: AppColors.slate900,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
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
  });
  final _ChartType selected;
  final Color accentColor;
  final ValueChanged<_ChartType> onChanged;

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
            label: 'Line',
            active: selected == _ChartType.line,
            accentColor: accentColor,
            onTap: () => onChanged(_ChartType.line),
          ),
          const SizedBox(width: 3),
          _Tab(
            icon: Icons.bar_chart_rounded,
            label: 'Bar',
            active: selected == _ChartType.bar,
            accentColor: accentColor,
            onTap: () => onChanged(_ChartType.bar),
          ),
          const SizedBox(width: 3),
          _Tab(
            icon: Icons.table_rows_outlined,
            label: 'Table',
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
  });
  final _ChartRange selected;
  final Color accentColor;
  final ValueChanged<_ChartRange> onChanged;
  final List<_ChartRange>? visible;

  @override
  Widget build(BuildContext context) {
    final ranges = visible ?? _ChartRange.values;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: ranges.map((r) {
        final active = r == selected;
        return GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: active ? accentColor : AppColors.pearlGray,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              r.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.white : AppColors.slate600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Inline data table (shown when Table tab is active) ───────────────────────

class _DataTableCard extends StatelessWidget {
  const _DataTableCard({required this.series});
  final List<DataPoint> series;

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text('YEAR',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.slate600)),
                ),
                Expanded(
                  child: Text('VALUE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.44,
                          color: AppColors.slate600)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('YOY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                      NumberFormatter.full(pt.value),
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
                    width: 60,
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
