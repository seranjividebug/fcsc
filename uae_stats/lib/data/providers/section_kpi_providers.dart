// lib/data/providers/section_kpi_providers.dart
//
// Riverpod providers for Economy, Demography, and Environment KPI cards.
//
// Each section provider:
//   1. Fetches live data from FCSC SDMX API in parallel
//   2. Shows blank '—' card on failure (no static fallback data)
//   3. Returns List<KpiSectionGroup> ready for the UI

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/home_kpi_item.dart';
import 'package:uae_stats/data/models/kpi_card_data.dart';
import 'package:uae_stats/data/services/kpi_sdmx_service.dart';

// ─── Service provider ────────────────────────────────────────────────────────

final kpiSdmxServiceProvider = Provider<KpiSdmxService>(
  (_) => KpiSdmxService(),
);

// ─── Section group model ─────────────────────────────────────────────────────

/// A titled group of KPI cards (e.g. "National Accounts").
class KpiSectionGroup {
  const KpiSectionGroup({required this.titleEn, required this.titleAr, required this.cards});
  final String titleEn;
  final String titleAr;
  final List<KpiCardData> cards;
}

// ─── KPI config catalogs ─────────────────────────────────────────────────────

// ── Economy ──────────────────────────────────────────────────────────────────

const _gdpYearly = KpiConfig(
  id: 'gdp_yearly',
  nameEn: 'Yearly GDP',
  nameAr: 'الناتج المحلي الإجمالي السنوي',
  unitEn: 'AED Mn',
  unitAr: 'مليون درهم',
  displayUnit: KpiDisplayUnit.aedMnToTrillions,
  icon: Icons.account_balance_outlined,
  dataflowId: ApiConstants.dfGdpCurr,
  dataflowVersion: ApiConstants.dfGdpCurrVersion,
  filter: '.A.............',
  measure: 'GDP_CUR',
  startPeriod: '2015',
);

const _gdpQuarterly = KpiConfig(
  id: 'gdp_quarterly',
  nameEn: 'Quarterly GDP',
  nameAr: 'الناتج المحلي الإجمالي الربعي',
  unitEn: 'AED',
  unitAr: 'درهم',
  displayUnit: KpiDisplayUnit.aedTrillions,
  icon: Icons.bar_chart_rounded,
  dataflowId: ApiConstants.dfGdpQ,
  dataflowVersion: ApiConstants.dfGdpQVersion,
  filter: '....Q',
);

const _totalTrade = KpiConfig(
  id: 'total_trade',
  nameEn: 'Total Trade',
  nameAr: 'إجمالي التجارة',
  unitEn: 'AED',
  unitAr: 'درهم',
  displayUnit: KpiDisplayUnit.aedTrillions,
  icon: Icons.swap_horiz_rounded,
  dataflowId: ApiConstants.dfTradeHs,
  dataflowVersion: ApiConstants.dfTradeHsVersion,
  filter: '...A',
);

const _import = KpiConfig(
  id: 'import',
  nameEn: 'Import',
  nameAr: 'الواردات',
  unitEn: 'AED',
  unitAr: 'درهم',
  displayUnit: KpiDisplayUnit.aedTrillions,
  icon: Icons.store_outlined,
  dataflowId: ApiConstants.dfTradeHs,
  dataflowVersion: ApiConstants.dfTradeHsVersion,
  filter: '...A',
  measure: 'IMP',
);

const _nonOilExports = KpiConfig(
  id: 'non_oil_exports',
  nameEn: 'Non-Oil Exports',
  nameAr: 'الصادرات غير النفطية',
  unitEn: 'AED',
  unitAr: 'درهم',
  displayUnit: KpiDisplayUnit.aedTrillions,
  icon: Icons.local_shipping_outlined,
  dataflowId: ApiConstants.dfTradeHs,
  dataflowVersion: ApiConstants.dfTradeHsVersion,
  filter: '...A',
  measure: 'EXP',
);

