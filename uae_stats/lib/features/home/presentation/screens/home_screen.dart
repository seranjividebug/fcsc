// lib/features/home/presentation/screens/home_screen.dart
// Pixel-perfect clone of uae-stats-home (1)(1).html — all 5 frames

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/home_kpi_item.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';
import 'package:uae_stats/data/providers/home_carousel_provider.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/data/providers/section_kpi_providers.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/app_logo.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ── Design tokens — AE Gold theme (hero + economy + home chrome) ─────────────
const _kGreen     = AppColors.aeGold;         // #92722A  primary brand gold
const _kForest    = AppColors.aeGoldDeep;     // #7C5E24  deep gold
const _kGold      = AppColors.aeGoldAccent;   // #B68A35  accent gold
const _kSage      = AppColors.aeGoldBg;       // #F9F7ED  light gold background
const _kOffWhite  = AppColors.offWhite;       // #FAFBFC
const _kPearl     = AppColors.pearlGray;      // #F3F5F7
const _kSilver    = AppColors.silver;         // #E5E7EB
const _kSlate400  = AppColors.slate400;       // #9CA3AF
const _kSlate600  = AppColors.slate600;       // #4B5563
const _kSlate900  = AppColors.slate900;       // #0F172A
// ── Demography (vitals sheet) — blue ─────────────────────────────────────────
const _kDemBlue    = AppColors.demBlue;       // #0073AB
const _kDemBlueBg  = AppColors.demBlueTint;   // #EFFAFF


// ── HomeScreen ────────────────────────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();
  final _demographyKey  = GlobalKey();
  final _economyKey     = GlobalKey();
  final _environmentKey = GlobalKey();
  String _activeFilter  = 'Demography';

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    // Population tile — live from API, fallback to seed while loading/error
    final demography = ref.watch(demographyKpisProvider);
    final popKpi    = demography.valueOrNull?.firstOrNull?.cards.firstOrNull;
    final popValue  = popKpi?.displayValue ?? '—';
    final popChange = popKpi?.trendPercent ?? 0.0;
    final popYear   = popKpi?.year ?? '—';
    final popSparkline = popKpi?.sparklinePoints ?? const [];

    return Scaffold(
      backgroundColor: _kOffWhite,
      body: Column(children: [
        // ── App bar ──────────────────────────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Container(
            height: AppSpacing.appBarHeight,
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: const Row(children: [
              Icon(Icons.menu, size: 24, color: _kSlate600),
              SizedBox(width: 12),
              AppLogo(),
              SizedBox(width: 8),
              Text('UAE Stats',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: _kSlate900, letterSpacing: -0.34)),
              Spacer(),
              LanguageToggleButton(foregroundColor: _kSlate600),
            ]),
          ),
        ),
        // ── Flag stripe ──────────────────────────────────────────────────────
        const FlagStripe(),
        // ── Scrollable body ──────────────────────────────────────────────────
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              // Hero + KPI carousel overlap block
              const SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Hero card — extra bottom padding reserves space for overlap
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _HeroCard(extraBottomPadding: 80),
                    ),
                    // KPI carousel — floats 60px up into the hero
                    Positioned(
                      left: 0, right: 0,
                      bottom: -80,
                      child: _KeyFiguresCarousel(),
                    ),
                  ],
                ),
              ),
              // Gap to account for the overlap
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
              // Search bar
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: _SearchBar(),
                ),
              ),
              // Filter chips
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: _FilterChips(
                  selected: _activeFilter,
                  onSelected: (v) {
                    setState(() => _activeFilter = v);
                    if (v == 'Demography') _scrollTo(_demographyKey);
                    if (v == 'Economy')    _scrollTo(_economyKey);
                    if (v == 'Environment') _scrollTo(_environmentKey);
                  },
                ),
              ),
              // Demography section
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _CategorySection(
                    sectionKey: _demographyKey,
                    icon: Icons.people_rounded,
                    iconColor: AppColors.demBlue,
                    iconBg: AppColors.demBlueTint,
                    title: isArabic ? 'الديموغرافيا' : 'Demography',
                    subtitle: isArabic ? 'السكان · الأحوال الحيوية · التعليم · الصحة · العمل · الشؤون الاجتماعية' : 'Population · Vitals · Education · Health · Labor · Social',
                    tiles: [
                      _TileData.metric(id: 'population', icon: Icons.people_outline, label: 'Population', value: popValue, change: popChange, year: popYear, sparklinePoints: popSparkline),
                      const _TileData.group(icon: Icons.monitor_heart_outlined, label: 'Vitals', subtitle: 'Births, Deaths, Marriages…', count: 4),
                      const _TileData.group(icon: Icons.school_outlined, label: 'Education', subtitle: 'Students, Teachers', count: 3),
                      const _TileData.group(icon: Icons.monitor_heart_outlined, label: 'Health', subtitle: 'Hospitals, Healthcare Professionals…', count: 4),
                      const _TileData.fullWidth(icon: Icons.work_outline, label: 'Labor Force', subtitle: 'Economic Activity, Employment, Unemployment…', value: '', change: 0, year: '', count: 7),
                    ],
                  ),
                ),
              ),
              // Economy section
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _CategorySection(
                    sectionKey: _economyKey,
                    icon: Icons.business_rounded,
                    iconColor: _kGold,
                    iconBg: _kSage,
                    title: isArabic ? 'الاقتصاد' : 'Economy',
                    subtitle: isArabic ? 'الناتج المحلي · التجارة · الصناعة · الأسعار' : 'GDP · Trade · Industry · Prices',
                    tiles: const [
                      _TileData.group(icon: Icons.account_balance_outlined, label: 'National Accounts', subtitle: 'GDP Current & Constant, Quarterly GDP', count: 4),
                      _TileData.group(icon: Icons.swap_horiz_rounded, label: 'International Trade', subtitle: 'Total Trade, Exports, Imports, Re-Exports…', count: 6),
                      _TileData.group(icon: Icons.flight_rounded, label: 'Air Transport', subtitle: 'Aircraft Operations, Airports, Aviation…', count: 1),
                      _TileData.group(icon: Icons.price_change_outlined, label: 'Prices', subtitle: 'CPI Annual, Hotel Arrivals, Establishments…', count: 4),
                    ],
                  ),
                ),
              ),
              // Environment section
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _CategorySection(
                    sectionKey: _environmentKey,
                    icon: Icons.eco_rounded,
                    iconColor: AppColors.envGreen,
                    iconBg: AppColors.envGreenTint,
                    title: isArabic ? 'البيئة' : 'Environment',
                    subtitle: isArabic ? 'الزراعة · الطاقة · المناخ · الموارد' : 'Agriculture · Energy · Climate · Resources',
                    tiles: const [
                      _TileData.group(icon: Icons.grass_outlined, label: 'Agriculture', subtitle: 'Crops, Land Area, Livestock Census', count: 7),
                      _TileData.group(icon: Icons.bolt_outlined, label: 'Energy', subtitle: 'Electricity, Oil & Gas, Renewable', count: 3),
                      _TileData.fullWidth(icon: Icons.cloud_outlined, label: 'Environment', subtitle: 'Ecology · Temperature, Rainfall, Water', value: '', change: 0, year: '', count: 3),
                    ],
                  ),
                ),
              ),
              // FCSC Footer
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: _FcscFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
        // ── Bottom nav ───────────────────────────────────────────────────────
        const AppBottomNavBar(),
      ]),
    );
  }
}


