// lib/features/indicator_detail/presentation/screens/indicator_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breadcrumb_bar.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breakdown_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/data_table_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/detail_hero_card.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/indicator_chart.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ─── Indicator nav items ──────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.id,
    required this.label,
    required this.group,
  });
  final String id;
  final String label;
  final String group;
}

const _navItems = [
  // ── Demography ──────────────────────────────────────────────────────────────
  // Population & Vitals
  _NavItem(id: 'population',         label: 'Population Estimates',    group: 'demography'),
  _NavItem(id: 'births',             label: 'Births',                  group: 'demography'),
  _NavItem(id: 'deaths',             label: 'Deaths',                  group: 'demography'),
  _NavItem(id: 'marriages',          label: 'Marriages',               group: 'demography'),
  _NavItem(id: 'divorces',           label: 'Divorces',                group: 'demography'),
  // Education
  _NavItem(id: 'student_enrolment',  label: 'Student Enrolment',       group: 'demography'),
  _NavItem(id: 'teaching_staff',     label: 'Teaching Staff',          group: 'demography'),
  _NavItem(id: 'higher_education',   label: 'Higher Education',        group: 'demography'),
  // Health
  _NavItem(id: 'hospitals',              label: 'Hospitals',           group: 'demography'),
  _NavItem(id: 'health_clinics_centers', label: 'Clinics & Centers',   group: 'demography'),
  _NavItem(id: 'health_hospital_beds',   label: 'Hospital Beds',       group: 'demography'),
  _NavItem(id: 'health_professionals',   label: 'Health Workforce',    group: 'demography'),
  // Labour
  _NavItem(id: 'labour_economic_activity',      label: 'Economic Activity',        group: 'demography'),
  _NavItem(id: 'labour_employed_age_gender',    label: 'Employed: Age & Gender',   group: 'demography'),
  _NavItem(id: 'labour_employed_education',     label: 'Employed: Education',      group: 'demography'),
  _NavItem(id: 'labour_employment_sector',      label: 'Employment by Sector',     group: 'demography'),
  _NavItem(id: 'labour_unemployment_education', label: 'Unemployment: Education',  group: 'demography'),
  _NavItem(id: 'labour_workforce_occupation',   label: 'Workforce: Occupation',    group: 'demography'),
  _NavItem(id: 'labour_unemployment_age_gender',label: 'Unemployment: Age/Gender', group: 'demography'),

  // ── Environment / Ecology ────────────────────────────────────────────────────
  _NavItem(id: 'ecology_mean_temp', label: 'Mean Temperature',           group: 'environment'),
  // Agriculture
  _NavItem(id: 'crop_production',   label: 'Crop Statistics by Emirate', group: 'environment'),
  _NavItem(id: 'crop_area',         label: 'Cultivated Area',            group: 'environment'),
  _NavItem(id: 'crop_land_total',   label: 'Total Agricultural Area',    group: 'environment'),

  // ── Economy ─────────────────────────────────────────────────────────────────
  // National Accounts
  _NavItem(id: 'gdp_current',            label: 'GDP (Current Prices)',    group: 'economy'),
  _NavItem(id: 'gdp_constant',           label: 'GDP (Constant Prices)',   group: 'economy'),
  _NavItem(id: 'gdp_quarterly_current',  label: 'Quarterly GDP (Current)', group: 'economy'),
  _NavItem(id: 'gdp_quarterly_constant', label: 'Quarterly GDP (Constant)',group: 'economy'),
  // International Trade
  _NavItem(id: 'trade_total',            label: 'Total Trade',             group: 'economy'),
  _NavItem(id: 'trade_imports_hs',       label: 'Imports by HS Section',   group: 'economy'),
  _NavItem(id: 'trade_non_oil_exports',  label: 'Non-Oil Exports',         group: 'economy'),
  _NavItem(id: 'trade_sector_country',   label: 'Sector & Country',        group: 'economy'),
  _NavItem(id: 'trade_reexports_annual', label: 'Annual Re-Exports',       group: 'economy'),
  _NavItem(id: 'trade_reexports_monthly',label: 'Monthly Re-Exports',      group: 'economy'),
  // Prices
  _NavItem(id: 'prices_cpi_annual',      label: 'CPI Annual',              group: 'economy'),
  // Tourism
  _NavItem(id: 'tourism_hotel_arrivals',       label: 'Hotel Guest Arrivals', group: 'economy'),
  _NavItem(id: 'tourism_hotel_establishments', label: 'Hotel Establishments', group: 'economy'),
  _NavItem(id: 'tourism_main_indicators',      label: 'Tourism Indicators',   group: 'economy'),
  // Air Transport
  _NavItem(id: 'aircraft_movement', label: 'Aircraft Movement', group: 'economy'),
];

