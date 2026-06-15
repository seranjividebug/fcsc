// lib/core/utils/number_formatter.dart

import 'package:intl/intl.dart';

/// Formats numbers in UAE Stats style with locale awareness.
abstract final class NumberFormatter {
  // ─── Compact display (for KPI cards, tiles) ───────────────────────────────

  /// e.g. 9861007 → "9.86M"  |  142000000 → "142M"  |  97290 → "97,290"
  static String compact(double value, {String locale = 'en'}) {
    if (value.abs() >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value.abs() >= 1e6) {
      final d = value / 1e6;
      return '${d % 1 == 0 ? d.toInt() : d.toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      return NumberFormat('#,##0', locale).format(value.toInt());
    }
    return value.toStringAsFixed(0);
  }

  /// Compact axis-tick label — ALWAYS uses K/M/B notation so chart axis
  /// labels never wrap or clip on narrow mobile screens.
  /// e.g. 9000 → "9K"  |  9500 → "9.5K"  |  105000 → "105K"  |  2.03e6 → "2M"
  static String axisTick(double value) {
    final v = value.abs();
    String trim(double d) =>
        d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
    if (v >= 1e9) return '${trim(value / 1e9)}B';
    if (v >= 1e6) return '${trim(value / 1e6)}M';
    if (v >= 1e3) return '${trim(value / 1e3)}K';
    return value.toStringAsFixed(0);
  }

  /// For population: 9861007 → "9.86M" or full "9,861,007"
  static String population(double value, {String locale = 'en'}) {
    if (value >= 1e6) {
      final m = value / 1e6;
      final formatted = m.toStringAsFixed(2);
      return '${formatted}M';
    }
    return NumberFormat('#,##0', locale).format(value.toInt());
  }

  /// Full comma-separated number: 106915 → "106,915"
  static String full(double value, {String locale = 'en'}) {
    return NumberFormat('#,##0', locale).format(value.toInt());
  }

  /// Full with decimal: 3.64 → "3.64"
  static String decimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }

  // ─── Percentage ──────────────────────────────────────────────────────────

  /// e.g. 2.3 → "+2.3%"  |  -1.5 → "-1.5%"
  static String percent(double value, {bool showSign = true}) {
    final abs = value.abs().toStringAsFixed(1);
    if (showSign && value > 0) return '+$abs%';
    if (value < 0) return '-$abs%';
    return '$abs%';
  }

  /// e.g. 2.3 → "2.3%"
  static String percentNoSign(double value) {
    return '${value.abs().toStringAsFixed(1)}%';
  }

  // ─── AED Millions formatting (GDP / National Accounts) ───────────────────

  /// GDP-style: 2028413 → "2,028,413 Mn AED"  compact → "2.03T AED"
  static String aedMillionsCompact(double value) {
    // value is already in AED Millions
    if (value.abs() >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)}T';
    } else if (value.abs() >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}B';
    }
    return NumberFormat('#,##0', 'en').format(value.toInt());
  }

  // ─── AED formatting ──────────────────────────────────────────────────────

  /// e.g. 1527812637140 → "AED 1.53T"
  static String aed(double value, {String locale = 'en'}) {
    if (value.abs() >= 1e12) {
      return 'AED ${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value.abs() >= 1e9) {
      return 'AED ${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value.abs() >= 1e6) {
      return 'AED ${(value / 1e6).toStringAsFixed(0)}M';
    }
    return 'AED ${NumberFormat('#,##0', locale).format(value.toInt())}';
  }

  // ─── Year-on-year change ─────────────────────────────────────────────────

  /// Calculates YoY % change between two values.
  static double yoyChange(double current, double previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  /// "vs 2023" style label.
  static String vsYear(int year) => 'vs $year';

  // ─── Sparkline normalisation ──────────────────────────────────────────────

  /// Normalises a list of values to 0.0–1.0 range for sparkline rendering.
  static List<double> normalise(List<double> values) {
    if (values.isEmpty) return [];
    final mn = values.reduce((a, b) => a < b ? a : b);
    final mx = values.reduce((a, b) => a > b ? a : b);
    final range = mx - mn;
    if (range == 0) return values.map((_) => 0.5).toList();
    return values.map((v) => (v - mn) / range).toList();
  }
}