// ── Tile data model ───────────────────────────────────────────────────────────
class _TileData {
  final String? id;
  final IconData icon;
  final String label;
  final String subtitle;
  final String value;
  final double change;
  final String year;
  final int count;
  final bool isFullWidth;
  final bool isMetric;
  final List<double> sparklinePoints;

  const _TileData._({
    this.id,
    required this.icon,
    required this.label,
    this.subtitle = '',
    this.value = '',
    this.change = 0,
    this.year = '',
    this.count = 0,
    this.isFullWidth = false,
    this.isMetric = false,
    this.sparklinePoints = const [],
  });

  const _TileData.metric({
    required String id,
    required IconData icon,
    required String label,
    required String value,
    required double change,
    required String year,
    List<double> sparklinePoints = const [],
  }) : this._(id: id, icon: icon, label: label, value: value,
               change: change, year: year, isMetric: true,
               sparklinePoints: sparklinePoints);

  const _TileData.group({
    required IconData icon,
    required String label,
    required String subtitle,
    required int count,
    String value = '',
    double change = 0,
    String year = '',
  }) : this._(icon: icon, label: label, subtitle: subtitle, count: count,
               value: value, change: change, year: year);

  const _TileData.fullWidth({
    required IconData icon,
    required String label,
    required String subtitle,
    String value = '',
    double change = 0,
    String year = '',
    int count = 0,
  }) : this._(icon: icon, label: label, subtitle: subtitle, value: value,
               change: change, year: year, count: count, isFullWidth: true);
}