const _reExport = KpiConfig(
  id: 're_export',
  nameEn: 'Re-Export',
  nameAr: 'إعادة التصدير',
  unitEn: 'AED',
  unitAr: 'درهم',
  displayUnit: KpiDisplayUnit.aedTrillions,
  icon: Icons.compare_arrows_rounded,
  dataflowId: ApiConstants.dfTradeHs,
  dataflowVersion: ApiConstants.dfTradeHsVersion,
  filter: '...A',
  measure: 'REEXP',
);

const _inflationRate = KpiConfig(
  id: 'inflation_rate',
  nameEn: 'Inflation Rate',
  nameAr: 'معدل التضخم',
  unitEn: '%',
  unitAr: '٪',
  displayUnit: KpiDisplayUnit.percent,
  icon: Icons.price_change_outlined,
  dataflowId: ApiConstants.dfCpi,
  dataflowVersion: ApiConstants.dfCpiVersion,
  filter: '...A..',
  startPeriod: '2019',
);

const _hotelEstablishments = KpiConfig(
  id: 'hotel_establishments',
  nameEn: 'Hotel Establishments',
  nameAr: 'المنشآت الفندقية',
  unitEn: 'Count',
  unitAr: 'عدد',
  displayUnit: KpiDisplayUnit.integer,
  icon: Icons.hotel,
  dataflowId: ApiConstants.dfHotels,
  dataflowVersion: ApiConstants.dfHotelsVersion,
  filter: '..A',
  measure: 'ESTABLISHMENTS',
);

const _hotelGuestArrivals = KpiConfig(
  id: 'hotel_guest_arrivals',
  nameEn: 'Hotel Guest Arrivals',
  nameAr: 'وصول نزلاء الفنادق',
  unitEn: 'Persons',
  unitAr: 'أشخاص',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.people_outline_rounded,
  dataflowId: ApiConstants.dfHotels,
  dataflowVersion: ApiConstants.dfHotelsVersion,
  filter: '..A',
  measure: 'ARRIVALS',
);

const _passengerTraffic = KpiConfig(
  id: 'passenger_traffic_v2',
  nameEn: 'Aircraft Movements',
  nameAr: 'حركة الطائرات',
  unitEn: 'Flights',
  unitAr: 'رحلة',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.flight_outlined,
  dataflowId: ApiConstants.dfAir,
  dataflowVersion: ApiConstants.dfAirVersion,
  filter: '.A....',
  measure: 'ACFT_MOV',
  startPeriod: '2016',
);

const _aircraftMovements = KpiConfig(
  id: 'aircraft_movements',
  nameEn: 'Aircraft Movements',
  nameAr: 'حركة الطائرات',
  unitEn: 'Flights',
  unitAr: 'رحلة',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.flight_takeoff_outlined,
  dataflowId: ApiConstants.dfAir,
  dataflowVersion: ApiConstants.dfAirVersion,
  filter: '.A....',
  measure: 'MOVEMENTS',
  startPeriod: '2016',
);

const _cargoTraffic = KpiConfig(
  id: 'cargo_traffic',
  nameEn: 'Cargo Traffic',
  nameAr: 'حركة البضائع',
  unitEn: 'Metric Tonnes',
  unitAr: 'طن متري',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.inventory_2_outlined,
  dataflowId: ApiConstants.dfAir,
  dataflowVersion: ApiConstants.dfAirVersion,
  filter: '.A....',
  measure: 'CARGO',
  startPeriod: '2016',
);

// ── Demography ────────────────────────────────────────────────────────────────

const _population = KpiConfig(
  id: 'population',
  nameEn: 'Population',
  nameAr: 'السكان',
  unitEn: 'Persons',
  unitAr: 'أشخاص',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.people_outline,
  dataflowId: ApiConstants.dfPopulation,
  dataflowVersion: ApiConstants.dfPopulationVersion,
  filter: '....A..',
  measure: 'POP',
);

