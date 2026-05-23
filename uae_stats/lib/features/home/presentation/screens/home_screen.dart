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
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ── Design tokens (exact from HTML spec) ─────────────────────────────────────
const _kGreen     = AppColors.emiratesGreen;  // #00594C
const _kForest    = AppColors.deepForest;     // #003D33
const _kGold      = AppColors.champagneGold;  // #C8973A
const _kSage      = AppColors.sageMist;       // #E8F1EE
const _kOffWhite  = AppColors.offWhite;       // #FAFBFC
const _kPearl     = AppColors.pearlGray;      // #F3F5F7
const _kSilver    = AppColors.silver;         // #E5E7EB
const _kSlate400  = AppColors.slate400;       // #9CA3AF
const _kSlate600  = AppColors.slate600;       // #4B5563
const _kSlate900  = AppColors.slate900;       // #0F172A


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
  String _activeFilter  = 'All';

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
    final popKpi = demography.valueOrNull?.firstOrNull?.cards.firstOrNull;
    final popValue  = popKpi?.displayValue ?? '—';
    final popChange = popKpi?.trendPercent ?? 0.0;
    final popYear   = popKpi?.year ?? '—';

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
              Icon(Icons.notifications_outlined, size: 22, color: _kSlate600),
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
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
              // Search bar
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SearchBar(),
                ),
              ),
              // Filter chips
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategorySection(
                    sectionKey: _demographyKey,
                    icon: Icons.people_rounded,
                    iconColor: _kGreen,
                    iconBg: _kSage,
                    title: isArabic ? 'الديموغرافيا' : 'Demography',
                    subtitle: isArabic ? 'السكان · الأحوال الحيوية · التعليم · الصحة · العمل · الشؤون الاجتماعية' : 'Population · Vitals · Education · Health · Labor · Social',
                    tiles: [
                      _TileData.metric(id: 'population', icon: Icons.people_outline, label: 'Population', value: popValue, change: popChange, year: popYear),
                      const _TileData.group(icon: Icons.favorite_border, label: 'Vitals', subtitle: 'Births, Deaths, Marriages…', count: 4),
                      const _TileData.group(icon: Icons.school_outlined, label: 'Education', subtitle: 'General, Higher', count: 2),
                      const _TileData.metric(id: 'health', icon: Icons.local_hospital_outlined, label: 'Health', value: '2.81/1k', change: 0.8, year: '2024'),
                      const _TileData.group(icon: Icons.security_outlined, label: 'Security & Justice', subtitle: '', count: 0, value: '94.2%', change: 0.6, year: '2024'),
                      const _TileData.group(icon: Icons.groups_outlined, label: 'Social', subtitle: 'Families, Culture, Worship…', count: 6),
                      const _TileData.fullWidth(icon: Icons.work_outline, label: 'Labor Force', subtitle: 'Total active workforce', value: '6.42M', change: 3.1, year: '2024'),
                    ],
                  ),
                ),
              ),
              // Economy section
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategorySection(
                    sectionKey: _economyKey,
                    icon: Icons.business_rounded,
                    iconColor: _kGold,
                    iconBg: AppColors.royalSand,
                    title: isArabic ? 'الاقتصاد' : 'Economy',
                    subtitle: isArabic ? 'الناتج المحلي · التجارة · الصناعة · الأسعار · السياحة' : 'GDP · Trade · Industry · Prices · Tourism',
                    tiles: const [
                      _TileData.group(icon: Icons.account_balance_outlined, label: 'National Accounts', subtitle: 'GDP, Foreign Investment', count: 3),
                      _TileData.group(icon: Icons.swap_horiz_rounded, label: 'International Trade', subtitle: 'Commodities, Services…', count: 4),
                      _TileData.group(icon: Icons.factory_outlined, label: 'Industry & Business', subtitle: 'ICT, Banking, Insurance…', count: 4),
                      _TileData.group(icon: Icons.price_change_outlined, label: 'Prices', subtitle: 'CPI & PPI', count: 2),
                      _TileData.fullWidth(icon: Icons.flight_outlined, label: 'Tourism', subtitle: 'Hotels & Air Transport', value: '', change: 0, year: '', count: 2),
                    ],
                  ),
                ),
              ),
              // Latest releases
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _LatestReleases(),
                ),
              ),
              // Environment section
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategorySection(
                    sectionKey: _environmentKey,
                    icon: Icons.eco_rounded,
                    iconColor: AppColors.teal,
                    iconBg: AppColors.tealTint,
                    title: isArabic ? 'البيئة' : 'Environment',
                    subtitle: isArabic ? 'الزراعة · الطاقة · المناخ · الموارد' : 'Agriculture · Energy · Climate · Resources',
                    tiles: const [
                      _TileData.group(icon: Icons.grass_outlined, label: 'Agriculture', subtitle: 'Crops, Livestock, Fisheries…', count: 4),
                      _TileData.group(icon: Icons.bolt_outlined, label: 'Energy', subtitle: 'Electricity, Oil & Gas, Renewable', count: 3),
                      _TileData.fullWidth(icon: Icons.park_outlined, label: 'Environment', subtitle: 'Air Quality, Reserves, Climate, Waste…', value: '', change: 0, year: '', count: 7),
                    ],
                  ),
                ),
              ),
              // Onboarding hint + latest releases (env)
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _LatestReleasesEnv(),
                ),
              ),
              // FCSC Footer
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: _FcscFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
  });

  const _TileData.metric({
    required String id,
    required IconData icon,
    required String label,
    required String value,
    required double change,
    required String year,
  }) : this._(id: id, icon: icon, label: label, value: value,
               change: change, year: year, isMetric: true);

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
class _KeyFiguresCarousel extends ConsumerWidget {
  const _KeyFiguresCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeCarouselProvider);

    return SizedBox(
      height: 152,
      child: async.when(
        loading: () => _buildList(_loadingItems),
        error: (_, __) => _buildList(_loadingItems),
        data: (items) => _buildList(items),
      ),
    );
  }

  static Widget _buildList(List<HomeKpiItem> items) => ListView.separated(
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
      iconColor: [_kGreen, _kGold, _kGold, AppColors.teal, _kGold][i],
      iconBg: [_kSage, AppColors.royalSand, AppColors.royalSand, AppColors.tealTint, AppColors.royalSand][i],
      categoryColor: [_kGreen, _kGold, _kGold, AppColors.teal, _kGold][i],
    ),
  );
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
    return Container(
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
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  static const _chips = ['All', 'Demography', 'Economy', 'Environment', 'Latest'];

  static String _label(String key, bool isArabic) {
    if (!isArabic) return key;
    const ar = {'All': 'الكل', 'Demography': 'الديموغرافيا',
      'Economy': 'الاقتصاد', 'Environment': 'البيئة', 'Latest': 'الأحدث'};
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
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 20, color: widget.iconColor),
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
                    style: const TextStyle(fontSize: 12, color: _kSlate400, height: 1.3)),
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
    // Separate full-width tiles from grid tiles
    final gridTiles = tiles.where((t) => !t.isFullWidth).toList();
    final fullTiles  = tiles.where((t) => t.isFullWidth).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        // 2-column grid
        if (gridTiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 118,
            ),
            itemCount: gridTiles.length,
            itemBuilder: (_, i) => _Tile(
              data: gridTiles[i],
              accentColor: accentColor,
              accentBg: accentBg,
            ),
          ),
        // Full-width tiles
        for (final t in fullTiles) ...[
          if (gridTiles.isNotEmpty) const SizedBox(height: 10),
          _FullWidthTile(data: t, accentColor: accentColor, accentBg: accentBg),
        ],
      ]),
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
        if (d.label == 'Vitals') {
          _showVitalsSheet(context);
        } else if (d.id != null) { context.push(AppRoutes.indicatorPath(d.id!)); }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.98 : 1.0, _pressed ? 0.98 : 1.0, 1.0, 1.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kPearl,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: _pressed
            ? Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.5)
            : null,
          boxShadow: _pressed ? [] : AppColors.shadowCard,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
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
              style: const TextStyle(fontSize: 11, color: _kSlate400)),
            const SizedBox(height: 4),
            Row(children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.accentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${d.count} indicators',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: widget.accentColor)),
                ),
              ),
            ]),
          ],
          if (hasValue) ...[
            const SizedBox(height: 2),
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
              Flexible(
                child: Text('${d.change.toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: d.change >= 0 ? AppColors.success : AppColors.error)),
              ),
              const Spacer(),
              Text(d.year,
                style: const TextStyle(fontSize: 9, color: _kSlate400)),
            ]),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()..scaleByDouble(_pressed ? 0.98 : 1.0, _pressed ? 0.98 : 1.0, 1.0, 1.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPearl,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: _pressed ? [] : AppColors.shadowCard,
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: widget.accentBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, size: 20, color: widget.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: _kSlate900)),
            if (d.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(d.subtitle,
                style: const TextStyle(fontSize: 12, color: _kSlate400)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.accentBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${d.count} indicators',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: widget.accentColor)),
              ),
            ],
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kSlate400),
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
                decoration: BoxDecoration(color: _kSage, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.favorite_border, size: 20, color: _kGreen),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vitals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kSlate900)),
                  Text('Demography · 4 indicators',
                    style: TextStyle(fontSize: 12, color: _kSlate400)),
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
                  ),
                  data: (summary) => _VitalRow(
                    icon: _icons[id]!,
                    label: _labels[id]!,
                    summary: summary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/indicator/$id');
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
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
              const SizedBox(height: 8),
              const Text('Data source: FCSC · Updated monthly',
                style: TextStyle(fontSize: 11, color: _kSlate400)),
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
  });
  final IconData icon;
  final String label;
  final IndicatorSummary summary;
  final VoidCallback? onTap;

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
            decoration: BoxDecoration(color: _kSage, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: _kGreen),
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
          decoration: BoxDecoration(color: _kSage, borderRadius: BorderRadius.circular(8)),
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
  const _VitalRowEmpty({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: _kSage, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: _kGreen),
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


// ── Sparkline painter ─────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.isUp});
  final List<double> points;
  final bool isUp;

  static const _fallbackUp   = [0.60, 0.65, 0.72, 0.80, 0.88, 0.95, 1.0];
  static const _fallbackDown = [1.00, 0.92, 0.85, 0.78, 0.72, 0.68, 0.62];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = points.isNotEmpty ? points : (isUp ? _fallbackUp : _fallbackDown);
    final drawColor = isUp ? AppColors.success : AppColors.error;

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
class _LatestReleases extends ConsumerWidget {
  const _LatestReleases();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Text(isArabic ? 'أحدث الإصدارات' : 'Latest Releases',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kSlate900)),
            const Spacer(),
            Row(children: [
              Text(isArabic ? 'عرض الكل' : 'View all',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kGreen)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: _kGreen),
            ]),
          ]),
        ),
        const Divider(height: 1, color: _kPearl),
        const _ReleaseRow(isNew: true,  tag: 'Economy',     date: '15 May 2026',
          title: 'Consumer Price Index — April 2026'),
        const Divider(height: 1, indent: 16, color: _kPearl),
        const _ReleaseRow(isNew: false, tag: 'Economy',     date: '11 May 2026',
          title: 'Tourism Statistics Q1 2026 — Hotels & Air'),
      ]),
    );
  }
}

