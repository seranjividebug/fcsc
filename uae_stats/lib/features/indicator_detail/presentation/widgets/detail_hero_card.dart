// lib/features/indicator_detail/presentation/widgets/detail_hero_card.dart
//
// Hero value card on the Indicator Detail screen.
// Design: gradient(135deg, #00594C, #003D33), radius 24, padding 24, min-height 200.
// Includes: Islamic pattern overlay (6% opacity), pulsing live dot,
//           category tag, name (22px), BIG value (58px animated), period,
//           trend pill (white/15% bg, backdropFilter blur), trending-up gold icon.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';

class DetailHeroCard extends StatefulWidget {
  const DetailHeroCard({super.key, required this.data});
  final IndicatorData data;

  @override
  State<DetailHeroCard> createState() => _DetailHeroCardState();
}

class _DetailHeroCardState extends State<DetailHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Derived display strings ─────────────────────────────────────────────

  String get _categoryTag =>
      '${_cap(widget.data.meta.category)} · ${_cap(widget.data.meta.subCategory)}'.toUpperCase();

  String get _period => widget.data.latestPeriod;

  String get _subtitle => _subtitleFor(widget.data.meta.id, _period);

  double get _value => widget.data.latestValue;

  double get _yoy {
    final series = widget.data.uaeTotalSeries;
    if (series.length < 2) return 0;
    final prev = series[series.length - 2].value;
    if (prev == 0) return 0;
    return ((_value - prev) / prev) * 100;
  }

  String get _vsLabel {
    final series = widget.data.uaeTotalSeries;
    if (series.length < 2) return '';
    return 'vs ${series[series.length - 2].timePeriod}';
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  static String _subtitleFor(String id, String period) => switch (id) {
        'births' => 'live births registered in $period',
        'population' => 'estimated residents in UAE',
        'deaths' => 'deaths registered in $period',
        'marriages' => 'marriages registered in $period',
        'divorces' => 'divorces registered in $period',
        _ => 'as of $period',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 1.0],
            colors: [AppColors.emiratesGreen, AppColors.deepForest],
          ),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        constraints: const BoxConstraints(minHeight: 200),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Islamic pattern overlay ─────────────────────────────────
            const Positioned(
              top: -10,
              right: -10,
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  size: Size(220, 220),
                  painter: _GeoPainter(),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category tag + live indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _categoryTag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.08 * 10,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pulsing live dot
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, __) => Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4ADE80)
                                        .withValues(alpha: 0.25 * _pulse.value),
                                    blurRadius: 6,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.data.fromCache
                                ? 'Cached data'
                                : 'Live · ${_fmtDate(widget.data.fetchedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Indicator name
                  Text(
                    widget.data.meta.name.en,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── BIG animated value ─────────────────────────────────
                  TweenAnimationBuilder<double>(
                    key: ValueKey('${widget.data.meta.id}_$_value'),
                    tween: Tween(begin: 0, end: _value),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        NumberFormatter.full(val),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 58,
                          color: AppColors.white,
                          letterSpacing: -1.45,
                          fontFeatures: [FontFeature.tabularFigures()],
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),

                  // Sub-label
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 14),
                    child: Text(
                      _subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  // Bottom row: trend pill + gold trending icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Trend pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _yoy >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 14,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_yoy >= 0 ? '+' : ''}${_yoy.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _vsLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Gold trending icon
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 24,
                        color: AppColors.champagneGold,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Geometric pattern painter matching the births HTML SVG ──────────────────
// Pattern: hexagon outer + hexagon inner + cross lines + diagonals + circle
// Cell: 44×44 units (scaled to 220×220 canvas = 25 cells each)

class _GeoPainter extends CustomPainter {
  const _GeoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final thick = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;

    final veryThin = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const cell = 44.0;
    for (double ox = 0; ox < size.width + cell; ox += cell) {
      for (double oy = 0; oy < size.height + cell; oy += cell) {
        _drawCell(canvas, thick, thin, veryThin, ox, oy, cell);
      }
    }
  }

  void _drawCell(Canvas c, Paint thick, Paint thin, Paint veryThin,
      double ox, double oy, double sz) {
    final cx = ox + sz / 2;
    final cy = oy + sz / 2;
    final r = sz / 2;

    // Outer hexagon
    _hex(c, thick, cx, cy, r * 0.91, r * 0.91);
    // Inner hexagon
    _hex(c, veryThin, cx, cy, r * 0.59, r * 0.59);
    // Cross lines (thin, 0.6 opacity)
    c.drawLine(Offset(cx, oy), Offset(cx, oy + sz), thin);
    c.drawLine(Offset(ox + r * 0.18, oy + r * 0.5),
        Offset(ox + sz - r * 0.18, oy + r * 1.5), thin);
    c.drawLine(Offset(ox + sz - r * 0.18, oy + r * 0.5),
        Offset(ox + r * 0.18, oy + r * 1.5), thin);
    // Centre circle
    c.drawCircle(Offset(cx, cy), r * 0.11, veryThin);
  }

  void _hex(Canvas c, Paint p, double cx, double cy, double rx, double ry) {
    const sides = 6;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (i * 2 * pi / sides) - pi / 2;
      final x = cx + rx * cos(a);
      final y = cy + ry * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