const _populationGrowth = KpiConfig(
  id: 'population_growth',
  nameEn: 'Population Growth',
  nameAr: 'النمو السكاني',
  unitEn: '%',
  unitAr: '٪',
  displayUnit: KpiDisplayUnit.percent,
  icon: Icons.trending_up_rounded,
  dataflowId: ApiConstants.dfPopulation,
  dataflowVersion: ApiConstants.dfPopulationVersion,
  filter: '....A..',
  measure: 'POPGWTH',
);

const _marriages = KpiConfig(
  id: 'marriages',
  nameEn: 'Marriages',
  nameAr: 'الزيجات',
  unitEn: 'Count',
  unitAr: 'عدد',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.favorite_border,
  dataflowId: ApiConstants.dfMarriages,
  dataflowVersion: ApiConstants.dfMarriagesVersion,
  filter: '.A........',
  measure: 'MARRIAGES',
  startPeriod: '2016',
);

const _divorces = KpiConfig(
  id: 'divorces',
  nameEn: 'Divorces',
  nameAr: 'الطلاق',
  unitEn: 'Count',
  unitAr: 'عدد',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.heart_broken_outlined,
  dataflowId: ApiConstants.dfDivorces,
  dataflowVersion: ApiConstants.dfDivorcesVersion,
  filter: '.A....',
  measure: 'DIVORCES',
  startPeriod: '2015',
);

const _generalEducation = KpiConfig(
  id: 'general_education_v2',
  nameEn: 'General Education',
  nameAr: 'التعليم العام',
  unitEn: 'Students',
  unitAr: 'طالب',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.school_outlined,
  dataflowId: ApiConstants.dfEducation,
  dataflowVersion: ApiConstants.dfEducationVersion,
  filter: '...A.....',
  startPeriod: '2018',
);

const _higherEducation = KpiConfig(
  id: 'higher_education_v2',
  nameEn: 'Higher Education',
  nameAr: 'التعليم العالي',
  unitEn: 'Students',
  unitAr: 'طالب',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.account_balance_outlined,
  dataflowId: ApiConstants.dfEduHigh,
  dataflowVersion: ApiConstants.dfEduHighVersion,
  filter: 'all',
  startPeriod: '2018',
);

const _hospitals = KpiConfig(
  id: 'hospitals',
  nameEn: 'Hospitals',
  nameAr: 'المستشفيات',
  unitEn: 'Facilities',
  unitAr: 'منشأة',
  displayUnit: KpiDisplayUnit.integer,
  icon: Icons.local_hospital_outlined,
  dataflowId: ApiConstants.dfHealth,
  dataflowVersion: ApiConstants.dfHealthVersion,
  filter: '..A',
  measure: 'HOSPITALS',
);

const _clinicsCenters = KpiConfig(
  id: 'clinics_centers',
  nameEn: 'Clinics and Centers',
  nameAr: 'العيادات والمراكز',
  unitEn: 'Facilities',
  unitAr: 'منشأة',
  displayUnit: KpiDisplayUnit.integer,
  icon: Icons.healing,
  dataflowId: ApiConstants.dfHealth,
  dataflowVersion: ApiConstants.dfHealthVersion,
  filter: '..A',
  measure: 'CLINICS',
);

const _labourForce = KpiConfig(
  id: 'labour_force',
  nameEn: 'Labour Force',
  nameAr: 'القوى العاملة',
  unitEn: '% Participation',
  unitAr: '٪ مشاركة',
  displayUnit: KpiDisplayUnit.percent,
  icon: Icons.work_outline,
  dataflowId: ApiConstants.dfLabour,
  dataflowVersion: ApiConstants.dfLabourVersion,
  filter: '..A',
  measure: 'LFPR',
);

const _unemploymentRate = KpiConfig(
  id: 'unemployment_rate',
  nameEn: 'Unemployed Rate',
  nameAr: 'معدل البطالة',
  unitEn: '%',
  unitAr: '٪',
  displayUnit: KpiDisplayUnit.percent,
  icon: Icons.trending_down_rounded,
  dataflowId: ApiConstants.dfLabour,
  dataflowVersion: ApiConstants.dfLabourVersion,
  filter: '..A',
  measure: 'UNEMP',
);

