// lib/features/splash/presentation/splash_screen.dart
//
// Matches the approved HTML design: uae-stats-splash.html
// Animation timeline:
//   300ms  Emblem springs in (scale 0.80→1.0, elastic)
//   520ms  "UAE Stats" slides up + fades
//   720ms  Arabic name fades in
//   940ms  Gold divider expands
//   1100ms EN subtitle fades
//   1220ms AR subtitle fades
//   1420ms Taglines fade + slide up
//   360ms+ Progress bar fills over 2400ms
//   2800ms ✓ Ready → navigate to Home

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/constants/app_constants.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

// ── Colours from HTML spec ────────────────────────────────────────────────────
const _kGold       = Color(0xFFC8973A);
const _kGoldLight  = Color(0xFFE3B86A);
const _kFlagRed    = Color(0xFFEF3340);
const _kFlagGreen  = Color(0xFF009639);
const _kFlagWhite  = Color(0xFFF8F8F8);
const _kFlagBlack  = Color(0xFF0D0D0D);


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  late final AnimationController _main;     // 2800ms total
  late final AnimationController _progress; // 2400ms, starts at 360ms

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset>  _nameSlide;
  late final Animation<double> _arNameOpacity;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _subEnOpacity;
  late final Animation<double> _subArOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset>  _taglineSlide;

  bool _showReady = false;

  double _t(int ms) => ms / 2800;

  @override
  void initState() {
    super.initState();
    _main     = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

    // Logo: 300ms → 780ms
    _logoScale = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(300), _t(780), curve: Curves.elasticOut)));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(300), _t(580), curve: Curves.easeOut)));

    // Name: 520ms → 800ms
    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(520), _t(800), curve: Curves.easeOut)));
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.28), end: Offset.zero).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(520), _t(800), curve: Curves.easeOut)));

    // Arabic name: 720ms → 1000ms
    _arNameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(720), _t(1000), curve: Curves.easeOut)));

    // Divider: 940ms → 1200ms (0 → 56 logical px)
    _dividerWidth = Tween<double>(begin: 0.0, end: 56.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(940), _t(1200), curve: Curves.easeOut)));

    // EN subtitle: 1100ms → 1360ms
    _subEnOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(1100), _t(1360), curve: Curves.easeOut)));

    // AR subtitle: 1220ms → 1460ms
    _subArOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(1220), _t(1460), curve: Curves.easeOut)));

    // Taglines: 1420ms → 1700ms
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(1420), _t(1700), curve: Curves.easeOut)));
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero).animate(
      CurvedAnimation(parent: _main, curve: Interval(_t(1420), _t(1700), curve: Curves.easeOut)));

    _main.forward();
    Future.delayed(const Duration(milliseconds: 360), () { if (mounted) _progress.forward(); });
    Future.delayed(const Duration(milliseconds: 2800), () { if (mounted) setState(() => _showReady = true); });
    Future.delayed(const Duration(milliseconds: 3000), () { if (mounted) context.go(AppRoutes.home); });
  }

  @override
  void dispose() { _main.dispose(); _progress.dispose(); super.dispose(); }


  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _progress]),
        builder: (_, __) => _buildLayout(isArabic),
      ),
    );
  }

  Widget _buildLayout(bool isArabic) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        // White / off-white splash theme.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
          colors: [Color(0xFFFFFFFF), Color(0xFFFCFBF7), Color(0xFFF7F4EC)],
        ),
      ),
      child: Stack(
        children: [
          // ── Lattice pattern (faint gold on white) ────────────────────────
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _LatticePainter(color: _kGold)),
            ),
          ),
          // ── Radial glow (warm gold tint) ─────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.42,
            left: MediaQuery.of(context).size.width * 0.5 - 155,
            child: Container(
              width: 310, height: 310,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x14C8973A), Colors.transparent],
                  stops: [0.0, 0.65],
                ),
              ),
            ),
          ),
          // ── UAE map watermark ────────────────────────────────────────────
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width * 0.5 - 125,
            child: const Opacity(
              opacity: 0.06,
              child: CustomPaint(
                  size: Size(250, 90),
                  painter: _UaeMapPainter(color: _kGold)),
            ),
          ),
          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
              children: [
                // (Language toggle removed from splash — language is chosen
                //  in-app via the app-bar toggle.)
                const SizedBox(height: 8),
                const Spacer(flex: 2),
                // Emblem
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(scale: _logoScale, child: const _FcscEmblem()),
                ),
                const SizedBox(height: 26),
                // UAE Stats
                SlideTransition(
                  position: _nameSlide,
                  child: FadeTransition(
                    opacity: _nameOpacity,
                    child: const Text('UAE Stats',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 40, fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A), letterSpacing: -0.7, height: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                // Arabic name
                FadeTransition(
                  opacity: _arNameOpacity,
                  child: const Text('إحصاءات الإمارات',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w600,
                      color: Color(0xCC1F2937), height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Gold divider
                SizedBox(
                  width: _dividerWidth.value,
                  height: 1.5,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, _kGold, _kGoldLight, _kGold, Colors.transparent],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // EN subtitle
                FadeTransition(
                  opacity: _subEnOpacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      AppConstants.fcscNameEn.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w500,
                        color: Color(0x99475569), letterSpacing: 1.9, height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // AR subtitle
                FadeTransition(
                  opacity: _subArOpacity,
                  child: const Text(
                    AppConstants.fcscNameAr,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w400,
                      color: Color(0x80475569), height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Taglines
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineOpacity,
                    child: Column(children: [
                      const Text('Data for a Better Future',
                        style: TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 15,
                          fontWeight: FontWeight.w400, color: _kGold, letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('بيانات من أجل مستقبل أفضل',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 14, color: _kGold.withValues(alpha: 0.62)),
                      ),
                    ]),
                  ),
                ),
                const Spacer(flex: 3),
                // Progress bar
                _ProgressSection(progress: _progress.value, showReady: _showReady),
                const SizedBox(height: 46),
                // Official badge
                const _OfficialBadge(),
                const SizedBox(height: 9),
                const Text(
                  'v${AppConstants.appVersion}  ·  ${AppConstants.fcscWebsite}',
                  style: TextStyle(fontSize: 9.5, color: Color(0x59475569), letterSpacing: 0.6),
                ),
                const SizedBox(height: 20),
              ],
            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── FCSC Emblem ───────────────────────────────────────────────────────────────
// Matches the SVG emblem in the HTML: outer ring, gold accent dots, star ring,
// inner circle with UAE flag, gold centre pin, curved "FCSC · UAE" text arc.

class _FcscEmblem extends StatelessWidget {
  const _FcscEmblem();

  @override
  Widget build(BuildContext context) {
    // Decorative compass ring (CustomPaint) with the brand logo.png centred in
    // the inner circle — the painter skips drawing the flag so the logo shows.
    const innerDiameter = 34.0; // matches painter innerR (17) * 2
    return SizedBox(
      width: 104, height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(104, 104), painter: _EmblemPainter()),
          // Logo sits slightly above centre, like the flag emblem did (cy-4).
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipOval(
              child: SizedBox(
                width: innerDiameter,
                height: innerDiameter,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Outer ring fill + stroke (dark/gold tint so it shows on the white bg).
    canvas.drawCircle(Offset(cx, cy), r - 1,
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.02));
    canvas.drawCircle(Offset(cx, cy), r - 1,
      Paint()..color = _kGold.withValues(alpha: 0.30)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.1);

    // Cardinal gold dots (top, bottom, left, right)
    final goldDot = Paint()..color = _kGold.withValues(alpha: 0.85);
    for (final pt in [
      Offset(cx, 4.0), Offset(cx, size.height - 4),
      Offset(4.0, cy), Offset(size.width - 4, cy),
    ]) {
      canvas.drawCircle(pt, 2.8, goldDot);
    }

    // Diagonal faint dots
    final diagDot = Paint()..color = _kGold.withValues(alpha: 0.32);
    final d = size.width * 0.183;
    for (final pt in [
      Offset(d, d), Offset(size.width - d, d),
      Offset(d, size.height - d), Offset(size.width - d, size.height - d),
    ]) {
      canvas.drawCircle(pt, 1.6, diagDot);
    }

    // Decorative 16-point star ring
    _drawStarRing(canvas, Offset(cx, cy), 24.0, 9.0,
      Paint()..color = _kGold.withValues(alpha: 0.24)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9);

    // Inner circle (flag container)
    const innerR = 17.0;
    final innerCy = cy - 4; // slightly above centre like HTML (cy=48 in 104px)
    canvas.drawCircle(Offset(cx, innerCy), innerR,
      Paint()..color = const Color(0xFFF7F4EC));
    canvas.drawCircle(Offset(cx, innerCy), innerR,
      Paint()..color = _kGold.withValues(alpha: 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.9);

    // NB: the UAE-flag fill + gold centre pin that used to sit here are now
    // replaced by the brand logo.png, overlaid in [_FcscEmblem]. The inner
    // circle border above still frames it.

    // Curved "FCSC · UAE" text arc
    _drawArcText(canvas, size, cx, cy);
  }

  void _drawStarRing(Canvas canvas, Offset center, double outerR, double innerR, Paint paint) {
    const pts = 16;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final rad = i.isEven ? outerR : innerR;
      final x = center.dx + rad * cos(angle);
      final y = center.dy + rad * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawArcText(Canvas canvas, Size size, double cx, double cy) {
    // Draw "FCSC · UAE" along a bottom arc (matches HTML textPath)
    const text = 'FCSC · UAE';
    const fontSize = 7.0;
    final tp = TextPainter(
      text: const TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize, fontWeight: FontWeight.w600,
          color: Color(0x8C8A6D2E), letterSpacing: 2.4,
          fontFamily: 'Inter',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Arc radius matches HTML: r=32 centred at (52,52) in 104px
    final arcR = size.width * 0.308; // ~32/104
    final arcCy = cy;
    final totalAngle = tp.width / arcR;
    final startAngle = pi / 2 - totalAngle / 2; // bottom arc, centred

    canvas.save();
    for (int i = 0; i < text.length; i++) {
      final charTp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: const TextStyle(
            fontSize: fontSize, fontWeight: FontWeight.w600,
            color: Color(0x8C8A6D2E), letterSpacing: 0,
            fontFamily: 'Inter',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final charAngle = startAngle + (i / text.length) * totalAngle;
      final x = cx + arcR * cos(charAngle) - charTp.width / 2;
      final y = arcCy + arcR * sin(charAngle) - charTp.height / 2;
      canvas.save();
      canvas.translate(x + charTp.width / 2, y + charTp.height / 2);
      canvas.rotate(charAngle + pi / 2);
      canvas.translate(-charTp.width / 2, -charTp.height / 2);
      charTp.paint(canvas, Offset.zero);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


// ── Lattice painter (8-pointed star grid) ─────────────────────────────────────

class _LatticePainter extends CustomPainter {
  const _LatticePainter({this.color = Colors.white});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 80.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35;

    for (double x = 0; x < size.width + cellSize; x += cellSize) {
      for (double y = 0; y < size.height + cellSize; y += cellSize) {
        _drawStar(canvas, paint, Offset(x, y), cellSize * 0.45, 16);
        _drawStar(canvas, innerPaint, Offset(x, y), cellSize * 0.22, 16);
        canvas.drawCircle(Offset(x, y), 1.2,
            Paint()..color = color.withValues(alpha: 0.2));
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double outerR, int pts) {
    final innerR = outerR * 0.42;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * pi / pts) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── UAE Map watermark painter ─────────────────────────────────────────────────

class _UaeMapPainter extends CustomPainter {
  const _UaeMapPainter({this.color = Colors.white});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    // Simplified UAE silhouette path (matches HTML SVG path)
    final path = Path();
    final pts = [
      [10,60],[16,44],[28,34],[44,26],[60,20],[76,17],[92,18],[103,25],
      [110,34],[116,44],[122,53],[129,57],[138,53],[150,47],[162,41],
      [175,36],[188,30],[200,25],[212,21],[222,17],[230,15],[234,24],
      [230,37],[224,48],[215,57],[204,64],[191,70],[176,73],[160,74],
      [145,73],[131,75],[119,77],[105,79],[90,78],[74,74],[58,68],
      [43,60],[28,54],
    ];
    path.moveTo(pts[0][0].toDouble(), pts[0][1].toDouble());
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i][0].toDouble(), pts[i][1].toDouble());
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}


// ── Progress section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.progress, required this.showReady});
  final double progress;
  final bool showReady;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: 208, height: 2.5,
        child: Stack(children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF475569).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGold, _kGoldLight, _kGold],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: _kGold.withValues(alpha: 0.45), blurRadius: 6)],
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: showReady
          ? const Text('✓  Ready',
              key: ValueKey('ready'),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: Color(0xF2C8973A), letterSpacing: 0.5))
          : const Text('Loading official data…',
              key: ValueKey('loading'),
              style: TextStyle(fontSize: 11, color: Color(0x8C475569), letterSpacing: 0.8)),
      ),
    ]);
  }
}

// ── Official badge ────────────────────────────────────────────────────────────

class _OfficialBadge extends StatelessWidget {
  const _OfficialBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini UAE flag
        SizedBox(
          width: 21, height: 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Row(children: [
              Container(width: 5.8, color: _kFlagRed),
              const Expanded(child: Column(children: [
                Expanded(child: ColoredBox(color: _kFlagGreen)),
                Expanded(child: ColoredBox(color: _kFlagWhite)),
                Expanded(child: ColoredBox(color: _kFlagBlack)),
              ])),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        const Text('OFFICIAL GOVERNMENT APP',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w500,
            color: Color(0x99475569), letterSpacing: 2.2,
          )),
      ],
    );
  }
}
