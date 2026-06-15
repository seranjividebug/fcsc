// lib/data/models/home_kpi_item.dart
//
// Display model for a single home-screen KPI carousel card.
// Carries pre-formatted strings and normalized sparkline data.

import 'package:flutter/material.dart';

/// Normalize raw values to the 0.0–1.0 range for sparkline rendering.
List<double> normalizePoints(List<double> raw) {
  if (raw.length < 2) return raw.map((_) => 0.5).toList();
  final min = raw.reduce((a, b) => a < b ? a : b);
  final max = raw.reduce((a, b) => a > b ? a : b);
  if (max == min) return raw.map((_) => 0.5).toList();
  return raw.map((v) => (v - min) / (max - min)).toList();
}

class HomeKpiItem {
  const HomeKpiItem({
    required this.category,
    required this.label,
    required this.displayValue,
    required this.year,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.categoryColor,
    this.trendPercent,
    this.sparklinePoints = const [],
    this.isLoading = false,
    this.valueUnit = '',
  });

  final String category;
  final String label;

  /// Pre-formatted display string, e.g. "10.68M", "1.63%".
  final String displayValue;

  /// Small unit suffix rendered next to [displayValue] (e.g. "GWh"). Empty
  /// when the unit lives in the title instead.
  final String valueUnit;

  /// Period label derived from API, e.g. "2024", "2023".
  final String year;

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color categoryColor;

  /// YoY percentage change; null when unavailable.
  final double? trendPercent;

  /// Normalized (0.0–1.0) values in chronological order for sparkline.
  final List<double> sparklinePoints;

  final bool isLoading;

  bool get isUp => (trendPercent ?? 0) >= 0;

  factory HomeKpiItem.loading({
    required String category,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color categoryColor,
  }) =>
      HomeKpiItem(
        category: category,
        label: label,
        displayValue: '—',
        year: '—',
        icon: icon,
        iconColor: iconColor,
        iconBg: iconBg,
        categoryColor: categoryColor,
        isLoading: true,
      );
}
