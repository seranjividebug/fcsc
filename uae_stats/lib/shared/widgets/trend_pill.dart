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
          Icon(_icon, size: iconSize, color: _fgColor),
          const SizedBox(width: 2),
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
  });

  final double value;
  final String vsLabel;

  TrendDirection get _direction {
    if (value > 0) return TrendDirection.up;
    if (value < 0) return TrendDirection.down;
    return TrendDirection.flat;
  }

  IconData get _icon => switch (_direction) {
        TrendDirection.up => Icons.arrow_upward_rounded,
        TrendDirection.down => Icons.arrow_downward_rounded,
        TrendDirection.flat => Icons.remove_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            NumberFormatter.percent(value),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            vsLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