// ── Hero card ─────────────────────────────────────────────────────────────────
class _HeroCard extends ConsumerWidget {
  const _HeroCard({this.extraBottomPadding = 0});
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kForest, _kGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(color: _kGreen.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(children: [
        // Islamic pattern overlay
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(painter: _IslamicPatternPainter()),
            ),
          ),
        ),
        Padding(
          // Extra bottom padding so the green area extends behind the KPI cards
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + extraBottomPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Official Statistics + date (left) | flag logo (right)
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isArabic ? 'الإحصاءات الرسمية' : 'OFFICIAL STATISTICS',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: Colors.white70, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6,
                          decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(isArabic ? 'تحديث · ١٥ مايو ٢٠٢٦' : 'Updated · 15 May 2026',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Colors.white60, letterSpacing: 0.2)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const AppLogo(size: 36),
            ]),
            const SizedBox(height: 14),
            Text(isArabic ? 'الإمارات العربية المتحدة' : 'United Arab Emirates',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                color: Colors.white, height: 1.2, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(isArabic ? 'أرقام الإمارات الرئيسية' : 'Key Figures at a Glance',
              style: TextStyle(fontSize: 14, color: _kGold.withValues(alpha: 0.95), height: 1.4,
                fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ── Key figures horizontal carousel ──────────────────────────────────────────
class _KeyFiguresCarousel extends ConsumerStatefulWidget {
  const _KeyFiguresCarousel();

  @override
  ConsumerState<_KeyFiguresCarousel> createState() =>
      _KeyFiguresCarouselState();
}

class _KeyFiguresCarouselState extends ConsumerState<_KeyFiguresCarousel> {
  final ScrollController _controller = ScrollController();

  // One card (160) + separator (12) — the scroll step per arrow tap.
  static const double _step = 172;

  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final left = _controller.offset > 4;
    final right = _controller.offset < pos.maxScrollExtent - 4;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + delta)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeCarouselProvider);

    return SizedBox(
      height: 152,
      child: Stack(
        children: [
          async.when(
            loading: () => _buildList(_loadingItems),
            error: (_, __) => _buildList(_loadingItems),
            data: (items) => _buildList(items),
          ),
          // Left arrow
          Positioned(
            left: 4,
            top: 0,
            bottom: 8,
            child: Center(
              child: _CarouselArrow(
                icon: Icons.chevron_left_rounded,
                visible: _canScrollLeft,
                onTap: () => _scrollBy(-_step),
              ),
            ),
          ),
          // Right arrow
          Positioned(
            right: 4,
            top: 0,
            bottom: 8,
            child: Center(
              child: _CarouselArrow(
                icon: Icons.chevron_right_rounded,
                visible: _canScrollRight,
                onTap: () => _scrollBy(_step),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<HomeKpiItem> items) => ListView.separated(
    controller: _controller,
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    itemCount: items.length,
    separatorBuilder: (_, __) => const SizedBox(width: 12),
    itemBuilder: (_, i) => _KeyFigureCard(data: items[i]),
  );

  static final _loadingItems = List.generate(
    5,
    (i) => HomeKpiItem.loading(
      category: ['Demography', 'Economy', 'Economy', 'Environment', 'Economy'][i],
      label: ['Population', 'CPI Inflation', 'Air Passengers', 'Renewable Energy', 'Yearly GDP'][i],
      icon: [Icons.people_rounded, Icons.price_change_outlined, Icons.flight_rounded,
             Icons.wb_sunny_outlined, Icons.trending_up_rounded][i],
      iconColor: [AppColors.demBlue, _kGold, _kGold, AppColors.envGreen, _kGold][i],
      iconBg: [AppColors.demBlueTint, _kSage, _kSage, AppColors.envGreenTint, _kSage][i],
      categoryColor: [AppColors.demBlue, _kGold, _kGold, AppColors.envGreen, _kGold][i],
    ),
  );
}

// ── Carousel navigation arrow ─────────────────────────────────────────────────
class _CarouselArrow extends StatelessWidget {
  const _CarouselArrow({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _kSilver),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: _kSlate600),
          ),
        ),
      ),
    );
  }
}

class _KeyFigureCard extends StatelessWidget {
  const _KeyFigureCard({required this.data});
  final HomeKpiItem data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: const [
          BoxShadow(color: Color(0x1A0F172A), blurRadius: 20, offset: Offset(0, 6)),
          BoxShadow(color: Color(0x0A0F172A), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Icon + category pill
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: data.isLoading
                ? null
                : Icon(data.icon, size: 16, color: data.iconColor),
          ),
          const Spacer(),
          data.isLoading
              ? const ShimmerBox(width: 56, height: 16, borderRadius: 999)
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(data.category,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      color: data.categoryColor, letterSpacing: 0.2)),
                ),
        ]),
        const Spacer(),
        // Label
        data.isLoading
            ? const ShimmerBox(width: 80, height: 12, borderRadius: 4)
            : Text(data.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: _kSlate600, height: 1.3)),
        const SizedBox(height: 4),
        // Value
        data.isLoading
            ? const ShimmerBox(width: 72, height: 24, borderRadius: 4)
            : Text(data.displayValue,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: _kSlate900, height: 1.1,
                  fontFeatures: [FontFeature.tabularFigures()])),
        const SizedBox(height: 6),
        // Trend + year
        data.isLoading
            ? const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4)
            : Row(children: [
                Icon(data.isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11,
                  color: data.isUp ? AppColors.success : AppColors.error),
                const SizedBox(width: 2),
                Text(
                  data.trendPercent != null
                      ? '${data.trendPercent!.abs().toStringAsFixed(1)}%'
                      : '—',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: data.isUp ? AppColors.success : AppColors.error)),
                const Spacer(),
                Text(data.year,
                  style: const TextStyle(fontSize: 10, color: _kSlate400)),
              ]),
      ]),
    );
  }
}


// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return GestureDetector(
      onTap: () => context.push(AppRoutes.search),
      child: Container(
        height: AppSpacing.searchBarHeight,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: _kSilver),
          boxShadow: AppColors.shadowCard,
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 20, color: _kSlate400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isArabic ? 'ابحث عن المؤشرات والموضوعات والبيانات…' : 'Search any indicator or topic…',
              style: const TextStyle(fontSize: 14, color: _kSlate400, height: 1.0)),
          ),
          const Icon(Icons.mic_none_rounded, size: 20, color: _kSlate400),
          const SizedBox(width: 14),
        ]),
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  static const _chips = ['Demography', 'Economy', 'Environment'];

  static String _label(String key, bool isArabic) {
    if (!isArabic) return key;
    const ar = {'Demography': 'الديموغرافيا',
      'Economy': 'الاقتصاد', 'Environment': 'البيئة'};
    return ar[key] ?? key;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return SizedBox(
      height: AppSpacing.actionChipHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final chip = _chips[i];
          final active = chip == selected;
          return GestureDetector(
            onTap: () => onSelected(chip),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: active ? _kGreen : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: active ? _kGreen : _kSilver),
              ),
              child: Text(_label(chip, isArabic),
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : _kSlate600,
                )),
            ),
          );
        },
      ),
    );
  }
}


// ── Category section ──────────────────────────────────────────────────────────
class _CategorySection extends ConsumerStatefulWidget {
  const _CategorySection({
    this.sectionKey,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.tiles,
  });
  final GlobalKey? sectionKey;
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final List<_TileData> tiles;

