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
      id: 'home_inflation',
      nameEn: 'CPI Inflation',
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
      id: 'home_air_passengers_v2',
      nameEn: 'Air Passengers',
      nameAr: 'ركاب الطيران',
      unitEn: 'Persons',
      unitAr: 'أشخاص',
      displayUnit: KpiDisplayUnit.millions,
      icon: Icons.flight_rounded,
      dataflowId: ApiConstants.dfAir,
      dataflowVersion: ApiConstants.dfAirVersion,
      filter: '.A....',
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
  _CarouselEntry(
    cfg: KpiConfig(
      id: 'home_gdp',
      nameEn: 'Yearly GDP',
      nameAr: 'الناتج المحلي الإجمالي',
      unitEn: 'AED',
      unitAr: 'درهم',
      displayUnit: KpiDisplayUnit.aedTrillions,
      icon: Icons.trending_up_rounded,
      dataflowId: ApiConstants.dfGdpConst,
      dataflowVersion: ApiConstants.dfGdpConstVersion,
      filter: '.A.............',
      startPeriod: '2015',
    ),
    category: 'Economy',
    iconColor: AppColors.champagneGold,
    iconBg: AppColors.royalSand,
    categoryColor: AppColors.champagneGold,
  ),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final homeCarouselProvider = FutureProvider<List<HomeKpiItem>>((ref) async {
  final svc = ref.read(kpiSdmxServiceProvider);

  final results = await Future.wait(
    _carouselConfigs.map((c) => svc.fetchKpiSeries(c.cfg)),
  );

  return List.generate(_carouselConfigs.length, (i) {
    final c = _carouselConfigs[i];
    final result = results[i];

    if (result == null) {
      return HomeKpiItem(
        category: c.category,
        label: c.cfg.nameEn,
        displayValue: '—',
        year: '—',
        icon: c.cfg.icon,
        iconColor: c.iconColor,
        iconBg: c.iconBg,
        categoryColor: c.categoryColor,
      );
    }

    final raw = result.historicalValues;
    final last8 = raw.length > 8 ? raw.sublist(raw.length - 8) : raw;

    return HomeKpiItem(
      category: c.category,
      label: c.cfg.nameEn,
      displayValue: KpiCardData.format(result.value, c.cfg.displayUnit),
      year: result.year,
      icon: c.cfg.icon,
      iconColor: c.iconColor,
      iconBg: c.iconBg,
      categoryColor: c.categoryColor,
      trendPercent: result.trendPercent,
      sparklinePoints: normalizePoints(last8),
    );
  });
});