/// Returns the nav-strip group ('demography' | 'economy') for a given indicator id.
String _groupFor(String id) {
  for (final item in _navItems) {
    if (item.id == id) return item.group;
  }
  // Fallback: infer from id prefix
  if (id.startsWith('gdp_') || id.startsWith('trade_') ||
      id.startsWith('tourism_') || id.startsWith('prices_') ||
      id == 'aircraft_movement') { return 'economy'; }
  if (id.startsWith('ecology_') || id.startsWith('crop_')) { return 'environment'; }
  return 'demography';
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class IndicatorDetailScreen extends ConsumerStatefulWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  ConsumerState<IndicatorDetailScreen> createState() =>
      _IndicatorDetailScreenState();
}

class _IndicatorDetailScreenState
    extends ConsumerState<IndicatorDetailScreen> {
  late String _activeId;
  final ScrollController _scrollController = ScrollController();

  static String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _catAr(String c) => switch (c) {
    'demography'  => 'الديموغرافيا',
    'economy'     => 'الاقتصاد',
    'environment' => 'البيئة',
    _             => c,
  };

  /// Returns the correct accent color for a given category string.
  static Color _accentFor(String category) => switch (category) {
        'economy'     => AppColors.champagneGold,
        'environment' => AppColors.envGreen,
        _             => AppColors.demBlue,
      };

  @override
  void initState() {
    super.initState();
    _activeId = widget.indicatorId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(indicatorDataProvider(_activeId));
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ─── App bar ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.slate900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dataAsync.maybeWhen(
                        data: (d) => isAr ? d.meta.name.ar : d.meta.name.en,
                        orElse: () => _labelFor(_activeId),
                      ),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const LanguageToggleButton(),
                ],
              ),
            ),
          ),

          // ─── Flag stripe ──────────────────────────────────────────────────
          const FlagStripe(),

          // ─── Breadcrumb ───────────────────────────────────────────────────
          dataAsync.maybeWhen(
            data: (d) => BreadcrumbBar(meta: d.meta),
            orElse: () => _BreadcrumbShimmer(),
          ),

          // ─── Indicator nav strip ──────────────────────────────────────────
          _IndicatorNavStrip(
            activeId: _activeId,
            group: _groupFor(_activeId),
            onSelect: (id) {
              _scrollToTop();
              setState(() => _activeId = id);
            },
          ),

          // ─── Scrollable body ──────────────────────────────────────────────
          Expanded(
            child: dataAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorView(
                onRetry: () =>
                    ref.invalidate(indicatorDataProvider(_activeId)),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: _accentFor(data.meta.category),
                child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero card
                    DetailHeroCard(data: data),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: IndicatorChart(
                        allSeries: data.uaeTotalSeries,
                        indicatorName: isAr ? data.meta.name.ar : data.meta.name.en,
                        indicatorId: data.meta.id,
                        accentColor: _accentFor(data.meta.category),
                        femaleSeries: _showGenderSeries(data.meta.id)
                            ? data.byGender['F'] ?? []
                            : [],
                        maleSeries: _showGenderSeries(data.meta.id)
                            ? data.byGender['M'] ?? []
                            : [],
                      ),
                    ),

                    // Stats chips row
                    const SizedBox(height: 4),
                    DataTableSection(data: data),

                    // Breakdown
                    const SizedBox(height: 10),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: BreakdownSection(data: data),
                    ),

                    // Metadata card
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MetadataCard(data: data),
                    ),

                    // Related indicators
                    const SizedBox(height: 10),
                    _RelatedIndicators(currentId: _activeId),

                    // CTA buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentFor(data.meta.category),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              icon: const SizedBox.shrink(),
                              label: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isAr ? 'مقارنة مع مؤشر آخر' : 'Compare with Another Indicator',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.go(AppRoutes.home),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _accentFor(data.meta.category),
                                side: BorderSide(
                                  color: _accentFor(data.meta.category),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isAr
                                    ? 'عرض جميع مؤشرات ${_catAr(data.meta.category)}'
                                    : 'View All ${_capitalise(data.meta.category)} Indicators',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Citation footer
                    _CitationFooter(data: data),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ),
            ),
          ),

          // ─── Bottom nav ───────────────────────────────────────────────────
          const AppBottomNavBar(),
        ],
      ),
    );
  }

  // Only show Male/Female series for these indicators
  static bool _showGenderSeries(String id) => const {
    'student_enrolment',
    'teaching_staff',
    'higher_education',
    'health_professionals',
    'labour_employed_age_gender',
    'labour_unemployment_age_gender',
  }.contains(id);

  String _labelFor(String id) {
    return _navItems
        .firstWhere((n) => n.id == id,
            orElse: () => _NavItem(
                id: id,
                label: id[0].toUpperCase() + id.substring(1).replaceAll('_', ' '),
                group: ''))
        .label;
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(indicatorDataProvider(_activeId));
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

// ─── Indicator nav strip ──────────────────────────────────────────────────────
class _IndicatorNavStrip extends StatefulWidget {
  const _IndicatorNavStrip({
    required this.activeId,
    required this.group,
    required this.onSelect,
  });

  final String activeId;
  final String group;
  final ValueChanged<String> onSelect;

  @override
  State<_IndicatorNavStrip> createState() => _IndicatorNavStripState();
}

class _IndicatorNavStripState extends State<_IndicatorNavStrip> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    for (final item in _navItems) {
      _itemKeys[item.id] = GlobalKey();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(_IndicatorNavStrip old) {
    super.didUpdateWidget(old);
    if (old.activeId != widget.activeId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActive() {
    final key = _itemKeys[widget.activeId];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.3,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (widget.group) {
      'economy'     => AppColors.champagneGold,
      'environment' => AppColors.envGreen,
      _             => AppColors.demBlue,
    };
    final items = _navItems.where((i) => i.group == widget.group).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.silver, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: items.map((item) {
            final active = item.id == widget.activeId;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                key: _itemKeys[item.id],
                onTap: () => widget.onSelect(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active ? accentColor : AppColors.silver,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: active ? Colors.white : AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Breadcrumb shimmer ───────────────────────────────────────────────────────
class _BreadcrumbShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
          ShimmerBox(width: 200, height: 12),
          Spacer(),
          ShimmerBox(width: 80, height: 12),
        ],
      ),
    );
  }
}

// ─── Metadata card ────────────────────────────────────────────────────────────
class _MetadataCard extends ConsumerWidget {
  const _MetadataCard({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final meta = data.meta;
    final rows = <_MetaRow>[
      _MetaRow(
        key: isAr ? 'تكرار التحديث' : 'Update Frequency',
        value: isAr ? _freqAr(meta.frequency) : meta.frequencyLabel,
      ),
      _MetaRow(
        key: isAr ? 'آخر تحديث' : 'Last Update',
        value: data.preparedAtForDisplay ?? data.latestPeriod,
      ),
      _MetaRow(
        key: isAr ? 'نطاق البيانات' : 'Data Coverage',
        value: data.dataRange,
      ),
      _MetaRow(
        key: isAr ? 'الوحدة' : 'Unit',
        value: isAr ? meta.unit.ar : meta.unit.en,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pearlGray,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'حول هذا المؤشر' : 'About This Indicator',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.map((r) => _MetaRowWidget(row: r)),
        ],
      ),
    );
  }

  static String _freqAr(String f) => switch (f) {
    'A' => 'سنوي',
    'M' => 'شهري',
    'Q' => 'ربع سنوي',
    _   => f,
  };
}

class _MetaRow {
  const _MetaRow({required this.key, required this.value});
  final String key;
  final String value;
}

class _MetaRowWidget extends StatelessWidget {
  const _MetaRowWidget({required this.row});
  final _MetaRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x1A0073AB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.key,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Related indicators ───────────────────────────────────────────────────────

// Visual config only — no hardcoded statistical values.
class _RelatedConfig {
  const _RelatedConfig({
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });
  final String label;
  final Color iconColor;
  final Color bgColor;
}

class _RelatedIndicators extends ConsumerWidget {
  const _RelatedIndicators({required this.currentId});

  final String currentId;

  // Returns 3 related indicator IDs based on the current indicator
  static List<String> _relatedFor(String id) {
    const groups = {
      'population':            ['births', 'deaths', 'marriages'],
      'births':                ['deaths', 'marriages', 'population'],
      'deaths':                ['births', 'marriages', 'population'],
      'marriages':             ['births', 'deaths', 'divorces'],
      'divorces':              ['marriages', 'births', 'deaths'],
      'student_enrolment':     ['teaching_staff', 'higher_education', 'population'],
      'teaching_staff':        ['student_enrolment', 'higher_education', 'population'],
      'higher_education':      ['student_enrolment', 'teaching_staff', 'population'],
      'hospitals':             ['health_clinics_centers', 'health_hospital_beds', 'health_professionals'],
      'health_clinics_centers':['hospitals', 'health_hospital_beds', 'health_professionals'],
      'health_hospital_beds':  ['hospitals', 'health_clinics_centers', 'health_professionals'],
      'health_professionals':  ['hospitals', 'health_clinics_centers', 'health_hospital_beds'],
      // Economy — National Accounts
      'gdp_current':           ['gdp_constant', 'gdp_quarterly_current', 'prices_cpi_annual'],
      'gdp_constant':          ['gdp_current', 'gdp_quarterly_constant', 'prices_cpi_annual'],
      'gdp_quarterly_current': ['gdp_current', 'gdp_quarterly_constant', 'gdp_constant'],
      'gdp_quarterly_constant':['gdp_constant', 'gdp_quarterly_current', 'gdp_current'],
      // Economy — Trade
      'trade_total':           ['trade_non_oil_exports', 'trade_imports_hs', 'trade_reexports_annual'],
      'trade_non_oil_exports': ['trade_total', 'trade_imports_hs', 'trade_reexports_annual'],
      'trade_imports_hs':      ['trade_total', 'trade_non_oil_exports', 'trade_reexports_annual'],
      'trade_reexports_annual':['trade_total', 'trade_non_oil_exports', 'trade_imports_hs'],
      'prices_cpi_annual':     ['gdp_current', 'gdp_constant', 'trade_total'],
    };
    final related = groups[id];
    if (related != null) return related;
    // Default fallback: show vitals
    return ['births', 'deaths', 'population'];
  }

  static const _allConfigs = {
    'population': _RelatedConfig(label: 'Total Population', iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'births':     _RelatedConfig(label: 'Births',           iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'deaths':     _RelatedConfig(label: 'Deaths',           iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'marriages':  _RelatedConfig(label: 'Marriages',        iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'divorces':   _RelatedConfig(label: 'Divorces',         iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'student_enrolment':      _RelatedConfig(label: 'Student Enrolment',     iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'teaching_staff':         _RelatedConfig(label: 'Teaching Staff',        iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'higher_education':       _RelatedConfig(label: 'Higher Education',      iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'hospitals':              _RelatedConfig(label: 'Hospitals',             iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'health_clinics_centers': _RelatedConfig(label: 'Clinics and Centers',   iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'health_hospital_beds':   _RelatedConfig(label: 'Hospital Beds',         iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'health_professionals':   _RelatedConfig(label: 'Health Workforce',      iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    // Economy
    'gdp_current':            _RelatedConfig(label: 'GDP (Current Prices)',   iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'gdp_constant':           _RelatedConfig(label: 'GDP (Constant Prices)',  iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'gdp_quarterly_current':  _RelatedConfig(label: 'Quarterly GDP (Current)',iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'gdp_quarterly_constant': _RelatedConfig(label: 'Quarterly GDP (Const.)',  iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'trade_total':            _RelatedConfig(label: 'Total Trade',             iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'trade_non_oil_exports':  _RelatedConfig(label: 'Non-Oil Exports',         iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'trade_imports_hs':       _RelatedConfig(label: 'Imports by HS Section',   iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'trade_reexports_annual': _RelatedConfig(label: 'Annual Re-Exports',       iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'prices_cpi_annual':      _RelatedConfig(label: 'CPI Annual',              iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'aircraft_movement':      _RelatedConfig(label: 'Aircraft Movement',      iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleIds = _relatedFor(currentId)
        .where((id) => id != currentId)
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Related Indicators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: const Text(
                  'View all →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.demBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visibleIds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final id = visibleIds[i];
              final cfg = _allConfigs[id] ??
                  const _RelatedConfig(
                    label: '—',
                    iconColor: AppColors.demBlue,
                    bgColor: AppColors.demBlueTint,
                  );
              final dataAsync = ref.watch(indicatorDataProvider(id));

              String value = '—';
              String trend = '—';
              bool trendUp = true;

              dataAsync.whenData((data) {
                final series = data.uaeTotalSeries;
                if (series.isNotEmpty) {
                  value = NumberFormatter.compact(data.latestValue);
                  if (series.length >= 2) {
                    final prev = series[series.length - 2].value;
                    if (prev != 0) {
                      final yoy =
                          (data.latestValue - prev) / prev * 100;
                      trendUp = yoy >= 0;
                      final arrow = trendUp ? '↑ +' : '↓ ';
                      trend =
                          '$arrow${yoy.abs().toStringAsFixed(1)}% vs '
                          '${series[series.length - 2].timePeriod}';
                    }
                  }
                }
              });

              return GestureDetector(
                onTap: () =>
                    context.push(AppRoutes.indicatorPath(id)),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: AppColors.shadowCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cfg.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          size: 20,
                          color: cfg.iconColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cfg.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trendUp
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Citation footer ──────────────────────────────────────────────────────────
class _CitationFooter extends StatelessWidget {
  const _CitationFooter({required this.data});

  final dynamic data;

  static String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m];

  @override
  Widget build(BuildContext context) {
    final dataYear = data.latestPeriod as String;
    final fetched = data.fetchedAt as DateTime;
    final retrievedStr = '${_monthName(fetched.month)} ${fetched.year}';
    final citation =
        "Federal Competitiveness and Statistics Authority (FCSA), "
        "'${data.meta.name.en} in the UAE — $dataYear', "
        "Retrieved $retrievedStr from uaestat.fcsa.gov.ae";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            citation,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
              fontStyle: FontStyle.italic,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: citation));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Citation copied to clipboard'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.slate900,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded,
                    size: 13, color: AppColors.demBlue),
                SizedBox(width: 4),
                Text(
                  'Copy Citation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.demBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero shimmer
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.aeGoldDeep.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          // Chart shimmer
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.demBlue,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ShimmerBox(width: double.infinity, height: 80),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 200),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.slate400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.demBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