  @override
  ConsumerState<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Container(
      key: widget.sectionKey,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(children: [
        // Section header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 19, color: widget.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isArabic ? 'الفئة' : 'Category',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                      color: _kSlate400, letterSpacing: 0.6)),
                  const SizedBox(height: 1),
                  Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: _kSlate900, letterSpacing: -0.2)),
                  const SizedBox(height: 2),
                  Text(widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: _kSlate600, height: 1.3)),
                ],
              )),
              Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 22, color: _kSlate400),
            ]),
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, color: _kPearl),
          _TileGrid(tiles: widget.tiles, accentColor: widget.iconColor, accentBg: widget.iconBg),
        ],
      ]),
    );
  }
}

// ── Tile grid (2-col + full-width orphan rule) ────────────────────────────────
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles, required this.accentColor, required this.accentBg});
  final List<_TileData> tiles;
  final Color accentColor, accentBg;

  @override
  Widget build(BuildContext context) {
    final gridTiles = tiles.where((t) => !t.isFullWidth).toList();
    final fullTiles = tiles.where((t) => t.isFullWidth).toList();

    // Build rows of 2 manually to avoid GridView shrinkWrap height bugs
    final rows = <Widget>[];
    for (int i = 0; i < gridTiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      final a = gridTiles[i];
      final b = i + 1 < gridTiles.length ? gridTiles[i + 1] : null;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _Tile(data: a, accentColor: accentColor, accentBg: accentBg)),
              if (b != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _Tile(data: b, accentColor: accentColor, accentBg: accentBg)),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    for (final t in fullTiles) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 8));
      rows.add(_FullWidthTile(data: t, accentColor: accentColor, accentBg: accentBg));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}


// ── Individual tile (2-col) ───────────────────────────────────────────────────
class _Tile extends StatefulWidget {
  const _Tile({required this.data, required this.accentColor, required this.accentBg});
  final _TileData data;
  final Color accentColor, accentBg;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasValue = d.value.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        if (d.label == 'Agriculture') {
          _showAgricultureSheet(context);
        } else if (d.label == 'Vitals') {
          _showVitalsSheet(context);
        } else if (d.label == 'Education') {
          _showEducationSheet(context);
        } else if (d.label == 'Health') {
          _showHealthSheet(context);
        } else if (d.label == 'Air Transport') {
          _showAirTransportSheet(context);
        } else if (d.label == 'National Accounts') {
          _showNationalAccountsSheet(context);
        } else if (d.label == 'International Trade') {
          _showInternationalTradeSheet(context);
        } else if (d.label == 'Prices') {
          _showPricesSheet(context);
        } else if (d.label == 'Tourism') {
          _showTourismSheet(context);
        } else if (d.label == 'Labor Force') {
          _showLaborSheet(context);
        } else if (d.label == 'Environment') {
          // Climate / ecology indicators (only Mean Temperature is wired today).
          context.push(AppRoutes.indicatorPath('ecology_mean_temp'));
        } else if (d.id != null) { context.push(AppRoutes.indicatorPath(d.id!)); }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.98 : 1.0, _pressed ? 0.98 : 1.0, 1.0, 1.0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: _pressed
            ? Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.5)
            : null,
          boxShadow: _pressed ? [] : AppColors.shadowCard,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: widget.accentBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(d.icon, size: 16, color: widget.accentColor),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _kSlate400),
          ]),
          const SizedBox(height: 6),
          Text(d.label,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: _kSlate900, height: 1.2)),
          if (!hasValue && d.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(d.subtitle,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: _kSlate600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.accentBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${d.count} Indicators',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: widget.accentColor)),
                  ),
                ),
                const Icon(Icons.grid_view_rounded, size: 14, color: _kSlate400),
              ],
            ),
          ],
          if (hasValue) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(d.value,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                            color: widget.accentColor, height: 1.1,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                      ),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(d.change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 10, color: d.change >= 0 ? AppColors.success : AppColors.error),
                        const SizedBox(width: 2),
                        Text('${d.change.toStringAsFixed(1)}%',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: d.change >= 0 ? AppColors.success : AppColors.error)),
                        const SizedBox(width: 6),
                        Text(d.year,
                          style: const TextStyle(fontSize: 9, color: _kSlate400)),
                      ]),
                    ],
                  ),
                ),
                if (d.sparklinePoints.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 52,
                    height: 32,
                    child: CustomPaint(
                      painter: _SparklinePainter(
                        points: d.sparklinePoints,
                        isUp: d.change >= 0,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ]),
      ),
    );
  }
}

// ── Full-width tile ───────────────────────────────────────────────────────────
class _FullWidthTile extends StatefulWidget {
  const _FullWidthTile({required this.data, required this.accentColor, required this.accentBg});
  final _TileData data;
  final Color accentColor, accentBg;

  @override
  State<_FullWidthTile> createState() => _FullWidthTileState();
}

