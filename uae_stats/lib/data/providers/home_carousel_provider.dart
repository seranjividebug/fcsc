// lib/data/providers/home_carousel_provider.dart
//
// Riverpod provider for the home-screen KPI carousel.
// Fetches 5 key indicators with full historical time-series from the SDMX API.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/data/models/home_kpi_item.dart';
import 'package:uae_stats/data/models/kpi_card_data.dart';
import 'package:uae_stats/data/providers/section_kpi_providers.dart';

// ─── Carousel indicator definitions ──────────────────────────────────────────

class _CarouselEntry {
  const _CarouselEntry({
    required this.cfg,
    required this.category,
    required this.iconColor,
    required this.iconBg,
    required this.categoryColor,
  });
  final KpiConfig cfg;
  final String category;
  final Color iconColor;
  final Color iconBg;
  final Color categoryColor;
}

// Client-requested order:
//   1. Population (Demography)
//   2. Yearly GDP (Economy)
//   3. CPI Inflation (Economy)
//   4. Tourist / Visitor Arrivals (Economy) — replaces Aircraft Movements
//   5. Renewable Energy (Environment)
const _carouselConfigs = <_CarouselEntry>[
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_population',
      nameEn: 'Population',
      nameAr: 'السكان',
      unitEn: 'Persons',
      unitAr: 'أشخاص',
      displayUnit: KpiDisplayUnit.millions,
      icon: Icons.people_rounded,
      dataflowId: ApiConstants.dfPopulation,
      dataflowVersion: ApiConstants.dfPopulationVersion,
      filter: '....A..',
      measure: 'POP',
    ),
    category: 'Demography',
    iconColor: AppColors.demBlue,
    iconBg: AppColors.demBlueTint,
    categoryColor: AppColors.demBlue,
  ),
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_gdp',
      nameEn: 'Yearly GDP',
      nameAr: 'الناتج المحلي الإجمالي',
      unitEn: 'AED Mn',
      unitAr: 'مليون درهم',
      displayUnit: KpiDisplayUnit.aedMnToTrillions,
      icon: Icons.trending_up_rounded,
      // Use GDP Current dataflow — filter for UAE total (_T) annual row
      dataflowId: ApiConstants.dfGdpCurr,
      dataflowVersion: ApiConstants.dfGdpCurrVersion,
      filter: '.A.............',
      measure: 'GDP_CUR',
      startPeriod: '2015',
    ),
    category: 'Economy',
    iconColor: AppColors.champagneGold,
    iconBg: AppColors.royalSand,
    categoryColor: AppColors.champagneGold,
  ),
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_inflation',
      nameEn: 'Inflation',
      nameAr: 'معدل التضخم',
      unitEn: '%',
      unitAr: '٪',
      displayUnit: KpiDisplayUnit.percent,
      icon: Icons.trending_up_rounded,
      dataflowId: ApiConstants.dfCpi,
      dataflowVersion: ApiConstants.dfCpiVersion,
      filter: '...A..',
      startPeriod: '2019',
    ),
    category: 'Economy',
    iconColor: AppColors.champagneGold,
    iconBg: AppColors.royalSand,
    categoryColor: AppColors.champagneGold,
  ),
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_visitor_arrivals',
      nameEn: 'Guest Arrivals',
      nameAr: 'وصول النزلاء',
      unitEn: 'Persons',
      unitAr: 'أشخاص',
      displayUnit: KpiDisplayUnit.millions,
      icon: Icons.luggage_outlined,
      // Total hotel guests = visitor arrivals (DF_ALL_HOT). The DSD has 8
      // dimensions: MEASURE.UNIT_MEASURE.REF_AREA.FREQ.H_TYPE.H_INDICATOR.
      // GUEST_REGION.SOURCE_DETAIL. We pin the fully-qualified key for the
      // national total guests series — H=Hotels, NUMBER, AE, Annual,
      // H_TYPE _Z (n/a), H_INDICATOR GHH (Guests), GUEST_REGION _T (Total),
      // FCSC. Verified latest 2022 = 25,215,050. No MEASURE filter needed
      // (the key is already specific to a single observation per year).
      dataflowId: ApiConstants.dfHotels,
      dataflowVersion: ApiConstants.dfHotelsVersion,
      filter: 'H.NUMBER.AE.A._Z.GHH._T.FCSC',
      startPeriod: '2016',
    ),
    category: 'Economy',
    iconColor: AppColors.champagneGold,
    iconBg: AppColors.royalSand,
    categoryColor: AppColors.champagneGold,
  ),
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_renewable',
      nameEn: 'Renewable Energy',
      nameAr: 'الطاقة المتجددة',
      unitEn: 'GWh',
      unitAr: 'جيجاواط/ساعة',
      displayUnit: KpiDisplayUnit.thousands,
      icon: Icons.wb_sunny_outlined,
      dataflowId: ApiConstants.dfRenewable,
      dataflowVersion: ApiConstants.dfRenewableVersion,
      filter: '.A....',
      startPeriod: '2015',
    ),
    category: 'Environment',
    iconColor: AppColors.envGreen,
    iconBg: AppColors.envGreenTint,
    categoryColor: AppColors.envGreen,
  ),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Card title with its unit in parentheses, e.g. "Yearly GDP (AED)" /
/// "Renewable (GWh)". The unit lives ONLY in the title — the value below is
/// the bare scaled number (e.g. "2.03T", "5.68K"), never repeated with a unit.
String _titleWithUnit(String id, String name) => switch (id) {
      'home_gdp' => 'GDP',
      'home_renewable' => 'Renewables',
      _ => name,
    };

/// Small unit suffix shown next to the value (e.g. "5.68K GWh"). Only used
/// where the unit reads better beside the figure than in the title.
String _valueUnit(String id) => switch (id) {
      'home_renewable' => 'GWh',
      'home_gdp' => 'AED',
      _ => '',
    };

final homeCarouselProvider = FutureProvider<List<HomeKpiItem>>((ref) async {
  final svc = ref.read(kpiSdmxServiceProvider);

  final cards = await Future.wait(
    _carouselConfigs.map((c) => resolveKpi(c.cfg, svc)),
  );

  return List.generate(_carouselConfigs.length, (i) {
    final c = _carouselConfigs[i];
    final card = cards[i];

    return HomeKpiItem(
      category: c.category,
      label: _titleWithUnit(c.cfg.id, c.cfg.nameEn),
      // Bare value — unit is shown in the title, or beside the value via
      // [valueUnit] (e.g. Renewables → "5.68K GWh").
      displayValue: card.displayValue,
      valueUnit: _valueUnit(c.cfg.id),
      year: card.year,
      icon: c.cfg.icon,
      iconColor: c.iconColor,
      iconBg: c.iconBg,
      categoryColor: c.categoryColor,
      trendPercent: card.trendPercent,
      sparklinePoints: card.sparklinePoints,
    );
  });
});