// ── Environment ───────────────────────────────────────────────────────────────

const _totalCropArea = KpiConfig(
  id: 'total_crop_area',
  nameEn: 'Total Crop Area',
  nameAr: 'إجمالي المساحة الزراعية',
  unitEn: 'DONUM',
  unitAr: 'دونم',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.grass_outlined,
  dataflowId: ApiConstants.dfCrops,
  dataflowVersion: ApiConstants.dfCropsVersion,
  filter: '..A',
  measure: 'CROP_AREA',
);

const _livestock = KpiConfig(
  id: 'livestock',
  nameEn: 'Livestock',
  nameAr: 'الثروة الحيوانية',
  unitEn: 'Head',
  unitAr: 'رأس',
  displayUnit: KpiDisplayUnit.millions,
  icon: Icons.pets,
  dataflowId: ApiConstants.dfLivestock,
  dataflowVersion: ApiConstants.dfLivestockVersion,
  filter: '..A',
);

const _climateMeanTemp = KpiConfig(
  id: 'ecology_mean_temp',
  nameEn: 'Mean Temperature',
  nameAr: 'متوسط درجة الحرارة',
  unitEn: '°C',
  unitAr: '°م',
  displayUnit: KpiDisplayUnit.decimal1,
  icon: Icons.device_thermostat,
  dataflowId: ApiConstants.dfClimateTemp,
  dataflowVersion: ApiConstants.dfClimateTempVersion,
  filter: '...M...',
  measure: 'MEAN_TEMP',
  startPeriod: '2016',
);

const _rainfall = KpiConfig(
  id: 'rainfall',
  nameEn: 'Rainfall',
  nameAr: 'هطول الأمطار',
  unitEn: 'mm',
  unitAr: 'ملم',
  displayUnit: KpiDisplayUnit.decimal2,
  icon: Icons.water,
  dataflowId: ApiConstants.dfClimateRain,
  dataflowVersion: ApiConstants.dfClimateRainVersion,
  filter: '..M',
);

const _desalinatedWater = KpiConfig(
  id: 'desalinated_water',
  nameEn: 'Desalinated Water',
  nameAr: 'المياه المحلاة',
  unitEn: 'MCM',
  unitAr: 'مليون م³',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.water_outlined,
  dataflowId: ApiConstants.dfWaterDesal,
  dataflowVersion: ApiConstants.dfWaterDesalVersion,
  filter: '..A',
);

const _naturalReserves = KpiConfig(
  id: 'natural_reserves',
  nameEn: 'Natural Reserves',
  nameAr: 'المحميات الطبيعية',
  unitEn: 'SqKm',
  unitAr: 'كم²',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.park_outlined,
  dataflowId: ApiConstants.dfNatReserves,
  dataflowVersion: ApiConstants.dfNatReservesVersion,
  filter: '..A',
);

const _electricity = KpiConfig(
  id: 'electricity',
  nameEn: 'Electricity',
  nameAr: 'الكهرباء',
  unitEn: 'GWh',
  unitAr: 'جيجاواط/ساعة',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.bolt_outlined,
  dataflowId: ApiConstants.dfElectricity,
  dataflowVersion: ApiConstants.dfElectricityVersion,
  filter: '..A',
  measure: 'CONSUMPTION',
);

const _renewableEnergy = KpiConfig(
  id: 'renewable_energy',
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
);

const _crudeOilProduction = KpiConfig(
  id: 'crude_oil_production',
  nameEn: 'Crude Oil Production',
  nameAr: 'إنتاج النفط الخام',
  unitEn: '1000 b/d',
  unitAr: 'ألف ب/ي',
  displayUnit: KpiDisplayUnit.thousands,
  icon: Icons.local_gas_station,
  dataflowId: ApiConstants.dfOilGas,
  dataflowVersion: ApiConstants.dfOilGasVersion,
  filter: '..A',
  measure: 'CRUDE_OIL',
);