class _FullWidthTileState extends State<_FullWidthTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasValue = d.value.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        final d = widget.data;
        if (d.label == 'Labor Force') {
          _showLaborSheet(context);
        } else if (d.label == 'Tourism') {
          _showTourismSheet(context);
        } else if (d.label == 'Environment') {
          _showEcologySheet(context);
        } else if (d.id != null) {
          context.push(AppRoutes.indicatorPath(d.id!));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.98 : 1.0, _pressed ? 0.98 : 1.0, 1.0, 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: _pressed ? [] : AppColors.shadowCard,
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: widget.accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, size: 19, color: widget.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _kSlate900)),
            if (d.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(d.subtitle,
                style: const TextStyle(fontSize: 12, color: _kSlate600)),
            ],
            if (hasValue) ...[
              const SizedBox(height: 6),
              Text(d.value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                  color: widget.accentColor,
                  fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 4),
              Row(children: [
                Icon(d.change >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11, color: d.change >= 0 ? AppColors.success : AppColors.error),
                const SizedBox(width: 2),
                Text('${d.change.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: d.change >= 0 ? AppColors.success : AppColors.error)),
                const SizedBox(width: 8),
                Text(d.year,
                  style: const TextStyle(fontSize: 10, color: _kSlate400)),
              ]),
            ],
            if (!hasValue && d.count > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.accentBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('${d.count} Indicators',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: widget.accentColor)),
                  ),
                  const Icon(Icons.grid_view_rounded, size: 14, color: _kSlate400),
                ],
              ),
            ],
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kSlate400),
        ]),
      ),
    );
  }
}


// ── Agriculture bottom sheet ──────────────────────────────────────────────────
void _showAgricultureSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _AgricultureSheet(),
  );
}

class _AgricultureSheet extends ConsumerWidget {
  const _AgricultureSheet();

  static const _ids    = [
    'crop_production', 'crop_area', 'crop_land_total',
    'livestock_camel', 'livestock_cattle', 'livestock_goat', 'livestock_sheep',
  ];
  static const _icons  = {
    'crop_production': Icons.grass_outlined,
    'crop_area':       Icons.crop_square_rounded,
    'crop_land_total': Icons.terrain_outlined,
    'livestock_camel':  Icons.pets_outlined,
    'livestock_cattle': Icons.pets_outlined,
    'livestock_goat':   Icons.pets_outlined,
    'livestock_sheep':  Icons.pets_outlined,
  };
  static const _labels = {
    'crop_production': 'Crop Statistics by Emirate',
    'crop_area':       'Agricultural Cultivated Area',
    'crop_land_total': 'Total Agricultural Land Use',
    'livestock_camel':  'Camel Population',
    'livestock_cattle': 'Cattle Population',
    'livestock_goat':   'Goat Population',
    'livestock_sheep':  'Sheep Population',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW, height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(color: _kSilver, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.envGreenTint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.grass_outlined, size: 20, color: AppColors.envGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Agriculture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                  Text('Environment · 7 Indicators', style: TextStyle(fontSize: 12, color: _kSlate600)),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!, label: _labels[id]!,
                    iconColor: AppColors.envGreen, iconBg: AppColors.envGreenTint,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!, label: _labels[id]!,
                    summary: summary,
                    iconColor: AppColors.envGreen, iconBg: AppColors.envGreenTint,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kPearl))),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.indicatorPath('crop_production'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.envGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                  elevation: 0,
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('View All Agriculture Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Ecology bottom sheet ──────────────────────────────────────────────────────
void _showEcologySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _EcologySheet(),
  );
}

class _EcologySheet extends ConsumerWidget {
  const _EcologySheet();

  static const _ids = ['ecology_mean_temp', 'ecology_rainfall', 'ecology_produced_water'];
  static const _icons = {
    'ecology_mean_temp':      Icons.thermostat_outlined,
    'ecology_rainfall':       Icons.water_drop_outlined,
    'ecology_produced_water': Icons.opacity_outlined,
  };
  static const _labels = {
    'ecology_mean_temp':      'Mean Temperature',
    'ecology_rainfall':       'Annual Rainfall',
    'ecology_produced_water': 'Produced Water',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.36,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW, height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(color: _kSilver, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.envGreenTint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.cloud_outlined, size: 20, color: AppColors.envGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ecology', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                  Text('Environment · 3 Indicators', style: TextStyle(fontSize: 12, color: _kSlate600)),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!, label: _labels[id]!,
                    iconColor: AppColors.envGreen, iconBg: AppColors.envGreenTint,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!, label: _labels[id]!,
                    summary: summary,
                    iconColor: AppColors.envGreen, iconBg: AppColors.envGreenTint,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Vitals bottom sheet ───────────────────────────────────────────────────────
void _showVitalsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _VitalsSheet(),
  );
}

class _VitalsSheet extends ConsumerWidget {
  const _VitalsSheet();

  static const _icons = {
    'births':   Icons.child_care_rounded,
    'deaths':   Icons.monitor_heart_outlined,
    'marriages': Icons.favorite_rounded,
    'divorces': Icons.heart_broken_outlined,
  };
  static const _labels = {
    'births':   'Births',
    'deaths':   'Deaths',
    'marriages': 'Marriages',
    'divorces': 'Divorces',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ['births', 'deaths', 'marriages', 'divorces'];
    final summaries = ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.80,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW, height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                color: _kSilver,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Sheet header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _kDemBlueBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.monitor_heart_outlined, size: 20, color: _kDemBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vitals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                  Text('Demography · 4 Indicators',
                    style: TextStyle(fontSize: 12, color: _kSlate600)),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          // Rows
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('births'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDemBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('View All Vitals Data',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _VitalRow extends StatelessWidget {
  const _VitalRow({
    required this.icon,
    required this.label,
    required this.summary,
    this.onTap,
    this.iconColor = _kDemBlue,
    this.iconBg = _kDemBlueBg,
  });
  final IconData icon;
  final String label;
  final IndicatorSummary summary;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    final up = summary.yoyChange >= 0;
    final prevYear = summary.latestPeriod.isNotEmpty && summary.latestPeriod != '—'
        ? '${int.tryParse(summary.latestPeriod) != null ? int.parse(summary.latestPeriod) - 1 : summary.latestPeriod}'
        : '—';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSlate900)),
            Row(children: [
              Text(summary.latestPeriod,
                style: const TextStyle(fontSize: 11, color: _kSlate400)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: up ? AppColors.successBg : AppColors.errorBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 9, color: up ? AppColors.success : AppColors.error),
                  const SizedBox(width: 2),
                  Text('${summary.yoyChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: up ? AppColors.success : AppColors.error)),
                  const SizedBox(width: 3),
                  Text('vs $prevYear',
                    style: const TextStyle(fontSize: 9, color: _kSlate400)),
                ]),
              ),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
            Text(NumberFormatter.full(summary.latestValue),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                color: _kSlate900, fontFeatures: [FontFeature.tabularFigures()])),
            SizedBox(
              width: 60, height: 18,
              child: CustomPaint(painter: _SparklinePainter(
                points: summary.sparklineValues,
                isUp: up,
              )),
            ),
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _kSlate400),
        ]),
      ),
    );
  }
}

