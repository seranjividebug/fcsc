// lib/data/models/kpi_card_data.dart
//
// Lightweight display model for a single KPI statistic card.
// Used by Economy, Demography, and Environment section screens.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// How the raw numeric value is formatted for display.
enum KpiDisplayUnit {
  /// Divide by 1e12 → e.g. 1,680,000,000,000 → "1.68T"
  aedTrillions,

  /// Divide by 1e9  → e.g. 450,000,000 → "0.45B"
  aedBillions,

  /// Divide by 1e6  → e.g. 10,680,000 → "10.68M"
  millions,

  /// Divide by 1e3  → e.g. 17,650 → "17.65K"
  thousands,

  /// Full integer with comma separator → e.g. 5,599 → "5,599"
  integer,

  /// Percentage with 2 decimal places → e.g. 1.63 → "1.63%"
  percent,

  /// One decimal place → e.g. 21.8 → "21.8"
  decimal1,

  /// Two decimal places → e.g. 89.85 → "89.85"
  decimal2,

  /// Value is in AED Millions, display as Trillions → 2,028,413 → "2.03T"
  aedMnToTrillions,
}

/// Configuration for a single KPI card (static, compile-time definition).
class KpiConfig {
  const KpiConfig({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.unitEn,
    required this.unitAr,
    required this.displayUnit,
    required this.icon,
    this.dataflowId,
    this.dataflowVersion = '1.0.0',
    this.filter = '....A',
    this.measure,
    this.startPeriod = '2018',
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String unitEn;
  final String unitAr;

  /// Material icon shown in the card's icon badge.
  final IconData icon;

  /// How to format the raw value for display.
  final KpiDisplayUnit displayUnit;

  /// SDMX dataflow ID (null = no live API for this KPI).
  final String? dataflowId;
  final String dataflowVersion;

  /// SDMX filter key, e.g. "....A" for annual UAE total.
  final String filter;

  /// Optional MEASURE dimension code to filter on (e.g. "POPGWTH").
  final String? measure;

  /// Earliest year to request from the API (passed as startPeriod query param).
  final String startPeriod;
}

/// Runtime display data for a KPI card — produced by the provider layer.
class KpiCardData {
  const KpiCardData({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.displayValue,
    required this.unitEn,
    required this.unitAr,
    required this.year,
    this.trendPercent,
    this.isLoading = false,
    this.fromCache = false,
    this.icon,
    this.sparklinePoints = const [],
  });

  final String id;
  final String nameEn;
  final String nameAr;

  /// Pre-formatted string ready for display, e.g. "1.68T", "25.22M", "1.63%".
  final String displayValue;

  final String unitEn;
  final String unitAr;

  /// The year / period label, e.g. "2023", "Q2-2024".
  final String year;

  /// YoY percentage change (null = not computed).
  final double? trendPercent;

  final bool isLoading;
  final bool fromCache;

  /// Material icon for the card's icon badge (null in loading skeletons).
  final IconData? icon;

  /// Normalized 0.0–1.0 sparkline points (empty = no sparkline).
  final List<double> sparklinePoints;

  // ─── Loading placeholder ─────────────────────────────────────────────────

  factory KpiCardData.loading(KpiConfig cfg) => KpiCardData(
        id: cfg.id,
        nameEn: cfg.nameEn,
        nameAr: cfg.nameAr,
        displayValue: '—',
        unitEn: cfg.unitEn,
        unitAr: cfg.unitAr,
        year: '—',
        isLoading: true,
        icon: cfg.icon,
      );

  // ─── Live value ──────────────────────────────────────────────────────────

  factory KpiCardData.fromLive({
    required KpiConfig cfg,
    required double value,
    required String year,
    double? trendPercent,
    bool fromCache = false,
    List<double> sparklinePoints = const [],
  }) =>
      KpiCardData(
        id: cfg.id,
        nameEn: cfg.nameEn,
        nameAr: cfg.nameAr,
        displayValue: KpiCardData.format(value, cfg.displayUnit),
        unitEn: cfg.unitEn,
        unitAr: cfg.unitAr,
        year: year,
        trendPercent: trendPercent,
        fromCache: fromCache,
        icon: cfg.icon,
        sparklinePoints: sparklinePoints,
      );

  // ─── Formatting ──────────────────────────────────────────────────────────

  static String format(double v, KpiDisplayUnit unit) {
    switch (unit) {
      case KpiDisplayUnit.aedTrillions:
        // Auto-scale: API may return raw AED, millions, or billions
        final abs = v.abs();
        if (abs >= 1e12) return '${(v / 1e12).toStringAsFixed(2)}T';
        if (abs >= 1e9)  return '${(v / 1e9).toStringAsFixed(2)}B';
        if (abs >= 1e6)  return '${(v / 1e6).toStringAsFixed(2)}M';
        if (abs >= 1e3)  return '${(v / 1e3).toStringAsFixed(2)}K';
        return v.toStringAsFixed(2);
      case KpiDisplayUnit.aedBillions:
        final abs = v.abs();
        if (abs >= 1e9)  return '${(v / 1e9).toStringAsFixed(2)}B';
        if (abs >= 1e6)  return '${(v / 1e6).toStringAsFixed(2)}M';
        if (abs >= 1e3)  return '${(v / 1e3).toStringAsFixed(2)}K';
        return v.toStringAsFixed(2);
      case KpiDisplayUnit.millions:
        final abs = v.abs();
        if (abs >= 1e6)  return '${(v / 1e6).toStringAsFixed(2)}M';
        if (abs >= 1e3)  return '${(v / 1e3).toStringAsFixed(2)}K';
        return v.toStringAsFixed(2);
      case KpiDisplayUnit.thousands:
        final abs = v.abs();
        if (abs >= 1e6)  return '${(v / 1e6).toStringAsFixed(2)}M';
        if (abs >= 1e3)  return '${(v / 1e3).toStringAsFixed(2)}K';
        return v.toStringAsFixed(2);
      case KpiDisplayUnit.integer:
        return NumberFormat('#,##0').format(v.toInt());
      case KpiDisplayUnit.percent:
        return '${v.toStringAsFixed(2)}%';
      case KpiDisplayUnit.decimal1:
        return v.toStringAsFixed(1);
      case KpiDisplayUnit.decimal2:
        return v.toStringAsFixed(2);
      case KpiDisplayUnit.aedMnToTrillions:
        // Value is in AED Millions — divide by 1,000,000 to get Trillions
        final t = v / 1e6;
        if (t >= 1) return '${t.toStringAsFixed(2)}T';
        return '${(v / 1e3).toStringAsFixed(2)}B';
    }
  }
}