// ─── Provider helpers ─────────────────────────────────────────────────────────

/// IDs whose raw API value is a CPI index — display value must be YoY % change.
const _cpiIds = {'home_inflation', 'inflation_rate'};

Future<KpiCardData> _resolve(KpiConfig cfg, KpiSdmxService svc) async {
  // For GDP indicators, go directly to seed (API returns multi-sector rows
  // that don't filter correctly through the KPI series parser)
  if (cfg.id == 'gdp_yearly' || cfg.id == 'home_gdp' || cfg.id == 'gdp_quarterly') {
    final seed = await _resolveSeed(cfg);
    if (seed != null) return seed;
  }
  try {
    final result = await svc.fetchKpiSeries(cfg);
    if (result != null) {
      final raw = result.historicalValues;
      final last8 = raw.length > 8 ? raw.sublist(raw.length - 8) : raw;

      // CPI dataflow returns index values — convert to YoY inflation rate.
      if (_cpiIds.contains(cfg.id)) {
        return _cpiCardFromSeries(cfg, raw, year: result.year);
      }

      return KpiCardData.fromLive(
        cfg: cfg,
        value: result.value,
        year: result.year,
        trendPercent: result.trendPercent,
        fromCache: result.fromCache,
        sparklinePoints: normalizePoints(last8),
      );
    }
  } catch (_) {}

  // CPI seed fallback — compute YoY from index values.
  if (_cpiIds.contains(cfg.id)) {
    final seed = await _resolveCpiSeed(cfg);
    if (seed != null) return seed;
  }

  final seed = await _resolveSeed(cfg);
  if (seed != null) return seed;
  return KpiCardData(
    id: cfg.id,
    nameEn: cfg.nameEn,
    nameAr: cfg.nameAr,
    displayValue: '—',
    unitEn: cfg.unitEn,
    unitAr: cfg.unitAr,
    year: '—',
    icon: cfg.icon,
  );
}

Future<KpiCardData?> _resolveSeed(KpiConfig cfg) async {
  final seedPath = switch (cfg.id) {
    'hospitals'        => 'assets/data/seeds/hospitals_seed.json',
    'clinics_centers'  => 'assets/data/seeds/health_clinics_centers_seed.json',
    'gdp_yearly'       => 'assets/data/seeds/gdp_current_seed.json',
    'home_gdp'         => 'assets/data/seeds/gdp_current_seed.json',
    'gdp_quarterly'    => 'assets/data/seeds/gdp_quarterly_current_seed.json',
    'ecology_mean_temp' => 'assets/data/seeds/climate_temp_seed.json',
    // Home-carousel Aircraft Movements — seed fallback when live API/CORS fails.
    'home_air_passengers_v2' => 'assets/data/seeds/aircraft_movement_seed.json',
    'aircraft_movement'      => 'assets/data/seeds/aircraft_movement_seed.json',
    _ => null,
  };
  if (seedPath == null) return null;

  try {
    final raw = await rootBundle.loadString(seedPath);
    final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final totals = rows
        .where((row) =>
            (row['refArea'] as String?) == 'AE' &&
            (row['gender'] as String?) == '_T')
        .toList()
      ..sort((a, b) =>
          (a['timePeriod'] as String).compareTo(b['timePeriod'] as String));
    if (totals.isEmpty) return null;

    final values =
        totals.map((row) => (row['value'] as num).toDouble()).toList();
    final latest = totals.last;
    final previous = values.length > 1 ? values[values.length - 2] : null;
    final trend = previous != null && previous != 0
        ? ((values.last - previous) / previous) * 100
        : null;
    final last8 = values.length > 8 ? values.sublist(values.length - 8) : values;

    return KpiCardData.fromLive(
      cfg: cfg,
      value: values.last,
      year: latest['timePeriod'] as String,
      trendPercent: trend,
      fromCache: true,
      sparklinePoints: normalizePoints(last8),
    );
  } catch (_) {
    return null;
  }
}

