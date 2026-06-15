// lib/shared/widgets/trend_pill.dart

import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';

enum TrendDirection { up, down, flat }

/// Small pill showing YoY change with directional arrow and colour coding.
/// Up = green, Down = red, Flat = gray.
class TrendPill extends StatelessWidget {
  const TrendPill({
    super.key,
    required this.value,
    this.compact = false,
  });

  /// The YoY percentage change (e.g. 2.3 = +2.3%).
  final double value;

  /// If true, renders in a smaller size for tiles/sheet rows.
  final bool compact;

  TrendDirection get _direction {
    if (value > 0.05) return TrendDirection.up;
    if (value < -0.05) return TrendDirection.down;
    return TrendDirection.flat;
  }

  Color get _bgColor => switch (_direction) {
        TrendDirection.up => AppColors.successBg,
        TrendDirection.down => AppColors.errorBg,
        TrendDirection.flat => AppColors.pearlGray,
      };

  Color get _fgColor => switch (_direction) {
        TrendDirection.up => AppColors.success,
        TrendDirection.down => AppColors.error,
        TrendDirection.flat => AppColors.slate400,
      };

  IconData get _icon => switch (_direction) {
        TrendDirection.up => Icons.arrow_upward_rounded,
        TrendDirection.down => Icons.arrow_downward_rounded,
        TrendDirection.flat => Icons.remove_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 10.0 : 11.0;
    final iconSize = compact ? 10.0 : 11.0;
    final hPad = compact ? 6.0 : 8.0;
    final vPad = compact ? 2.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_direction != TrendDirection.flat) ...[
            Icon(_icon, size: iconSize, color: _fgColor),
            const SizedBox(width: 2),
          ],
          Text(
            NumberFormatter.percentNoSign(value),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: _fgColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline trend text for hero card (white on green).
class HeroTrendPill extends StatelessWidget {
  const HeroTrendPill({
    super.key,
    required this.value,
    required this.vsLabel,
    this.pointDelta = false,
  });

  final double value;
  final String vsLabel;

  /// When true, renders a percentage-POINT delta ("+10.3 pp") instead of a
  /// percent change ("+10.3%").
  final bool pointDelta;

  /// Value snapped to 0 when it would round to 0.0 at one decimal — avoids a
  /// misleading "−0.0%" / "+0.0%" when there is effectively no change.
  double get _rounded {
    final r = double.parse(value.toStringAsFixed(1));
    return r == 0 ? 0.0 : r;
  }

  String get _text {
    final v = _rounded;
    final sign = v > 0 ? '+' : (v < 0 ? '−' : '');
    if (pointDelta) {
      return '$sign${v.abs().toStringAsFixed(1)} pp';
    }
    if (v == 0) return '0.0%';
    return NumberFormatter.percent(v);
  }

  TrendDirection get _direction {
    final v = _rounded;
    if (v > 0) return TrendDirection.up;
    if (v < 0) return TrendDirection.down;
    return TrendDirection.flat;
  }

  IconData get _icon => switch (_direction) {
        TrendDirection.up => Icons.arrow_upward_rounded,
        TrendDirection.down => Icons.arrow_downward_rounded,
        TrendDirection.flat => Icons.remove_rounded,
      };

  // Solid light pill (green / red / grey) with strong colored text + arrow —
  // a clean, high-contrast badge that reads on the dark hero. Up = green,
  // Down = red, Flat = grey.
  Color get _bg => switch (_direction) {
        TrendDirection.up => const Color(0xFFE7F8EF),   // light green
        TrendDirection.down => const Color(0xFFFDECEC), // light red/pink
        TrendDirection.flat => const Color(0xFFEFF1F4), // light grey
      };

  Color get _fg => switch (_direction) {
        TrendDirection.up => const Color(0xFF059669),   // green
        TrendDirection.down => const Color(0xFFDC2626), // red
        TrendDirection.flat => AppColors.slate600,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // No arrow/dash glyph when flat — a "−" before "0.0%" misreads as a
          // negative value when there is no change.
          if (_direction != TrendDirection.flat) ...[
            Icon(_icon, size: 14, color: _fg),
            const SizedBox(width: 4),
          ],
          Text(
            _text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _fg,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            vsLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