class _VitalRowShimmer extends StatelessWidget {
  const _VitalRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _kDemBlueBg, borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShimmerBox(width: 80, height: 12),
          SizedBox(height: 6),
          ShimmerBox(width: 120, height: 10),
        ])),
        const Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          ShimmerBox(width: 64, height: 14),
          SizedBox(height: 4),
          ShimmerBox(width: 60, height: 10),
        ]),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _kSlate400),
      ]),
    );
  }
}

class _VitalRowEmpty extends StatelessWidget {
  const _VitalRowEmpty({
    required this.icon,
    required this.label,
    this.iconColor = _kDemBlue,
    this.iconBg = _kDemBlueBg,
  });
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSlate900))),
        const Text('—', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate400)),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _kSlate400),
      ]),
    );
  }
}


// ── Education bottom sheet ────────────────────────────────────────────────────
void _showEducationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _EducationSheet(),
  );
}

class _EducationSheet extends ConsumerWidget {
  const _EducationSheet();

  static const _ids = ['student_enrolment', 'teaching_staff', 'higher_education'];

  static const _icons = {
    'student_enrolment': Icons.school_outlined,
    'teaching_staff':    Icons.person_outline_rounded,
    'higher_education':  Icons.account_balance_outlined,
  };
  static const _labels = {
    'student_enrolment': 'Students',
    'teaching_staff':    'Teachers',
    'higher_education':  'Higher Education',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW, height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(color: _kSilver, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _kDemBlueBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_outlined, size: 20, color: _kDemBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Education',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                  Text('Demography · 3 Indicators',
                    style: TextStyle(fontSize: 12, color: _kSlate600)),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          // Rows
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('student_enrolment'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDemBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('View All Education Data',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Sparkline painter ─────────────────────────────────────────────────────────
void _showHealthSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _HealthSheet(),
  );
}

class _HealthSheet extends ConsumerWidget {
  const _HealthSheet();

  static const _ids = [
    'hospitals',
    'health_clinics_centers',
    'health_hospital_beds',
    'health_professionals',
  ];

  static const _icons = {
    'hospitals': Icons.local_hospital_outlined,
    'health_clinics_centers': Icons.healing,
    'health_hospital_beds': Icons.bed_outlined,
    'health_professionals': Icons.medical_services_outlined,
  };

  static const _labels = {
    'hospitals': 'Hospitals',
    'health_clinics_centers': 'Clinics and Centers',
    'health_hospital_beds': 'Hospital Beds',
    'health_professionals': 'Healthcare Professionals',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW,
              height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                color: _kSilver,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kDemBlueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  size: 20,
                  color: _kDemBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kSlate900,
                      ),
                    ),
                    Text(
                      'Demography · 4 Indicators',
                      style: TextStyle(fontSize: 12, color: _kSlate600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration:
                      const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('hospitals'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDemBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All Health Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Air Transport bottom sheet ────────────────────────────────────────────────

void _showAirTransportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _AirTransportSheet(),
  );
}

class _AirTransportSheet extends ConsumerWidget {
  const _AirTransportSheet();

  static const _ids    = ['aircraft_movement'];
  static const _icons  = {'aircraft_movement': Icons.flight_rounded};
  static const _labels = {'aircraft_movement': 'Aircraft Movement'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();
    return _EconomySheet(
      title: 'Air Transport',
      subtitle: 'Economy · 1 Indicator',
      icon: Icons.flight_rounded,
      ids: _ids,
      icons: _icons,
      labels: _labels,
      summaries: summaries,
      buttonLabel: 'View All Air Transport Data',
      firstIndicatorId: 'aircraft_movement',
      accentColor: _kGold,
      accentBg: _kSage,
      rowIconColor: _kGold,
      rowIconBg: _kSage,
    );
  }
}

// ── Prices bottom sheet ───────────────────────────────────────────────────────

void _showPricesSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _PricesSheet(),
  );
}

class _PricesSheet extends ConsumerWidget {
  const _PricesSheet();

