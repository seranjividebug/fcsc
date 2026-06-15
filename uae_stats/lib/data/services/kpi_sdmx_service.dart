// lib/data/services/kpi_sdmx_service.dart
//
// Generic SDMX REST fetcher for KPI single-value extraction.
// Used by Economy, Social, and Environment section providers.
//
// Strategy:
//   1. Try Hive cache (fresh ≤ 24 h)
//   2. Live SDMX REST call
//   3. Stale cache on network error
//   4. Return null — caller shows blank '—' card (no static fallback)

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/kpi_card_data.dart';

/// Result of a single KPI fetch.
class KpiResult {
  const KpiResult({
    required this.value,
    required this.year,
    this.previousValue,
    this.previousYear,
    this.fromCache = false,
    this.historicalValues = const [],
  });

  final double value;
  final String year;
  final double? previousValue;
  final String? previousYear;
  final bool fromCache;

  /// All observed values in chronological order (oldest → newest).
  /// Populated only by [KpiSdmxService.fetchKpiSeries].
  final List<double> historicalValues;

  double? get trendPercent {
    if (previousValue == null || previousValue == 0) return null;
    return ((value - previousValue!) / previousValue!) * 100;
  }
}

class KpiSdmxService {
  KpiSdmxService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: ApiConstants.sdmxJsonHeaders,
          ),
        );

  final Dio _dio;

  static const String _boxName = 'kpi_cache_v7';
  static const Duration _ttl = ApiConstants.cacheTtl;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Fetches the latest UAE-total observation plus full historical series.
  /// Used by the home-screen KPI carousel to drive sparkline charts.
  /// Returns null if all sources fail (caller should use seed data).
  Future<KpiResult?> fetchKpiSeries(KpiConfig cfg) async {
    if (cfg.dataflowId == null) return null;

    final cacheKey = 'kpiseries_${cfg.id}';

    final cached = await _getCachedSeries(cacheKey);
    if (cached != null) return cached;

    try {
      final url = ApiConstants.dataUrl(
        dataflowId: cfg.dataflowId!,
        version: cfg.dataflowVersion,
        filter: cfg.filter,
        startPeriod: cfg.startPeriod,
      );
      final result = await _fetchAndParseSeries(url, cfg.measure);
      if (result != null) {
        await _putSeriesCache(cacheKey, result);
        return result;
      }
    } on DioException {
      final stale = await _getStale(cacheKey);
      if (stale != null) return stale.copyWith(fromCache: true);
    } catch (_) {
      final stale = await _getStale(cacheKey);
      if (stale != null) return stale.copyWith(fromCache: true);
    }

    return null;
  }

  /// Fetches the latest UAE-total observation for a given [KpiConfig].
  /// Returns null if all sources fail (caller should use seed data).
  Future<KpiResult?> fetchKpi(KpiConfig cfg) async {
    if (cfg.dataflowId == null) return null;

    final cacheKey = 'kpi_${cfg.id}';

    // 1. Fresh cache
    final cached = await _getCached(cacheKey);
    if (cached != null) return cached;

    // 2. Live API
    try {
      final url = ApiConstants.dataUrl(
        dataflowId: cfg.dataflowId!,
        version: cfg.dataflowVersion,
        filter: cfg.filter,
        startPeriod: cfg.startPeriod,
      );
      final result = await _fetchAndParse(url, cfg.measure);
      if (result != null) {
        await _putCache(cacheKey, result);
        return result;
      }
    } on DioException {
      // Network failure → try stale cache
      final stale = await _getStale(cacheKey);
      if (stale != null) return stale.copyWith(fromCache: true);
    } catch (_) {
      // Parse / unexpected error → stale cache
      final stale = await _getStale(cacheKey);
      if (stale != null) return stale.copyWith(fromCache: true);
    }

    return null;
  }

  // ─── SDMX parsing ────────────────────────────────────────────────────────

  Future<KpiResult?> _fetchAndParseSeries(String url, String? measureFilter) async {
    final resp = await _dio.get<Map<String, dynamic>>(url);
    final body = resp.data;
    if (body == null) return null;
    return _parseSeries(body, measureFilter);
  }

  KpiResult? _parseSeries(Map<String, dynamic> root, String? measureFilter) {
    final data = root.containsKey('data')
        ? root['data'] as Map<String, dynamic>
        : root;

    final structure = _nested(data, ['structure']) ?? {};
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];
    if (dimObs.isEmpty) return null;

    final dims = dimObs.cast<Map<String, dynamic>>().map((d) {
      final vals = ((d['values'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((v) => (v['id'] ?? v['name'] ?? '').toString())
          .toList();
      return _Dim(id: (d['id'] ?? '').toString(), values: vals);
    }).toList();

    final dataSets = _nestedList(data, ['dataSets']) ?? [];
    if (dataSets.isEmpty) return null;

    final observations =
        (dataSets.first as Map<String, dynamic>)['observations']
            as Map<String, dynamic>?;
    if (observations == null || observations.isEmpty) return null;

    const emirateSet = {
      'AE-AZ', 'AE-DU', 'AE-SH', 'AE-AJ', 'AE-RK', 'AE-FJ', 'AE-UQ'
    };
    final emirateSums = <String, double>{};
    final nationalMap = <String, double>{};

    for (final entry in observations.entries) {
      final indices = entry.key.split(':');
      final valueArr = entry.value as List?;
      if (valueArr == null || valueArr.isEmpty || valueArr[0] == null) continue;
      final val = (valueArr[0] as num).toDouble();

      final dmap = <String, String>{};
      for (int i = 0; i < dims.length && i < indices.length; i++) {
        final idx = int.tryParse(indices[i]);
        if (idx != null && idx < dims[i].values.length) {
          dmap[dims[i].id] = dims[i].values[idx];
        }
      }

      final area        = dmap['REF_AREA'];
      final gender      = dmap['GENDER'];
      final citizenship = dmap['CITIZENSHIP'] ?? dmap['NATIONALITY'] ?? dmap['CIVIL_STATUS'] ?? dmap['CITIZEN'];
      final period      = dmap['TIME_PERIOD'] ?? '';
      final measure     = dmap['MEASURE'] ?? dmap['INDICATOR'];

      if (gender != null && gender != '_T') continue;
      if (citizenship != null && citizenship != '_T' && citizenship != '_Z') continue;
      if (measureFilter != null && measure != null && measure != measureFilter) continue;

      if (area != null && emirateSet.contains(area)) {
        emirateSums[period] = (emirateSums[period] ?? 0) + val;
      } else if (area == 'AE' || area == null) {
        nationalMap[period] ??= val;
      }
    }

    // Prefer emirate sum; fall back to AE national row.
    final source = emirateSums.isNotEmpty ? emirateSums : nationalMap;
    final obs = source.entries
        .map((e) => _Obs(period: e.key, value: e.value))
        .toList();
    if (obs.isEmpty) return null;

    // Sort chronologically oldest→newest for sparkline.
    obs.sort((a, b) => a.period.compareTo(b.period));

    final historical = obs.map((o) => o.value).toList();
    final latest = obs.last;
    final prev = obs.length > 1 ? obs[obs.length - 2] : null;

    return KpiResult(
      value: latest.value,
      year: latest.period,
      previousValue: prev?.value,
      previousYear: prev?.period,
      historicalValues: historical,
    );
  }

  Future<KpiResult?> _fetchAndParse(String url, String? measureFilter) async {
    final resp = await _dio.get<Map<String, dynamic>>(url);
    final body = resp.data;
    if (body == null) return null;

    return _parseLatest(body, measureFilter);
  }

  KpiResult? _parseLatest(Map<String, dynamic> root, String? measureFilter) {
    final data = root.containsKey('data')
        ? root['data'] as Map<String, dynamic>
        : root;

    final structure = _nested(data, ['structure']) ?? {};
    final dimObs =
        _nestedList(structure, ['dimensions', 'observation']) ?? [];
    if (dimObs.isEmpty) return null;

    // Build dimension lookup: index i → List<String> of code values
    final dims = dimObs.cast<Map<String, dynamic>>().map((d) {
      final vals = ((d['values'] as List?) ?? [])
          .cast<Map<String, dynamic>>()
          .map((v) => (v['id'] ?? v['name'] ?? '').toString())
          .toList();
      return _Dim(id: (d['id'] ?? '').toString(), values: vals);
    }).toList();

    final dataSets = _nestedList(data, ['dataSets']) ?? [];
    if (dataSets.isEmpty) return null;

    final observations =
        (dataSets.first as Map<String, dynamic>)['observations']
            as Map<String, dynamic>?;
    if (observations == null || observations.isEmpty) return null;

    const emirateSetL = {
      'AE-AZ', 'AE-DU', 'AE-SH', 'AE-AJ', 'AE-RK', 'AE-FJ', 'AE-UQ'
    };
    final emirateSumsL = <String, double>{};
    final nationalMapL = <String, double>{};

    for (final entry in observations.entries) {
      final indices = entry.key.split(':');
      final valueArr = entry.value as List?;
      if (valueArr == null || valueArr.isEmpty || valueArr[0] == null) continue;
      final val = (valueArr[0] as num).toDouble();

      final dmap = <String, String>{};
      for (int i = 0; i < dims.length && i < indices.length; i++) {
        final idx = int.tryParse(indices[i]);
        if (idx != null && idx < dims[i].values.length) {
          dmap[dims[i].id] = dims[i].values[idx];
        }
      }

      final area        = dmap['REF_AREA'];
      final gender      = dmap['GENDER'];
      final citizenship = dmap['CITIZENSHIP'] ?? dmap['NATIONALITY'] ?? dmap['CIVIL_STATUS'] ?? dmap['CITIZEN'];
      final period      = dmap['TIME_PERIOD'] ?? '';
      final measure     = dmap['MEASURE'] ?? dmap['INDICATOR'];

      if (gender != null && gender != '_T') continue;
      if (citizenship != null && citizenship != '_T' && citizenship != '_Z') continue;
      if (measureFilter != null && measure != null && measure != measureFilter) continue;

      if (area != null && emirateSetL.contains(area)) {
        emirateSumsL[period] = (emirateSumsL[period] ?? 0) + val;
      } else if (area == 'AE' || area == null) {
        nationalMapL[period] ??= val;
      }
    }

    final sourceL = emirateSumsL.isNotEmpty ? emirateSumsL : nationalMapL;
    if (sourceL.isEmpty) return null;

    // Sort by period descending and take latest two.
    final obs = sourceL.entries
        .map((e) => _Obs(period: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.period.compareTo(a.period));

    final latest = obs.first;
    final prev = obs.length > 1 ? obs[1] : null;

    return KpiResult(
      value: latest.value,
      year: latest.period,
      previousValue: prev?.value,
      previousYear: prev?.period,
    );
  }

  // ─── Hive cache ──────────────────────────────────────────────────────────

  Future<Box> _openBox() async => Hive.openBox(_boxName);

  Future<KpiResult?> _getCached(String key) async {
    final box = await _openBox();
    final entry = box.get(key) as Map?;
    if (entry == null) return null;
    final ts = entry['ts'] as int?;
    if (ts == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _ttl.inMilliseconds) return null;
    return _decodeResult(entry);
  }

  Future<KpiResult?> _getStale(String key) async {
    final box = await _openBox();
    final entry = box.get(key) as Map?;
    if (entry == null) return null;
    return _decodeResult(entry);
  }

  Future<void> _putCache(String key, KpiResult result) async {
    final box = await _openBox();
    await box.put(key, {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'value': result.value,
      'year': result.year,
      'prevValue': result.previousValue,
      'prevYear': result.previousYear,
    });
  }

  KpiResult _decodeResult(Map entry) => KpiResult(
        value: (entry['value'] as num).toDouble(),
        year: entry['year'] as String? ?? '',
        previousValue: (entry['prevValue'] as num?)?.toDouble(),
        previousYear: entry['prevYear'] as String?,
        fromCache: true,
      );

  Future<KpiResult?> _getCachedSeries(String key) async {
    final box = await _openBox();
    final entry = box.get(key) as Map?;
    if (entry == null) return null;
    final ts = entry['ts'] as int?;
    if (ts == null) return null;
    if (DateTime.now().millisecondsSinceEpoch - ts > _ttl.inMilliseconds) return null;
    return _decodeSeriesResult(entry);
  }

  Future<void> _putSeriesCache(String key, KpiResult result) async {
    final box = await _openBox();
    await box.put(key, {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'value': result.value,
      'year': result.year,
      'prevValue': result.previousValue,
      'prevYear': result.previousYear,
      'hist': result.historicalValues,
    });
  }

  KpiResult _decodeSeriesResult(Map entry) => KpiResult(
        value: (entry['value'] as num).toDouble(),
        year: entry['year'] as String? ?? '',
        previousValue: (entry['prevValue'] as num?)?.toDouble(),
        previousYear: entry['prevYear'] as String?,
        fromCache: true,
        historicalValues: ((entry['hist'] as List?) ?? [])
            .whereType<num>()
            .map((n) => n.toDouble())
            .toList(),
      );

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Map<String, dynamic>? _nested(Map<String, dynamic> m, List<String> keys) {
    dynamic cur = m;
    for (final k in keys) {
      if (cur is! Map<String, dynamic>) return null;
      cur = cur[k];
    }
    return cur is Map<String, dynamic> ? cur : null;
  }

  List? _nestedList(Map<String, dynamic> m, List<String> keys) {
    dynamic cur = m;
    for (final k in keys) {
      if (cur is! Map<String, dynamic>) return null;
      cur = cur[k];
    }
    return cur is List ? cur : null;
  }
}

class _Dim {
  const _Dim({required this.id, required this.values});
  final String id;
  final List<String> values;
}

class _Obs {
  const _Obs({required this.period, required this.value});
  final String period;
  final double value;
}

extension on KpiResult {
  KpiResult copyWith({bool? fromCache}) => KpiResult(
        value: value,
        year: year,
        previousValue: previousValue,
        previousYear: previousYear,
        fromCache: fromCache ?? this.fromCache,
        historicalValues: historicalValues,
      );
}
