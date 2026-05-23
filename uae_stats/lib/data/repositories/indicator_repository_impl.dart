// lib/data/repositories/indicator_repository_impl.dart
//
// Data access chain:
//   1. Hive cache (if fresh, ≤ 24 hours)
//   2. Live SDMX API (FCSC REST endpoint)
//   3. Stale cache (if available)

import 'package:uae_stats/core/constants/api_constants.dart';
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

    // Population module: always fetch live — never read from cache
    if (_isPopulationModule(indicatorId)) {
      try {
        final result = await _fetchFromApi(indicatorId);
        if (result.points.isNotEmpty) {
          await _cache.put(cacheKey, result.points);
          return IndicatorData(
            meta: meta,
            allPoints: result.points,
            fetchedAt: DateTime.now(),
            fromCache: false,
            apiPreparedAt: result.preparedAt,
          );
        }
      } catch (_) {}
      return IndicatorData(
        meta: meta,
        allPoints: const [],
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
    }

    // All other indicators: cache → API → stale cache
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
      if (result.points.isNotEmpty) {
        await _cache.put(cacheKey, result.points);
        return IndicatorData(
          meta: meta,
          allPoints: result.points,
          fetchedAt: DateTime.now(),
          fromCache: false,
          apiPreparedAt: result.preparedAt,
        );
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
      if (result.points.isNotEmpty) {
        await _cache.put(_cacheKey(indicatorId), result.points);
        return IndicatorData(
          meta: meta,
          allPoints: result.points,
          fetchedAt: DateTime.now(),
          fromCache: false,
          apiPreparedAt: result.preparedAt,
        );
      }
    } catch (_) {
      // Network or parse error — fall through
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
    return _metaIndex ??= [];
  }

  @override
  Future<void> clearCache() => _cache.clearAll();

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<SdmxResult> _fetchFromApi(String indicatorId) {
    return switch (indicatorId) {
      'population' => _api.fetchPopulation(),
      'births' => _api.fetchBirths(),
      'divorces' => _api.fetchDivorces(),
      'deaths' => _api.fetchDeaths(),
      'marriages' => _api.fetchMarriages(),
      _ => Future.value(const SdmxResult(points: [])),
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
        sourceCode: 'FCSC',
        sourceName: const LocalizedString(
          en: 'Federal Competitiveness and Statistics Centre',
          ar: 'الهيئة الاتحادية للتنافسية والإحصاء',
        ),
        coverageStart: '2015',
        coverageEnd: '2024',
      );

  LocalizedString _nameFor(String id) => switch (id) {
        'population' =>
          const LocalizedString(en: 'Population Estimates', ar: 'تقديرات السكان'),
        'births' => const LocalizedString(en: 'Births', ar: 'المواليد'),
        'deaths' => const LocalizedString(en: 'Deaths', ar: 'الوفيات'),
        'marriages' => const LocalizedString(en: 'Marriages', ar: 'الزيجات'),
        'divorces' => const LocalizedString(en: 'Divorces', ar: 'الطلاق'),
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

  /// Returns true for indicators in the Population module that must always
  /// fetch from the live FCSC API — no seed or stale-cache fallback.
  bool _isPopulationModule(String id) => switch (id) {
        'population' || 'births' || 'deaths' || 'marriages' || 'divorces' => true,
        _ => false,
      };
}
