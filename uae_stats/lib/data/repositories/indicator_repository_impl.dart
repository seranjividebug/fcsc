// lib/data/repositories/indicator_repository_impl.dart
//
// Data access chain:
//   1. Hive cache (if fresh, ≤ 24 hours)
//   2. Live SDMX API (FCSC REST endpoint)
//   3. Stale cache (if available)

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';
import 'package:uae_stats/data/models/localized_string.dart';
import 'package:uae_stats/data/repositories/indicator_repository.dart';
import 'package:uae_stats/data/sources/local_cache.dart';
import 'package:uae_stats/data/sources/sdmx_api_client.dart'
    show SdmxApiClient, SdmxResult;

class IndicatorRepositoryImpl implements IndicatorRepository {
  IndicatorRepositoryImpl({
    SdmxApiClient? apiClient,
    LocalCache? cache,
  })  : _api = apiClient ?? SdmxApiClient(),
        _cache = cache ?? LocalCache();

  final SdmxApiClient _api;
  final LocalCache _cache;

  List<IndicatorMeta>? _metaIndex;

  // ─── Public interface ─────────────────────────────────────────────────────

  @override
  Future<IndicatorData> getIndicator(String indicatorId) async {
    final meta = await _getMeta(indicatorId);
    final cacheKey = _cacheKey(indicatorId);

    // Population module: always fetch live, fall back to seed on failure
    if (_isPopulationModule(indicatorId)) {
      try {
        final result = await _fetchFromApi(indicatorId);
        final liveData = _toIndicatorData(
          meta: meta,
          points: result.points,
          fromCache: false,
          apiPreparedAt: result.preparedAt,
        );
        if (_hasUsableSeries(liveData)) {
          await _cache.put(cacheKey, result.points);
          return liveData;
        }
      } catch (_) {}
      // Live fetch failed or returned empty — try seed file
      final seed = await _loadSeed(indicatorId);
      if (seed.isNotEmpty) {
        return IndicatorData(
          meta: meta,
          allPoints: seed,
          fetchedAt: DateTime.now(),
          fromCache: true,
        );
      }
      return IndicatorData(
        meta: meta,
        allPoints: const [],
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
    }

    // Education & health: always try live API first, then seed — skip cache
    // to avoid serving previously-cached zero values
    if (_hasSeed(indicatorId)) {
      try {
        final result = await _fetchFromApi(indicatorId);
        final liveData = _toIndicatorData(
          meta: meta,
          points: result.points,
          fromCache: false,
          apiPreparedAt: result.preparedAt,
        );
        if (_hasUsableSeries(liveData)) {
          await _cache.put(cacheKey, result.points);
          return liveData;
        }
      } catch (_) {}
      // API failed or empty — load seed
      final seed = await _loadSeed(indicatorId);
      return IndicatorData(
        meta: meta,
        allPoints: seed,
        fetchedAt: DateTime.now(),
        fromCache: seed.isNotEmpty,
      );
    }

    // All other indicators: cache → API → stale cache → seed
    final cached = _cache.getIfFresh(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return IndicatorData(
        meta: meta,
        allPoints: cached,
        fetchedAt: DateTime.now().subtract(_cache.cacheAge(cacheKey)!),
        fromCache: true,
      );
    }

    try {
      final result = await _fetchFromApi(indicatorId);
      final liveData = _toIndicatorData(
        meta: meta,
        points: result.points,
        fromCache: false,
        apiPreparedAt: result.preparedAt,
      );
      if (_hasUsableSeries(liveData)) {
        await _cache.put(cacheKey, result.points);
        return liveData;
      }
    } catch (_) {}

    final staleCache = _cache.getAny(cacheKey);
    if (staleCache != null && staleCache.isNotEmpty) {
      return IndicatorData(
        meta: meta,
        allPoints: staleCache,
        fetchedAt: DateTime.now(),
        fromCache: true,
      );
    }

    // Final fallback: load bundled seed data if available
    final seed = await _loadSeed(indicatorId);
    if (seed.isNotEmpty) {
      return IndicatorData(
        meta: meta,
        allPoints: seed,
        fetchedAt: DateTime.now(),
        fromCache: true,
      );
    }

    return IndicatorData(
      meta: meta,
      allPoints: const [],
      fetchedAt: DateTime.now(),
      fromCache: false,
    );
  }

  @override
  Future<IndicatorData> refreshIndicator(String indicatorId) async {
    final meta = await _getMeta(indicatorId);
    await _cache.invalidate(_cacheKey(indicatorId));
    try {
      final result = await _fetchFromApi(indicatorId);
      final liveData = _toIndicatorData(
        meta: meta,
        points: result.points,
        fromCache: false,
        apiPreparedAt: result.preparedAt,
      );
      if (_hasUsableSeries(liveData)) {
        await _cache.put(_cacheKey(indicatorId), result.points);
        return liveData;
      }
    } catch (_) {
      // Network or parse error — fall through
    }
    final seed = await _loadSeed(indicatorId);
    if (seed.isNotEmpty) {
      return IndicatorData(
        meta: meta,
        allPoints: seed,
        fetchedAt: DateTime.now(),
        fromCache: true,
      );
    }
    return IndicatorData(
      meta: meta,
      allPoints: const [],
      fetchedAt: DateTime.now(),
      fromCache: false,
    );
  }

  @override
  Future<IndicatorSummary> getIndicatorSummary(String indicatorId) async {
    final data = await getIndicator(indicatorId);
    return data.toSummary();
  }

  @override
  Future<List<IndicatorMeta>> getAllMeta() async {
    if (_metaIndex != null) return _metaIndex!;
    try {
      final raw = await rootBundle.loadString('assets/data/indicators_index.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final list = (json['indicators'] as List).cast<Map<String, dynamic>>();
      _metaIndex = list.map(IndicatorMeta.fromJson).toList();
    } catch (_) {
      _metaIndex = [];
    }
    return _metaIndex!;
  }

  @override
  Future<void> clearCache() => _cache.clearAll();

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<SdmxResult> _fetchFromApi(String indicatorId) {
    return switch (indicatorId) {
      'population'           => _api.fetchPopulation(),
      'births'               => _api.fetchBirths(),
      'divorces'             => _api.fetchDivorces(),
      'deaths'               => _api.fetchDeaths(),
      'marriages'            => _api.fetchMarriages(),
      'student_enrolment'    => _api.fetchEducationStudents(),
      'teaching_staff'       => _api.fetchEducationTeachers(),
      'higher_education'     => _api.fetchEducationHigher(),
      'hospitals'            => _api.fetchHealthServices(),
      'health_services'      => _api.fetchHealthServices(),
      'health_clinics_centers' => _api.fetchHealthClinics(),
      'health_hospital_beds' => _api.fetchHospitalBeds(),
      'health_professionals'           => _api.fetchHealthProfessionals(),
      'prices_cpi_annual'              => _api.fetchCpiAnnual(),
      'tourism_hotel_arrivals'         => _api.fetchTourismHotelArrivals(),
      'tourism_hotel_establishments'   => _api.fetchTourismHotelEstablishments(),
      'tourism_main_indicators'        => _api.fetchTourismMainIndicators(),
      'aircraft_movement'              => _api.fetchAircraftMovement(),
      'trade_total'                    => _api.fetchTradeTotal(),
      'trade_imports_hs'               => _api.fetchTradeImportsHs(),
      'trade_non_oil_exports'          => _api.fetchTradeNonOilExports(),
      'trade_sector_country'           => _api.fetchTradeSectorCountry(),
      'trade_reexports_annual'         => _api.fetchTradeReexportsAnnual(),
      'trade_reexports_monthly'        => _api.fetchTradeReexportsMonthly(),
      'gdp_current'                    => _api.fetchGdpCurrent(),
      'gdp_constant'                   => _api.fetchGdpConstant(),
      'gdp_quarterly_current'          => _api.fetchGdpQuarterlyCurrent(),
      'gdp_quarterly_constant'         => _api.fetchGdpQuarterlyConstant(),
      'ecology_mean_temp'              => _api.fetchClimateTemp(),
      'crop_production'                => _api.fetchCropStatistics(),
      'crop_area'                      => _api.fetchCropStatistics(),
      'crop_land_total'                => _api.fetchCropLand(),
      'labour_economic_activity'       => _api.fetchEconomicActivity(),
      'labour_employed_age_gender'     => _api.fetchEmployedAgeGender(),
      'labour_employed_education'      => _api.fetchEmployedEducation(),
      'labour_employment_sector'       => _api.fetchEmploymentSector(),
      'labour_unemployment_education'  => _api.fetchUnemploymentEducation(),
      'labour_workforce_occupation'    => _api.fetchWorkforceOccupation(),
      'labour_unemployment_age_gender' => _api.fetchUnemploymentAgeGender(),
      'livestock_camel'                => _api.fetchCamelPopulation(),
      'livestock_cattle'               => _api.fetchCattlePopulation(),
      'livestock_goat'                 => _api.fetchGoatPopulation(),
      'livestock_sheep'                => _api.fetchSheepPopulation(),
      'ecology_rainfall'               => _api.fetchRainfall(),
      'ecology_produced_water'         => _api.fetchProducedWater(),
      'energy_generation_capacity'     => _api.fetchGenerationCapacity(),
      'energy_crude_oil'               => _api.fetchCrudeOil(),
      'energy_renewable'               => _api.fetchRenewableEnergy(),
      'ecology_natural_reserves'       => _api.fetchNaturalReserves(),
      'ecology_ramsar_wetlands'        => _api.fetchRamsarWetlands(),
      _                                => Future.value(const SdmxResult(points: [])),
    };
  }

  Future<IndicatorMeta> _getMeta(String indicatorId) async {
    final all = await getAllMeta();
    return all.firstWhere(
      (m) => m.id == indicatorId,
      orElse: () => _defaultMeta(indicatorId),
    );
  }

  IndicatorMeta _defaultMeta(String id) {
    final isGdp = id.startsWith('gdp_');
    final isTrade = id.startsWith('trade_');
    final isTourism = id.startsWith('tourism_');
    final isAir = id == 'aircraft_movement';
    final isPrices = id.startsWith('prices_');
    final isEcology = id.startsWith('ecology_');
    final isCrop    = id.startsWith('crop_');
    final isLivestock = id.startsWith('livestock_');
    final isEnergy = id.startsWith('energy_');
    return IndicatorMeta(
      id: id,
      dataflowId: '',
      dataflowVersion: '1.0.0',
      agencyId: 'FCSA',
      name: _nameFor(id),
      category: (isGdp || isTrade || isTourism || isPrices || isAir)
          ? 'economy'
          : (isEcology || isCrop || isLivestock || isEnergy) ? 'environment'
          : id.startsWith('labour_') ? 'demography' : 'demography',
      subCategory: isGdp ? 'national_accounts'
          : isTrade ? 'international_trade'
          : isTourism ? 'tourism'
          : isPrices ? 'prices'
          : isAir ? 'air_transport'
          : isEnergy ? 'energy'
          : isEcology ? 'ecology'
          : (isCrop || isLivestock) ? 'agriculture'
          : 'vitals',
      unit: isGdp || isTrade
          ? const LocalizedString(en: 'AED Million', ar: 'مليون درهم')
          : isTourism
          ? const LocalizedString(en: 'Persons', ar: 'أشخاص')
          : isPrices
          ? const LocalizedString(en: 'Index', ar: 'مؤشر')
          : isAir
          ? const LocalizedString(en: 'Movements', ar: 'حركة')
          : id == 'ecology_rainfall'
          ? const LocalizedString(en: 'mm', ar: 'مم')
          : id == 'ecology_produced_water'
          ? const LocalizedString(en: 'MCM', ar: 'مليون م³')
          : (id == 'energy_generation_capacity' || id == 'energy_renewable')
          ? const LocalizedString(en: 'MW', ar: 'ميجاوات')
          : id == 'energy_crude_oil'
          ? const LocalizedString(en: 'Mn Bbl', ar: 'مليون برميل')
          : (id == 'ecology_natural_reserves' || id == 'ecology_ramsar_wetlands')
          ? const LocalizedString(en: 'km²', ar: 'كم²')
          : isEcology
          ? const LocalizedString(en: '°C', ar: '°م')
          : isCrop && id == 'crop_land_total'
          ? const LocalizedString(en: 'K Donum', ar: 'ألف دونم')
          : isCrop
          ? const LocalizedString(en: 'Metric Tonnes', ar: 'طن متري')
          : isLivestock
          ? const LocalizedString(en: 'Head', ar: 'رأس')
          : const LocalizedString(en: 'Persons', ar: 'أشخاص'),
      unitCode: isGdp || isTrade ? 'AED_MN'
          : isAir ? 'MOV'
          : id == 'ecology_rainfall' ? 'MM'
          : id == 'ecology_produced_water' ? 'MCM'
          : (id == 'energy_generation_capacity' || id == 'energy_renewable') ? 'MW'
          : id == 'energy_crude_oil' ? 'MILBAR'
          : (id == 'ecology_natural_reserves' || id == 'ecology_ramsar_wetlands') ? 'KM2'
          : isEcology ? 'CEL'
          : isLivestock ? 'HEAD' : 'PS',
      frequency: 'A',
      sourceCode: 'FCSA',
      sourceName: const LocalizedString(
        en: 'Federal Competitiveness and Statistics Centre',
        ar: 'مركز الاتحادية للتنافسية والإحصاء',
      ),
      coverageStart: '2015',
      coverageEnd: '2024',
    );
  }

  LocalizedString _nameFor(String id) => switch (id) {
        'population'        => const LocalizedString(en: 'Population Estimates',      ar: 'تقديرات السكان'),
        'births'            => const LocalizedString(en: 'Births',                    ar: 'المواليد'),
        'deaths'            => const LocalizedString(en: 'Deaths',                    ar: 'الوفيات'),
        'marriages'         => const LocalizedString(en: 'Marriages',                 ar: 'الزيجات'),
        'divorces'          => const LocalizedString(en: 'Divorces',                  ar: 'الطلاق'),
        'student_enrolment' => const LocalizedString(en: 'Student',                   ar: 'الطلاب'),
        'teaching_staff'    => const LocalizedString(en: 'Teaching',                  ar: 'التدريس'),
        'higher_education'  => const LocalizedString(en: 'Higher Education',          ar: 'التعليم العالي'),
        'hospitals'         => const LocalizedString(en: 'Hospitals',                 ar: 'المستشفيات'),
        'health_services'   => const LocalizedString(en: 'Health Services',           ar: 'الخدمات الصحية'),
        'health_clinics_centers' => const LocalizedString(en: 'Clinics and Centers',  ar: 'العيادات والمراكز'),
        'health_hospital_beds'   => const LocalizedString(en: 'Hospital Beds',        ar: 'أسرة المستشفيات'),
        'health_professionals'           => const LocalizedString(en: 'Healthcare Professionals',        ar: 'المهنيون الصحيون'),
        'prices_cpi_annual'              => const LocalizedString(en: 'CPI Annual',                    ar: 'مؤشر أسعار المستهلك السنوي'),
        'tourism_hotel_arrivals'         => const LocalizedString(en: 'Hotel Guest Arrivals by Nationality', ar: 'وصول ضيوف الفنادق حسب الجنسية'),
        'tourism_hotel_establishments'   => const LocalizedString(en: 'Hotel Establishments',           ar: 'المنشآت الفندقية'),
        'tourism_main_indicators'        => const LocalizedString(en: 'Main Indicators',                ar: 'المؤشرات الرئيسية للسياحة'),
        'aircraft_movement'              => const LocalizedString(en: 'Aircraft Movement',              ar: 'حركة الطائرات'),
        'ecology_mean_temp'              => const LocalizedString(en: 'Mean Temperature',                ar: 'متوسط درجة الحرارة'),
        'crop_production'                => const LocalizedString(en: 'Crop Statistics by Emirate',      ar: 'إحصاءات المحاصيل حسب الإمارة'),
        'crop_area'                      => const LocalizedString(en: 'Agricultural Cultivated Area',    ar: 'المساحة الزراعية المزروعة'),
        'crop_land_total'                => const LocalizedString(en: 'Total Agricultural Land Use',     ar: 'إجمالي استخدام الأراضي الزراعية'),
        'trade_total'                    => const LocalizedString(en: 'Total Trade',                    ar: 'إجمالي التجارة'),
        'trade_imports_hs'               => const LocalizedString(en: 'Imports by HS Section',          ar: 'الواردات حسب أقسام النظام المنسق'),
        'trade_non_oil_exports'          => const LocalizedString(en: 'Non-Oil Exports',                ar: 'الصادرات غير النفطية'),
        'trade_sector_country'           => const LocalizedString(en: 'Sector & Country',               ar: 'القطاع والدولة'),
        'trade_reexports_annual'         => const LocalizedString(en: 'Annual Re-Exports',              ar: 'إعادة التصدير السنوية'),
        'trade_reexports_monthly'        => const LocalizedString(en: 'Monthly Re-Exports',             ar: 'إعادة التصدير الشهرية'),
        'gdp_current'                    => const LocalizedString(en: 'GDP (Current Prices)',           ar: 'الناتج المحلي بالأسعار الجارية'),
        'gdp_constant'                   => const LocalizedString(en: 'GDP (Constant Prices)',          ar: 'الناتج المحلي بالأسعار الثابتة'),
        'gdp_quarterly_current'          => const LocalizedString(en: 'Quarterly GDP (Current)',        ar: 'الناتج المحلي الفصلي - جاري'),
        'gdp_quarterly_constant'         => const LocalizedString(en: 'Quarterly GDP (Constant)',       ar: 'الناتج المحلي الفصلي - ثابت'),
        'labour_economic_activity'       => const LocalizedString(en: 'Economic Activity',              ar: 'النشاط الاقتصادي'),
        'labour_employed_age_gender'     => const LocalizedString(en: 'Employed by Age & Gender',       ar: 'العاملون حسب العمر والجنس'),
        'labour_employed_education'      => const LocalizedString(en: 'Employed by Education Status',   ar: 'العاملون حسب المستوى التعليمي'),
        'labour_employment_sector'       => const LocalizedString(en: 'Employment by Sector',           ar: 'التوظيف حسب القطاع'),
        'labour_unemployment_education'  => const LocalizedString(en: 'Unemployment by Education',      ar: 'البطالة حسب التعليم'),
        'labour_workforce_occupation'    => const LocalizedString(en: 'Workforce by Occupation',        ar: 'القوى العاملة حسب المهنة'),
        'livestock_camel'                => const LocalizedString(en: 'Camel Population',                ar: 'تعداد الإبل'),
        'livestock_cattle'               => const LocalizedString(en: 'Cattle Population',               ar: 'تعداد الأبقار'),
        'livestock_goat'                 => const LocalizedString(en: 'Goat Population',                 ar: 'تعداد الماعز'),
        'livestock_sheep'                => const LocalizedString(en: 'Sheep Population',                ar: 'تعداد الأغنام'),
        'ecology_rainfall'               => const LocalizedString(en: 'Annual Rainfall',                 ar: 'هطول الأمطار السنوي'),
        'ecology_produced_water'         => const LocalizedString(en: 'Produced Water',                  ar: 'المياه المنتجة'),
        'energy_generation_capacity'     => const LocalizedString(en: 'Generation Capacity',             ar: 'طاقة توليد الكهرباء'),
        'energy_crude_oil'               => const LocalizedString(en: 'Crude Oil',                       ar: 'النفط الخام'),
        'energy_renewable'               => const LocalizedString(en: 'Renewable Energy',                ar: 'الطاقة المتجددة'),
        'ecology_natural_reserves'       => const LocalizedString(en: 'Protected Natural Areas',         ar: 'المناطق الطبيعية المحمية'),
        'ecology_ramsar_wetlands'        => const LocalizedString(en: 'RAMSAR Wetlands',                 ar: 'مواقع رامسار'),
        'labour_unemployment_age_gender' => const LocalizedString(en: 'Unemployment by Age & Gender',   ar: 'البطالة حسب العمر والجنس'),
        _ => LocalizedString(en: id, ar: id),
      };

  String _cacheKey(String id) => switch (id) {
        'population' => ApiConstants.cacheKeyPopulation,
        'births' => ApiConstants.cacheKeyBirths,
        'divorces' => ApiConstants.cacheKeyDivorces,
        'deaths' => ApiConstants.cacheKeyDeaths,
        'marriages' => ApiConstants.cacheKeyMarriages,
        _ => 'indicator_$id',
      };

  IndicatorData _toIndicatorData({
    required IndicatorMeta meta,
    required List<DataPoint> points,
    required bool fromCache,
    String? apiPreparedAt,
  }) {
    return IndicatorData(
      meta: meta,
      allPoints: points,
      fetchedAt: DateTime.now(),
      fromCache: fromCache,
      apiPreparedAt: apiPreparedAt,
    );
  }

  bool _hasUsableSeries(IndicatorData data) {
    return data.uaeTotalSeries.isNotEmpty;
  }

  /// Returns true for indicators in the Population module.
  bool _isPopulationModule(String id) => switch (id) {
        'population' || 'births' || 'deaths' || 'marriages' || 'divorces' => true,
        _ => false,
      };

  /// Returns true if a bundled seed file exists for this indicator.
  bool _hasSeed(String id) => _seedPath(id) != null;

  /// Loads bundled seed JSON for the given indicator. Returns [] if none exists.
  Future<List<DataPoint>> _loadSeed(String indicatorId) async {
    final path = _seedPath(indicatorId);
    if (path == null) return [];
    try {
      final raw = await rootBundle.loadString(path);
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(DataPoint.fromSeedJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String? _seedPath(String id) => switch (id) {
        'population'        => 'assets/data/seeds/population_seed.json',
        'births'            => 'assets/data/seeds/births_seed.json',
        'deaths'            => 'assets/data/seeds/deaths_seed.json',
        'marriages'         => 'assets/data/seeds/marriages_seed.json',
        'divorces'          => 'assets/data/seeds/divorces_seed.json',
        'student_enrolment' => 'assets/data/seeds/student_enrolment_seed.json',
        'teaching_staff'    => 'assets/data/seeds/teaching_staff_seed.json',
        'higher_education'  => 'assets/data/seeds/higher_education_seed.json',
        'hospitals'              => 'assets/data/seeds/hospitals_seed.json',
        'health_services'        => 'assets/data/seeds/hospitals_seed.json',
        'health_clinics_centers' => 'assets/data/seeds/health_clinics_centers_seed.json',
        'health_hospital_beds'   => 'assets/data/seeds/health_hospital_beds_seed.json',
        'health_professionals'           => 'assets/data/seeds/health_professionals_seed.json',
        'prices_cpi_annual'              => 'assets/data/seeds/prices_cpi_annual_seed.json',
        'tourism_hotel_arrivals'         => 'assets/data/seeds/tourism_hotel_arrivals_seed.json',
        'tourism_hotel_establishments'   => 'assets/data/seeds/tourism_hotel_establishments_seed.json',
        'tourism_main_indicators'        => 'assets/data/seeds/tourism_main_indicators_seed.json',
        'aircraft_movement'              => 'assets/data/seeds/aircraft_movement_seed.json',
        'ecology_mean_temp'              => 'assets/data/seeds/climate_temp_seed.json',
        'crop_production'                => 'assets/data/seeds/crop_production_seed.json',
        'crop_area'                      => 'assets/data/seeds/crop_area_seed.json',
        'crop_land_total'                => 'assets/data/seeds/crop_land_total_seed.json',
        'trade_total'                    => 'assets/data/seeds/trade_total_seed.json',
        'trade_imports_hs'               => 'assets/data/seeds/trade_imports_hs_seed.json',
        'trade_non_oil_exports'          => 'assets/data/seeds/trade_non_oil_exports_seed.json',
        'trade_sector_country'           => 'assets/data/seeds/trade_sector_country_seed.json',
        'trade_reexports_annual'         => 'assets/data/seeds/trade_reexports_annual_seed.json',
        'trade_reexports_monthly'        => 'assets/data/seeds/trade_reexports_monthly_seed.json',
        'gdp_current'                    => 'assets/data/seeds/gdp_current_seed.json',
        'gdp_constant'                   => 'assets/data/seeds/gdp_constant_seed.json',
        'gdp_quarterly_current'          => 'assets/data/seeds/gdp_quarterly_current_seed.json',
        'gdp_quarterly_constant'         => 'assets/data/seeds/gdp_quarterly_constant_seed.json',
        'labour_economic_activity'       => 'assets/data/seeds/labour_economic_activity_seed.json',
        'labour_employed_age_gender'     => 'assets/data/seeds/labour_employed_age_gender_seed.json',
        'labour_employed_education'      => 'assets/data/seeds/labour_employed_education_seed.json',
        'labour_employment_sector'       => 'assets/data/seeds/labour_employment_sector_seed.json',
        'labour_unemployment_education'  => 'assets/data/seeds/labour_unemployment_education_seed.json',
        'labour_workforce_occupation'    => 'assets/data/seeds/labour_workforce_occupation_seed.json',
        'labour_unemployment_age_gender' => 'assets/data/seeds/labour_unemployment_age_gender_seed.json',
        _                                => null,
      };
}