  static const _ids = [
    'prices_cpi_annual',
    'tourism_hotel_arrivals',
    'tourism_hotel_establishments',
    'tourism_main_indicators',
  ];
  static const _icons = {
    'prices_cpi_annual':             Icons.price_change_outlined,
    'tourism_hotel_arrivals':        Icons.flight_land_rounded,
    'tourism_hotel_establishments':  Icons.hotel_outlined,
    'tourism_main_indicators':       Icons.bar_chart_rounded,
  };
  static const _labels = {
    'prices_cpi_annual':             'CPI Annual',
    'tourism_hotel_arrivals':        'Hotel Guest Arrivals by Nationality',
    'tourism_hotel_establishments':  'Hotel Establishments',
    'tourism_main_indicators':       'Main Indicators',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();
    return _EconomySheet(
      title: 'Prices',
      subtitle: 'Economy · 4 Indicators',
      icon: Icons.price_change_outlined,
      ids: _ids,
      icons: _icons,
      labels: _labels,
      summaries: summaries,
      buttonLabel: 'View All Prices & Tourism Data',
      firstIndicatorId: 'prices_cpi_annual',
      accentColor: _kGold,
      accentBg: _kSage,
      rowIconColor: _kGold,
      rowIconBg: _kSage,
    );
  }
}

// ── Tourism bottom sheet ──────────────────────────────────────────────────────

void _showTourismSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _TourismSheet(),
  );
}

class _TourismSheet extends ConsumerWidget {
  const _TourismSheet();

  static const _ids = [
    'tourism_hotel_arrivals',
    'tourism_hotel_establishments',
    'tourism_main_indicators',
  ];
  static const _icons = {
    'tourism_hotel_arrivals':       Icons.flight_land_rounded,
    'tourism_hotel_establishments': Icons.hotel_outlined,
    'tourism_main_indicators':      Icons.bar_chart_rounded,
  };
  static const _labels = {
    'tourism_hotel_arrivals':       'Hotel Guest Arrivals by Nationality',
    'tourism_hotel_establishments': 'Hotel Establishments',
    'tourism_main_indicators':      'Main Indicators',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();
    return _EconomySheet(
      title: 'Tourism',
      subtitle: 'Economy · 3 Indicators',
      icon: Icons.flight_outlined,
      ids: _ids,
      icons: _icons,
      labels: _labels,
      summaries: summaries,
      buttonLabel: 'View All Tourism Data',
      firstIndicatorId: 'tourism_hotel_arrivals',
      accentColor: _kGold,
      accentBg: _kSage,
      rowIconColor: _kGold,
      rowIconBg: _kSage,
    );
  }
}

// ── Shared economy sheet widget ───────────────────────────────────────────────