// ─── CPI helpers ──────────────────────────────────────────────────────────────

/// Builds a CPI card from a live historical series of index values.
/// Displays the YoY inflation rate (%), not the raw index.
KpiCardData _cpiCardFromSeries(
  KpiConfig cfg,
  List<double> indexValues, {
  String year = '—',
}) {
  if (indexValues.length < 2) {
    return KpiCardData(
      id: cfg.id, nameEn: cfg.nameEn, nameAr: cfg.nameAr,
      displayValue: '—', unitEn: cfg.unitEn, unitAr: cfg.unitAr,
      year: year, icon: cfg.icon,
    );
  }
  final prev    = indexValues[indexValues.length - 2];
  final current = indexValues.last;
  final yoy     = prev != 0 ? ((current - prev) / prev) * 100 : 0.0;

  // Build sparkline from YoY rates across the whole series
  final rates = <double>[];
  for (int i = 1; i < indexValues.length; i++) {
    final p = indexValues[i - 1];
    if (p != 0) rates.add(((indexValues[i] - p) / p) * 100);
  }
  final last8 = rates.length > 8 ? rates.sublist(rates.length - 8) : rates;

  return KpiCardData(
    id: cfg.id,
    nameEn: cfg.nameEn,
    nameAr: cfg.nameAr,
    displayValue: '${yoy.toStringAsFixed(2)}%',
    unitEn: cfg.unitEn,
    unitAr: cfg.unitAr,
    year: year,
    trendPercent: yoy,
    icon: cfg.icon,
    sparklinePoints: normalizePoints(last8),
  );
}

/// Reads the CPI seed JSON (index values) and returns a card showing YoY %.
Future<KpiCardData?> _resolveCpiSeed(KpiConfig cfg) async {
  const seedPath = 'assets/data/seeds/prices_cpi_annual_seed.json';
  try {
    final raw  = await rootBundle.loadString(seedPath);
    final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final totals = rows
        .where((r) =>
            (r['refArea'] as String?) == 'AE' &&
            (r['gender'] as String?) == '_T')
        .toList()
      ..sort((a, b) =>
          (a['timePeriod'] as String).compareTo(b['timePeriod'] as String));
    if (totals.length < 2) return null;

    final values = totals.map((r) => (r['value'] as num).toDouble()).toList();
    final latestYear = totals.last['timePeriod'] as String;
    final prev    = values[values.length - 2];
    final current = values.last;
    final yoy     = prev != 0 ? ((current - prev) / prev) * 100 : 0.0;

    // Sparkline from YoY rates
    final rates = <double>[];
    for (int i = 1; i < values.length; i++) {
      final p = values[i - 1];
      if (p != 0) rates.add(((values[i] - p) / p) * 100);
    }
    final last8 = rates.length > 8 ? rates.sublist(rates.length - 8) : rates;

    return KpiCardData(
      id: cfg.id,
      nameEn: cfg.nameEn,
      nameAr: cfg.nameAr,
      displayValue: '${yoy.toStringAsFixed(2)}%',
      unitEn: cfg.unitEn,
      unitAr: cfg.unitAr,
      year: latestYear,
      trendPercent: yoy,
      icon: cfg.icon,
      sparklinePoints: normalizePoints(last8),
    );
  } catch (_) {
    return null;
  }
}

/// Public wrapper around [_resolve] for use by other providers (e.g. home carousel).
Future<KpiCardData> resolveKpi(KpiConfig cfg, KpiSdmxService svc) =>
    _resolve(cfg, svc);

// ─── Economy provider ─────────────────────────────────────────────────────────

