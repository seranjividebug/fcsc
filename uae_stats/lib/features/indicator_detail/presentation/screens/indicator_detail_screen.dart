// lib/features/indicator_detail/presentation/screens/indicator_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breadcrumb_bar.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breakdown_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/cpi_division_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/crop_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/crude_oil_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/cultivated_area_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/data_table_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/detail_hero_card.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/electricity_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/establishment_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/export_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/gdp_sector_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/generation_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/hotel_arrivals_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/import_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/indicator_chart.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/land_use_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/monthly_reexport_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/movement_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/produced_water_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/rainfall_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/temperature_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/tourism_breakdown.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/trade_breakdown.dart';
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
  _NavItem(id: 'population',         label: 'Population',              group: 'demography'),
  _NavItem(id: 'births',             label: 'Births',                  group: 'demography'),
  _NavItem(id: 'deaths',             label: 'Deaths',                  group: 'demography'),
  _NavItem(id: 'marriages',          label: 'Marriages',               group: 'demography'),
  _NavItem(id: 'divorces',           label: 'Divorces',                group: 'demography'),
  // Education
  _NavItem(id: 'student_enrolment',  label: 'School Students',         group: 'demography'),
  _NavItem(id: 'teaching_staff',     label: 'Qualified Teachers',      group: 'demography'),
  _NavItem(id: 'higher_education',   label: 'Students by Level',       group: 'demography'),
  // Health
  _NavItem(id: 'hospitals',              label: 'Hospitals',           group: 'demography'),
  _NavItem(id: 'health_clinics_centers', label: 'Clinics & Centers',   group: 'demography'),
  _NavItem(id: 'health_hospital_beds',   label: 'Hospital Beds',       group: 'demography'),
  _NavItem(id: 'health_professionals',   label: 'Healthcare Professionals', group: 'demography'),
  // Labour
  _NavItem(id: 'labour_economic_activity',      label: 'Employment by Activity',   group: 'demography'),
  _NavItem(id: 'labour_employed_age_gender',    label: 'Labor Force by Age',       group: 'demography'),
  _NavItem(id: 'labour_employed_education',     label: 'Labor Force: Education',   group: 'demography'),
  _NavItem(id: 'labour_employment_sector',      label: 'Employment by Sector',     group: 'demography'),
  _NavItem(id: 'labour_unemployment_education', label: 'Unemployment: Education',  group: 'demography'),
  _NavItem(id: 'labour_workforce_occupation',   label: 'Employed by Occupation', group: 'demography'),
  _NavItem(id: 'labour_unemployment_age_gender',label: 'Unemployment: Age/Gender', group: 'demography'),

  // ── Environment ──────────────────────────────────────────────────────────────
  // Agriculture
  _NavItem(id: 'crop_production',   label: 'Crops by Emirate',           group: 'environment'),
  _NavItem(id: 'crop_area',         label: 'Cultivated Area',            group: 'environment'),
  _NavItem(id: 'crop_land_total',   label: 'Total Agricultural Area',    group: 'environment'),
  // Livestock
  _NavItem(id: 'livestock_camel',   label: 'Camel Population',           group: 'environment'),
  _NavItem(id: 'livestock_cattle',  label: 'Cattle Population',          group: 'environment'),
  _NavItem(id: 'livestock_goat',    label: 'Goat Population',            group: 'environment'),
  _NavItem(id: 'livestock_sheep',   label: 'Sheep Population',           group: 'environment'),
  // Ecology
  _NavItem(id: 'ecology_mean_temp',        label: 'Mean Temperature',    group: 'environment'),
  _NavItem(id: 'ecology_rainfall',       label: 'Annual Rainfall',       group: 'environment'),
  _NavItem(id: 'ecology_produced_water', label: 'Produced Water',        group: 'environment'),
  _NavItem(id: 'ecology_natural_reserves', label: 'Protected Areas',     group: 'environment'),
  _NavItem(id: 'ecology_ramsar_wetlands',  label: 'RAMSAR Wetlands',     group: 'environment'),
  // Energy
  _NavItem(id: 'energy_generation_capacity', label: 'Generation Capacity', group: 'environment'),
  _NavItem(id: 'energy_crude_oil',           label: 'Crude Oil',           group: 'environment'),
  _NavItem(id: 'energy_renewable',           label: 'Renewable Energy',    group: 'environment'),
  _NavItem(id: 'electricity',                label: 'Electricity Consumption', group: 'environment'),

  // ── Economy ─────────────────────────────────────────────────────────────────
  // National Accounts
  _NavItem(id: 'gdp_current',            label: 'Yearly GDP (Current)',    group: 'economy'),
  _NavItem(id: 'gdp_constant',           label: 'Yearly GDP (Constant)',   group: 'economy'),
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
  _NavItem(id: 'tourism_hotel_arrivals',       label: 'Guest Arrivals', group: 'economy'),
  _NavItem(id: 'tourism_hotel_establishments', label: 'Hotel Establishments', group: 'economy'),
  _NavItem(id: 'tourism_main_indicators',      label: 'Tourism Revenue',   group: 'economy'),
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

                    // IndicatorChart manages its own horizontal padding (20)
                    // internally — no extra wrapper, so the card uses full width.
                    IndicatorChart(
                      allSeries: data.uaeTotalSeries,
                      indicatorName: isAr ? data.meta.name.ar : data.meta.name.en,
                      indicatorId: data.meta.id,
                      unitLabel: isAr ? data.meta.unit.ar : data.meta.unit.en,
                      accentColor: _accentFor(data.meta.category),
                      femaleSeries: _showGenderSeries(data.meta.id)
                          ? data.byGender['F'] ?? []
                          : [],
                      maleSeries: _showGenderSeries(data.meta.id)
                          ? data.byGender['M'] ?? []
                          : [],
                    ),

                    // Stats chips row
                    const SizedBox(height: 4),
                    DataTableSection(data: data),

                    // Breakdown
                    const SizedBox(height: 10),
                    // GDP pages REPLACE the standard Overall/By Level breakdown
                    // with a dedicated card (sector tabs for annual GDP; a
                    // By Quarter card for Quarterly GDP Current).
                    if (data.meta.id != 'gdp_current' &&
                        data.meta.id != 'gdp_constant' &&
                        data.meta.id != 'gdp_quarterly_current' &&
                        data.meta.id != 'gdp_quarterly_constant' &&
                        data.meta.id != 'trade_total' &&
                        data.meta.id != 'trade_imports_hs' &&
                        data.meta.id != 'trade_non_oil_exports' &&
                        data.meta.id != 'trade_sector_country' &&
                        data.meta.id != 'trade_reexports_annual' &&
                        data.meta.id != 'trade_reexports_monthly' &&
                        data.meta.id != 'prices_cpi_annual' &&
                        data.meta.id != 'tourism_hotel_arrivals' &&
                        data.meta.id != 'tourism_hotel_establishments' &&
                        data.meta.id != 'tourism_main_indicators' &&
                        data.meta.id != 'ecology_mean_temp' &&
                        data.meta.id != 'ecology_rainfall' &&
                        data.meta.id != 'ecology_produced_water' &&
                        data.meta.id != 'energy_generation_capacity' &&
                        data.meta.id != 'energy_renewable' &&
                        data.meta.id != 'energy_crude_oil' &&
                        data.meta.id != 'electricity' &&
                        data.meta.id != 'crop_production' &&
                        data.meta.id != 'crop_land_total' &&
                        data.meta.id != 'crop_area' &&
                        data.meta.id != 'aircraft_movement')
                      // BreakdownSection manages its own horizontal padding so
                      // the tab bar can scroll edge-to-edge (full screen width).
                      BreakdownSection(
                        data: data,
                        accentColor: _accentFor(data.meta.category),
                      ),

                    // GDP pages: tabbed breakdown replaces the standard one.
                    if (data.meta.id == 'gdp_current' ||
                        data.meta.id == 'gdp_constant' ||
                        data.meta.id == 'gdp_quarterly_current' ||
                        data.meta.id == 'gdp_quarterly_constant')
                      GdpSectorBreakdown(data: data),

                    // Total Trade: 3-tab Trade Breakdown replaces the standard one.
                    if (data.meta.id == 'trade_total')
                      TradeBreakdown(data: data),

                    // Imports by HS Section: Import Breakdown replaces it.
                    if (data.meta.id == 'trade_imports_hs')
                      ImportBreakdown(data: data),

                    // Non-Oil Exports / Sector & Country / Annual Re-Exports:
                    // Export (or Re-Export) Breakdown.
                    if (data.meta.id == 'trade_non_oil_exports' ||
                        data.meta.id == 'trade_sector_country' ||
                        data.meta.id == 'trade_reexports_annual')
                      ExportBreakdown(data: data),

                    // Monthly Re-Exports: dedicated monthly breakdown.
                    if (data.meta.id == 'trade_reexports_monthly')
                      MonthlyReExportBreakdown(data: data),

                    // CPI Annual: CPI by Division breakdown.
                    if (data.meta.id == 'prices_cpi_annual')
                      CpiDivisionBreakdown(data: data),

                    // Hotel Guest Arrivals: by-nationality breakdown.
                    if (data.meta.id == 'tourism_hotel_arrivals')
                      HotelArrivalsBreakdown(data: data),

                    // Hotel Establishments: establishment breakdown.
                    if (data.meta.id == 'tourism_hotel_establishments')
                      EstablishmentBreakdown(data: data),

                    // Tourism Main Indicators: guest & revenue breakdown.
                    if (data.meta.id == 'tourism_main_indicators')
                      TourismBreakdown(data: data),

                    // Mean Temperature: station/season/indicator breakdown.
                    if (data.meta.id == 'ecology_mean_temp')
                      TemperatureBreakdown(data: data),

                    // Annual Rainfall: station/season/month breakdown.
                    if (data.meta.id == 'ecology_rainfall')
                      RainfallBreakdown(data: data),

                    // Produced Water: entity/source/annual breakdown.
                    if (data.meta.id == 'ecology_produced_water')
                      ProducedWaterBreakdown(data: data),

                    // Aircraft Movement: Movement Breakdown replaces it.
                    if (data.meta.id == 'aircraft_movement')
                      MovementBreakdown(data: data),

                    // Generation Capacity / Renewable Energy: renewable
                    // capacity / production / growth-trend tabs.
                    if (data.meta.id == 'energy_generation_capacity' ||
                        data.meta.id == 'energy_renewable')
                      GenerationBreakdown(data: data),

                    // Crude Oil: trade flow / top production / reserves growth.
                    if (data.meta.id == 'energy_crude_oil')
                      CrudeOilBreakdown(data: data),

                    // Electricity: by emirate / sector / consumer.
                    if (data.meta.id == 'electricity')
                      ElectricityBreakdown(data: data),

                    // Crop Statistics: by emirate / crop type / area.
                    if (data.meta.id == 'crop_production')
                      CropBreakdown(data: data),

                    // Total Agricultural Land Use: emirate / use type / cover.
                    if (data.meta.id == 'crop_land_total')
                      LandUseBreakdown(data: data),

                    // Cultivated Area: overall / by emirate / top growth.
                    if (data.meta.id == 'crop_area')
                      CultivatedAreaBreakdown(data: data),

                    // Related indicators
                    const SizedBox(height: 10),
                    _RelatedIndicators(currentId: _activeId),

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

  // Only show Male/Female series for these indicators.
  // Note: education indicators (student_enrolment, teaching_staff,
  // higher_education) intentionally excluded — Total line only.
  static bool _showGenderSeries(String id) => const {
    'health_professionals',
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
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    for (final item in _navItems) {
      _itemKeys[item.id] = GlobalKey();
    }
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActive();
      _onScroll();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final left = _scrollController.offset > 4;
    final right = _scrollController.offset < pos.maxScrollExtent - 4;
    if (left != _canLeft || right != _canRight) {
      setState(() {
        _canLeft = left;
        _canRight = right;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildScroller(items, accentColor),
          // Left scroll affordance
          Positioned(
            left: 0,
            child: _NavArrow(
              icon: Icons.chevron_left_rounded,
              visible: _canLeft,
              onTap: () => _scrollBy(-140),
            ),
          ),
          // Right scroll affordance
          Positioned(
            right: 0,
            child: _NavArrow(
              icon: Icons.chevron_right_rounded,
              visible: _canRight,
              onTap: () => _scrollBy(140),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScroller(List<_NavItem> items, Color accentColor) {
    return SingleChildScrollView(
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
      );
  }
}

// ─── Nav strip scroll arrow ───────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  const _NavArrow(
      {required this.icon, required this.visible, required this.onTap});

  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 52,
            // Fade the strip edge into the arrow so chips slide under it.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: icon == Icons.chevron_left_rounded
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                end: icon == Icons.chevron_left_rounded
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                colors: [
                  AppColors.white,
                  AppColors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: AppColors.shadowCard,
              ),
              child: Icon(icon, size: 18, color: AppColors.slate600),
            ),
          ),
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
    'population': _RelatedConfig(label: 'Population', iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'births':     _RelatedConfig(label: 'Births',           iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'deaths':     _RelatedConfig(label: 'Deaths',           iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'marriages':  _RelatedConfig(label: 'Marriages',        iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'divorces':   _RelatedConfig(label: 'Divorces',         iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'student_enrolment':      _RelatedConfig(label: 'School Students',      iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'teaching_staff':         _RelatedConfig(label: 'Qualified Teachers',   iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'higher_education':       _RelatedConfig(label: 'Students by Level',    iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'hospitals':              _RelatedConfig(label: 'Hospitals',             iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'health_clinics_centers': _RelatedConfig(label: 'Clinics and Centers',   iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    'health_hospital_beds':   _RelatedConfig(label: 'Hospital Beds',         iconColor: AppColors.teal, bgColor: AppColors.tealTint),
    'health_professionals':   _RelatedConfig(label: 'Healthcare Professionals', iconColor: AppColors.demBlue, bgColor: AppColors.demBlueTint),
    // Economy
    'gdp_current':            _RelatedConfig(label: 'Yearly GDP (Current)',   iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
    'gdp_constant':           _RelatedConfig(label: 'Yearly GDP (Constant)',  iconColor: AppColors.champagneGold, bgColor: AppColors.royalSand),
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