class _EconomySheet extends ConsumerWidget {
  const _EconomySheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.ids,
    required this.icons,
    required this.labels,
    required this.summaries,
    required this.buttonLabel,
    required this.firstIndicatorId,
    this.accentColor = _kDemBlue,
    this.accentBg = _kDemBlueBg,
    this.rowIconColor = _kDemBlue,
    this.rowIconBg = _kDemBlueBg,
  });

  final String title, subtitle, buttonLabel, firstIndicatorId;
  final IconData icon;
  final List<String> ids;
  final Map<String, IconData> icons;
  final Map<String, String> labels;
  final List<AsyncValue<IndicatorSummary>> summaries;
  final Color rowIconColor;
  final Color rowIconBg;
  final Color accentColor;
  final Color accentBg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: ids.length <= 2 ? 0.55 : 0.75,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW,
              height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                  color: _kSilver, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w700, color: _kSlate900)),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12, color: _kSlate600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                      color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ids.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                      icon: icons[id]!, label: labels[id]!,
                      iconColor: rowIconColor, iconBg: rowIconBg),
                  data: (summary) => _VitalRow(
                    icon: icons[id]!,
                    label: labels[id]!,
                    summary: summary,
                    iconColor: rowIconColor,
                    iconBg: rowIconBg,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath(firstIndicatorId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(buttonLabel,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── International Trade bottom sheet ─────────────────────────────────────────

void _showInternationalTradeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _InternationalTradeSheet(),
  );
}

class _InternationalTradeSheet extends ConsumerWidget {
  const _InternationalTradeSheet();

  static const _ids = [
    'trade_total',
    'trade_imports_hs',
    'trade_non_oil_exports',
    'trade_sector_country',
    'trade_reexports_annual',
    'trade_reexports_monthly',
  ];

  static const _icons = {
    'trade_total':             Icons.swap_horiz_rounded,
    'trade_imports_hs':        Icons.download_rounded,
    'trade_non_oil_exports':   Icons.upload_rounded,
    'trade_sector_country':    Icons.public_rounded,
    'trade_reexports_annual':  Icons.sync_rounded,
    'trade_reexports_monthly': Icons.calendar_month_outlined,
  };

  static const _labels = {
    'trade_total':             'Total Trade',
    'trade_imports_hs':        'Imports by HS Section',
    'trade_non_oil_exports':   'Non-Oil Exports',
    'trade_sector_country':    'Sector & Country',
    'trade_reexports_annual':  'Annual Re-Exports',
    'trade_reexports_monthly': 'Monthly Re-Exports',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW,
              height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                color: _kSilver,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kSage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    size: 20, color: _kGold),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('International Trade',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w700, color: _kSlate900)),
                    Text('Economy · 6 Indicators',
                        style: TextStyle(fontSize: 12, color: _kSlate600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                      color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kGold,
                    iconBg: _kSage,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kGold,
                    iconBg: _kSage,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('trade_total'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View All Trade Data',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── National Accounts bottom sheet ───────────────────────────────────────────

void _showNationalAccountsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _NationalAccountsSheet(),
  );
}

class _NationalAccountsSheet extends ConsumerWidget {
  const _NationalAccountsSheet();

  static const _ids = [
    'gdp_current',
    'gdp_constant',
    'gdp_quarterly_current',
    'gdp_quarterly_constant',
  ];

  static const _icons = {
    'gdp_current':            Icons.account_balance_outlined,
    'gdp_constant':           Icons.show_chart_rounded,
    'gdp_quarterly_current':  Icons.calendar_today_outlined,
    'gdp_quarterly_constant': Icons.calendar_month_outlined,
  };

  static const _labels = {
    'gdp_current':            'GDP (Current Prices)',
    'gdp_constant':           'GDP (Constant Prices)',
    'gdp_quarterly_current':  'Quarterly GDP (Current)',
    'gdp_quarterly_constant': 'Quarterly GDP (Constant)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW,
              height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                color: _kSilver,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kSage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_outlined,
                    size: 20, color: _kGold),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('National Accounts',
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.w700, color: _kSlate900)),
                    Text('Economy · 4 Indicators',
                        style: TextStyle(fontSize: 12, color: _kSlate600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kGold,
                    iconBg: _kSage,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kGold,
                    iconBg: _kSage,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('gdp_current'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGold,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View All National Accounts Data',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Labor Force bottom sheet ──────────────────────────────────────────────────

void _showLaborSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _LaborSheet(),
  );
}

class _LaborSheet extends ConsumerWidget {
  const _LaborSheet();

  static const _ids = [
    'labour_economic_activity',
    'labour_employed_age_gender',
    'labour_employed_education',
    'labour_employment_sector',
    'labour_unemployment_education',
    'labour_workforce_occupation',
    'labour_unemployment_age_gender',
  ];

  static const _icons = {
    'labour_economic_activity':       Icons.trending_up_rounded,
    'labour_employed_age_gender':     Icons.people_outline,
    'labour_employed_education':      Icons.school_outlined,
    'labour_employment_sector':       Icons.business_outlined,
    'labour_unemployment_education':  Icons.school_outlined,
    'labour_workforce_occupation':    Icons.work_outline,
    'labour_unemployment_age_gender': Icons.person_search_outlined,
  };

  static const _labels = {
    'labour_economic_activity':       'Economic Activity',
    'labour_employed_age_gender':     'Employed by Age & Gender',
    'labour_employed_education':      'Employed by Education Status',
    'labour_employment_sector':       'Employment by Sector',
    'labour_unemployment_education':  'Unemployment by Education',
    'labour_workforce_occupation':    'Workforce by Occupation',
    'labour_unemployment_age_gender': 'Unemployment by Age & Gender',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries =
        _ids.map((id) => ref.watch(indicatorSummaryProvider(id))).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.50,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet)),
          boxShadow: AppColors.shadowSheet,
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: AppSpacing.sheetHandleW,
              height: AppSpacing.sheetHandleH,
              decoration: BoxDecoration(
                color: _kSilver,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _kDemBlueBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline, size: 20, color: _kDemBlue),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Labor Force',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                    Text('Demography · 7 Indicators',
                        style: TextStyle(fontSize: 12, color: _kSlate600)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: _kPearl, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: _kSlate600),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kPearl),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _ids.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, color: _kPearl),
              itemBuilder: (_, i) {
                final id = _ids[i];
                final async = summaries[i];
                return async.when(
                  loading: () => const _VitalRowShimmer(),
                  error: (_, __) => _VitalRowEmpty(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    iconColor: _kDemBlue,
                    iconBg: _kDemBlueBg,
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.indicatorPath(id));
                    },
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _kPearl)),
            ),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.indicatorPath('labour_economic_activity'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kDemBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View All Labor Force Data',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.isUp, this.color});
  final List<double> points;
  final bool isUp;
  final Color? color;

  static const _fallbackUp   = [0.60, 0.65, 0.72, 0.80, 0.88, 0.95, 1.0];
  static const _fallbackDown = [1.00, 0.92, 0.85, 0.78, 0.72, 0.68, 0.62];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = points.isNotEmpty ? points : (isUp ? _fallbackUp : _fallbackDown);
    final drawColor = color ?? (isUp ? const Color(0xFF00594C) : AppColors.error);

    final paint = Paint()
      ..color = drawColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final x = (i / (pts.length - 1)) * size.width;
      final y = size.height - pts[i] * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath,
      Paint()..color = drawColor.withValues(alpha: 0.10)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Latest releases ───────────────────────────────────────────────────────────
// ── FCSC Footer ───────────────────────────────────────────────────────────────
class _FcscFooter extends StatelessWidget {
  const _FcscFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPearl,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: const Column(children: [
        Text('FCSA',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _kGreen, letterSpacing: 1.0)),
        SizedBox(height: 4),
        Text('Federal Competitiveness and Statistics Authority',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: _kSlate600, height: 1.4)),
        SizedBox(height: 4),
        Text('© 2026 United Arab Emirates',
          style: TextStyle(fontSize: 11, color: _kSlate400)),
      ]),
    );
  }
}

// ── Islamic pattern painter (hero card overlay) ───────────────────────────────
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 60.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (double x = 0; x < size.width + cellSize; x += cellSize) {
      for (double y = 0; y < size.height + cellSize; y += cellSize) {
        _drawStar(canvas, paint, Offset(x, y), cellSize * 0.38);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double r) {
    const pts = 8;
    final inner = r * 0.42;
    final path = Path();
    for (int i = 0; i < pts * 2; i++) {
      final angle = (i * math.pi / pts) - math.pi / 2;
      final rad = i.isEven ? r : inner;
      final x = center.dx + rad * math.cos(angle);
      final y = center.dy + rad * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── DemographySection (kept for backward compat with router) ─────────────────
class DemographySection extends StatelessWidget {
  const DemographySection({super.key, this.sectionKey});
  final GlobalKey? sectionKey;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