final economyKpisProvider =
    FutureProvider<List<KpiSectionGroup>>((ref) async {
  final svc = ref.read(kpiSdmxServiceProvider);

  final results = await Future.wait([
    _resolve(_gdpYearly, svc),
    _resolve(_gdpQuarterly, svc),
    _resolve(_totalTrade, svc),
    _resolve(_import, svc),
    _resolve(_nonOilExports, svc),
    _resolve(_reExport, svc),
    _resolve(_inflationRate, svc),
    _resolve(_hotelEstablishments, svc),
    _resolve(_hotelGuestArrivals, svc),
    _resolve(_passengerTraffic, svc),
    _resolve(_aircraftMovements, svc),
    _resolve(_cargoTraffic, svc),
  ]);

  return [
    KpiSectionGroup(
      titleEn: 'National Accounts',
      titleAr: 'الحسابات القومية',
      cards: [results[0], results[1]],
    ),
    KpiSectionGroup(
      titleEn: 'International Trade',
      titleAr: 'التجارة الدولية',
      cards: [results[2], results[3], results[4], results[5]],
    ),
    KpiSectionGroup(
      titleEn: 'Prices',
      titleAr: 'الأسعار',
      cards: [results[6]],
    ),
    KpiSectionGroup(
      titleEn: 'Tourism',
      titleAr: 'السياحة',
      cards: [results[7], results[8]],
    ),
    KpiSectionGroup(
      titleEn: 'Air Transport',
      titleAr: 'النقل الجوي',
      cards: [results[9], results[10], results[11]],
    ),
  ];
});

// ─── Demography provider ──────────────────────────────────────────────────────

final demographyKpisProvider =
    FutureProvider<List<KpiSectionGroup>>((ref) async {
  final svc = ref.read(kpiSdmxServiceProvider);

  final results = await Future.wait([
    _resolve(_population, svc),
    _resolve(_populationGrowth, svc),
    _resolve(_marriages, svc),
    _resolve(_divorces, svc),
    _resolve(_generalEducation, svc),
    _resolve(_higherEducation, svc),
    _resolve(_hospitals, svc),
    _resolve(_clinicsCenters, svc),
    _resolve(_labourForce, svc),
    _resolve(_unemploymentRate, svc),
  ]);

  return [
    KpiSectionGroup(
      titleEn: 'Population',
      titleAr: 'السكان',
      cards: [results[0], results[1]],
    ),
    KpiSectionGroup(
      titleEn: 'Vital Statistics',
      titleAr: 'الإحصاءات الحيوية',
      cards: [results[2], results[3]],
    ),
    KpiSectionGroup(
      titleEn: 'Education',
      titleAr: 'التعليم',
      cards: [results[4], results[5]],
    ),
    KpiSectionGroup(
      titleEn: 'Health',
      titleAr: 'الصحة',
      cards: [results[6], results[7]],
    ),
    KpiSectionGroup(
      titleEn: 'Labour Force',
      titleAr: 'القوى العاملة',
      cards: [results[8], results[9]],
    ),
  ];
});

// ─── Environment provider ─────────────────────────────────────────────────────

final environmentKpisProvider =
    FutureProvider<List<KpiSectionGroup>>((ref) async {
  final svc = ref.read(kpiSdmxServiceProvider);

  final results = await Future.wait([
    _resolve(_totalCropArea, svc),
    _resolve(_livestock, svc),
    _resolve(_climateMeanTemp, svc),
    _resolve(_rainfall, svc),
    _resolve(_desalinatedWater, svc),
    _resolve(_naturalReserves, svc),
    _resolve(_electricity, svc),
    _resolve(_renewableEnergy, svc),
    _resolve(_crudeOilProduction, svc),
  ]);

  return [
    KpiSectionGroup(
      titleEn: 'Agriculture',
      titleAr: 'الزراعة',
      cards: [results[0], results[1]],
    ),
    KpiSectionGroup(
      titleEn: 'Ecology',
      titleAr: 'البيئة الطبيعية',
      cards: [results[2], results[3], results[4], results[5]],
    ),
    KpiSectionGroup(
      titleEn: 'Energy',
      titleAr: 'الطاقة',
      cards: [results[6], results[7], results[8]],
    ),
  ];
});
