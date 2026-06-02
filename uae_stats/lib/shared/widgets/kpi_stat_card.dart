// lib/shared/widgets/kpi_stat_card.dart
//
// Light-theme KPI stat cards — matches the _Tile style from home_screen.dart.
// Used by Economy, Demography, and Environment section screens.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/kpi_card_data.dart';

// Indicator IDs that have a live detail page.
const _kNavigableIds = {
  'population',
  'births',
  'population_growth',
  'hospitals',
  'clinics_centers',
  'health_clinics_centers',
  'health_hospital_beds',
  'health_professionals',
};

// ─── 2-column grid card ───────────────────────────────────────────────────────

class KpiStatCard extends StatelessWidget {
  const KpiStatCard({
    super.key,
    required this.data,
    required this.accentColor,
    required this.accentBg,
    this.isArabic = false,
    this.onTap,
  });

  final KpiCardData data;
  final Color accentColor;
  final Color accentBg;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = isArabic ? data.nameAr : data.nameEn;
    final unit = isArabic ? data.unitAr : data.unitEn;

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon badge row ───────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: data.icon != null
                    ? Icon(data.icon, size: 16, color: accentColor)
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: accentColor.withValues(alpha: 0.5)),
            ],
          ),
          const Spacer(),
          // ── KPI name ─────────────────────────────────────────────────────
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit.isNotEmpty ? '$unit · ${data.year}' : data.year,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 4),
          // ── Value + sparkline row ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    data.isLoading
                        ? _ShimmerBar(color: accentColor)
                        : Text(
                            data.displayValue,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                              height: 1.1,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                    if (data.trendPercent != null && !data.isLoading) ...[
                      const SizedBox(height: 4),
                      _TrendRow(percent: data.trendPercent!),
                    ],
                  ],
                ),
              ),
              if (data.sparklinePoints.isNotEmpty && !data.isLoading)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: SizedBox(
                    width: 52,
                    height: 32,
                    child: CustomPaint(
                      painter: _KpiSparklinePainter(
                        points: data.sparklinePoints,
                        isUp: (data.trendPercent ?? 0) >= 0,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

// ─── Full-width lone card ─────────────────────────────────────────────────────

class KpiStatCardWide extends StatelessWidget {
  const KpiStatCardWide({
    super.key,
    required this.data,
    required this.accentColor,
    required this.accentBg,
    this.isArabic = false,
    this.onTap,
  });

  final KpiCardData data;
  final Color accentColor;
  final Color accentBg;
  final bool isArabic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = isArabic ? data.nameAr : data.nameEn;
    final unit = isArabic ? data.unitAr : data.unitEn;

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: data.icon != null
                ? Icon(data.icon, size: 20, color: accentColor)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  unit.isNotEmpty ? '$unit · ${data.year}' : data.year,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 6),
                data.isLoading
                    ? _ShimmerBar(color: accentColor, height: 26, width: 100)
                    : Text(
                        data.displayValue,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                if (data.trendPercent != null && !data.isLoading) ...[
                  const SizedBox(height: 4),
                  _TrendRow(percent: data.trendPercent!),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: accentColor.withValues(alpha: 0.5)),
          ],
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class KpiSectionTitle extends StatelessWidget {
  const KpiSectionTitle({
    super.key,
    required this.titleEn,
    required this.titleAr,
    this.isArabic = false,
  });

  final String titleEn;
  final String titleAr;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        isArabic ? titleAr : titleEn,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ─── 2-column grid ────────────────────────────────────────────────────────────

class KpiCardGrid extends StatelessWidget {
  const KpiCardGrid({
    super.key,
    required this.cards,
    required this.accentColor,
    required this.accentBg,
    this.isArabic = false,
  });

  final List<KpiCardData> cards;
  final Color accentColor;
  final Color accentBg;
  final bool isArabic;

  VoidCallback? _tapFor(BuildContext context, String id) {
    if (!_kNavigableIds.contains(id)) return null;
    return switch (id) {
      'population_growth' => () => context.push(AppRoutes.populationGrowth),
      'clinics_centers' => () =>
          context.push(AppRoutes.indicatorPath('health_clinics_centers')),
      _ => () => context.push(AppRoutes.indicatorPath(id)),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += 2) {
      final a = cards[i];
      final b = (i + 1 < cards.length) ? cards[i + 1] : null;

      if (b == null) {
        rows.add(KpiStatCardWide(
          data: a,
          accentColor: accentColor,
          accentBg: accentBg,
          isArabic: isArabic,
          onTap: _tapFor(context, a.id),
        ));
      } else {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: KpiStatCard(
                    data: a,
                    accentColor: accentColor,
                    accentBg: accentBg,
                    isArabic: isArabic,
                    onTap: _tapFor(context, a.id),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: KpiStatCard(
                    data: b,
                    accentColor: accentColor,
                    accentBg: accentBg,
                    isArabic: isArabic,
                    onTap: _tapFor(context, b.id),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (i + 2 < cards.length) rows.add(const SizedBox(height: 10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────

class _ShimmerBar extends StatefulWidget {
  const _ShimmerBar({required this.color, this.height = 22, this.width = 72});
  final Color color;
  final double height;
  final double width;

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 0.40).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

// ─── Trend row ────────────────────────────────────────────────────────────────

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    final icon =
        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          '${isUp ? '+' : ''}${percent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─── Sparkline painter ────────────────────────────────────────────────────────

class _KpiSparklinePainter extends CustomPainter {
  const _KpiSparklinePainter({
    required this.points,
    required this.isUp,
    required this.color,
  });
  final List<double> points;
  final bool isUp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - points[i] * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _KpiSparklinePainter old) =>
      old.points != points || old.isUp != isUp;
}