class _LatestReleasesEnv extends ConsumerWidget {
  const _LatestReleasesEnv();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(children: [
            Text(isArabic ? 'أحدث الإصدارات' : 'Latest Releases',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kSlate900)),
            const Spacer(),
            Row(children: [
              Text(isArabic ? 'عرض الكل' : 'View all',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kGreen)),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: _kGreen),
            ]),
          ]),
        ),
        const Divider(height: 1, color: _kPearl),
        const _ReleaseRow(isNew: true,  tag: 'Environment', date: '14 May 2026',
          title: 'Renewable Energy Report — Q1 2026'),
        const Divider(height: 1, indent: 16, color: _kPearl),
        const _ReleaseRow(isNew: false, tag: 'Demography',  date: '09 May 2026',
          title: 'Annual Population Estimates 2024'),
      ]),
    );
  }
}

class _ReleaseRow extends StatelessWidget {
  const _ReleaseRow({
    required this.isNew, required this.tag,
    required this.date, required this.title,
  });
  final bool isNew;
  final String tag, date, title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isNew ? _kGreen : _kPearl,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(isNew ? 'NEW' : '·',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: isNew ? AppColors.white : _kSlate400, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _kPearl, borderRadius: BorderRadius.circular(4)),
            child: const Text('PDF',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                color: _kSlate600, letterSpacing: 0.3)),
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: _kSlate900, height: 1.3)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _kSage, borderRadius: BorderRadius.circular(999)),
              child: Text(tag,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: _kGreen)),
            ),
            const SizedBox(width: 8),
            Text(date,
              style: const TextStyle(fontSize: 11, color: _kSlate400)),
          ]),
        ])),
      ]),
    );
  }
}


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
        Text('FCSC',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _kGreen, letterSpacing: 1.0)),
        SizedBox(height: 4),
        Text('Federal Competitiveness and Statistics Centre',
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

