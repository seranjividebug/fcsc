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
      'health_professionals' => _api.fetchHealthProfessionals(),
      _                      => Future.value(const SdmxResult(points: [])),
    };
  }

  Future<IndicatorMeta> _getMeta(String indicatorId) async {
    final all = await getAllMeta();
    return all.firstWhere(
      (m) => m.id == indicatorId,
      orElse: () => _defaultMeta(indicatorId),
    );
  }

  IndicatorMeta _defaultMeta(String id) => IndicatorMeta(
        id: id,
        dataflowId: '',
        dataflowVersion: '1.0.0',
        agencyId: 'FCSA',
        name: _nameFor(id),
        category: 'demography',
        subCategory: 'vitals',
        unit: const LocalizedString(en: 'Persons', ar: 'أشخاص'),
        unitCode: 'PS',
        frequency: 'A',
        sourceCode: 'FCSA',
        sourceName: const LocalizedString(
          en: 'Federal Competitiveness and Statistics Authority',
          ar: 'الهيئة الاتحادية للتنافسية والإحصاء',
        ),
        coverageStart: '2015',
        coverageEnd: '2024',
      );

  LocalizedString _nameFor(String id) => switch (id) {
        'population'        => const LocalizedString(en: 'Population Estimates',      ar: 'تقديرات السكان'),
        'births'            => const LocalizedString(en: 'Births',                    ar: 'المواليد'),
        'deaths'            => const LocalizedString(en: 'Deaths',                    ar: 'الوفيات'),
        'marriages'         => const LocalizedString(en: 'Marriages',                 ar: 'الزيجات'),
        'divorces'          => const LocalizedString(en: 'Divorces',                  ar: 'الطلاق'),
        'student_enrolment' => const LocalizedString(en: 'Student Enrolment',         ar: 'تسجيل الطلاب'),
        'teaching_staff'    => const LocalizedString(en: 'Teaching Staff',            ar: 'الكوادر التدريسية'),
        'higher_education'  => const LocalizedString(en: 'Higher Education Students', ar: 'طلاب التعليم العالي'),
        'hospitals'         => const LocalizedString(en: 'Hospitals',                 ar: 'المستشفيات'),
        'health_services'   => const LocalizedString(en: 'Health Services',           ar: 'الخدمات الصحية'),
        'health_clinics_centers' => const LocalizedString(en: 'Clinics and Centers',  ar: 'العيادات والمراكز'),
        'health_hospital_beds'   => const LocalizedString(en: 'Hospital Beds',        ar: 'أسرة المستشفيات'),
        'health_professionals'   => const LocalizedString(en: 'Healthcare Professionals', ar: 'المهنيون الصحيون'),
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
        'health_professionals'   => 'assets/data/seeds/health_professionals_seed.json',
        _                   => null,
      };
}
