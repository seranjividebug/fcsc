// lib/data/models/indicator_summary.dart
//
// Lightweight snapshot of an indicator used by:
//  • Home screen KPI cards
//  • Sub-category tiles (Variant A)
//  • Bottom sheet indicator rows

import 'package:uae_stats/data/models/localized_string.dart';
import 'package:uae_stats/shared/widgets/trend_pill.dart';

/// Compact view of an indicator's latest value, for tiles and summary cards.
class IndicatorSummary {
  const IndicatorSummary({
    required this.id,
    required this.name,
    required this.latestValue,
    required this.latestPeriod,
    required this.yoyChange,
    required this.trend,
    required this.sparklineValues,
    required this.unitCode,
    this.comingSoon = false,
  });

  final String id;
  final LocalizedString name;
  final double latestValue;

  /// e.g. "2024", "Q1 2026".
  final String latestPeriod;

  /// YoY change in percent, e.g. 2.3 = +2.3%.
  final double yoyChange;

  final TrendDirection trend;

  /// Normalised 0.0–1.0 values for the mini sparkline (last ≤ 5 points).
  final List<double> sparklineValues;

  final String unitCode;
  final bool comingSoon;

  // ─── Factory from a sorted list of DataPoints ─────────────────────────────

  static IndicatorSummary fromDataPoints({
    required String id,
    required LocalizedString name,
    required List<double> sortedValues, // oldest → newest
    required List<String> sortedPeriods,
    required String unitCode,
    bool comingSoon = false,
  }) {
    if (sortedValues.isEmpty) {
      return IndicatorSummary(
        id: id,
        name: name,
        latestValue: 0,
        latestPeriod: '—',
        yoyChange: 0,
        trend: TrendDirection.flat,
        sparklineValues: const [],
        unitCode: unitCode,
        comingSoon: comingSoon,
      );
    }

    final latest = sortedValues.last;
    final latestPeriod = sortedPeriods.last;

    double yoy = 0;
    TrendDirection trend = TrendDirection.flat;
    if (sortedValues.length >= 2) {
      final prev = sortedValues[sortedValues.length - 2];
      if (prev != 0) {
        yoy = ((latest - prev) / prev) * 100;
        if (yoy > 0.05) trend = TrendDirection.up;
        if (yoy < -0.05) trend = TrendDirection.down;
      }
    }

    // Normalise last 5 values for sparkline
    final raw = sortedValues.length > 5
        ? sortedValues.sublist(sortedValues.length - 5)
        : sortedValues;
    final mn = raw.reduce((a, b) => a < b ? a : b);
    final mx = raw.reduce((a, b) => a > b ? a : b);
    final range = mx - mn;
    final normalised = range == 0
        ? raw.map((_) => 0.5).toList()
        : raw.map((v) => (v - mn) / range).toList();

    return IndicatorSummary(
      id: id,
      name: name,
      latestValue: latest,
      latestPeriod: latestPeriod,
      yoyChange: yoy,
      trend: trend,
      sparklineValues: normalised,
      unitCode: unitCode,
      comingSoon: comingSoon,
    );
  }

  @override
  String toString() =>
      'IndicatorSummary($id, $latestValue, $latestPeriod, yoy:$yoyChange%)';
}
