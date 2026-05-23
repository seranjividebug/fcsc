// lib/data/sources/sdmx_api_client.dart
//
// FCSC SDMX REST API client.
// Fetches SDMX-JSON 1.0 format and decodes it into List<DataPoint>.
//
// SDMX-JSON observation key decoding:
//   "k0:k1:k2:...:kN" → each ki is the index into dimensions[i].values
//   Value array → [observationValue, statusCode?, ...]

import 'package:dio/dio.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/data_point.dart';

/// Wraps parsed data points together with the API's own preparation timestamp.
class SdmxResult {
  const SdmxResult({required this.points, this.preparedAt});
  final List<DataPoint> points;
  final String? preparedAt; // ISO-8601 from root['meta']['prepared']
}

// Internal helper — one SDMX dimension definition
class _SdmxDimension {
  const _SdmxDimension({required this.id, required this.values});
  final String id;
  final List<String> values; // index → value code (e.g. "AE", "_T")
}

class SdmxApiClient {
  SdmxApiClient()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: ApiConstants.sdmxJsonHeaders,
          ),
        );

  final Dio _dio;

  // ─── Public fetch methods ─────────────────────────────────────────────────

  /// Fetches Population Estimates (DF_POP_ALL).
  Future<SdmxResult> fetchPopulation() async {
    return _fetch(ApiConstants.populationDataUrl);
  }

  /// Fetches Births (DF_BIRTHS).
  Future<SdmxResult> fetchBirths() async {
    return _fetch(ApiConstants.birthsDataUrl);
  }

  /// Fetches Divorces (DF_DV_NA).
  Future<SdmxResult> fetchDivorces() async {
    return _fetch(ApiConstants.divorcesDataUrl);
  }

  /// Fetches Deaths (DF_DEATHS).
  Future<SdmxResult> fetchDeaths() async {
    return _fetch(ApiConstants.deathsDataUrl);
  }

  /// Fetches Marriages (DF_MR_NA).
  Future<SdmxResult> fetchMarriages() async {
    return _fetch(ApiConstants.marriagesDataUrl);
  }

  // ─── Core fetch + parse ───────────────────────────────────────────────────

  Future<SdmxResult> _fetch(String url) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final body = response.data;
    if (body == null) throw const SdmxParseException('Empty API response');
    final points = _parseSdmxJson(body);
    final preparedAt =
        (body['meta'] as Map<String, dynamic>?)?['prepared'] as String?;
    return SdmxResult(points: points, preparedAt: preparedAt);
  }

  // ─── SDMX-JSON 1.0 parser ────────────────────────────────────────────────

  List<DataPoint> _parseSdmxJson(Map<String, dynamic> root) {
    // The SDMX-JSON envelope may use 'data' or place structure at root level.
    final data = root.containsKey('data')
        ? root['data'] as Map<String, dynamic>
        : root;

    // ── 1. Extract dimension definitions ──
    final structure = _nestedMap(data, ['structure']) ??
        _nestedMap(root, ['structure']) ??
        {};
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];

    if (dimObs.isEmpty) {
      throw SdmxParseException(
        'No dimensions found in response structure. '
        'Keys: ${structure.keys.toList()}',
      );
    }

    final dimensions = dimObs
        .cast<Map<String, dynamic>>()
        .map((d) {
          final rawVals = (d['values'] as List?) ?? [];
          final valueIds = rawVals
              .cast<Map<String, dynamic>>()
              .map((v) => (v['id'] ?? v['name'] ?? '').toString())
              .toList();
          return _SdmxDimension(
            id: (d['id'] ?? '').toString(),
            values: valueIds,
          );
        })
        .toList();

    // ── 2. Extract datasets ──
    final dataSets = _nestedList(data, ['dataSets']) ??
        _nestedList(root, ['dataSets']) ??
        [];

    if (dataSets.isEmpty) {
      throw const SdmxParseException('No dataSets found in response');
    }

    final observations = (dataSets.first as Map<String, dynamic>)['observations']
        as Map<String, dynamic>?;

    if (observations == null || observations.isEmpty) {
      return []; // Valid empty dataset
    }

    // ── 3. Decode each observation ──
    final result = <DataPoint>[];

    for (final entry in observations.entries) {
      // Key: "0:1:2:3:4" → indices into each dimension's values list
      final indices = entry.key.split(':');

      // Value array: [numericValue, statusCode?, ...]
      final valueArr = entry.value as List?;
      if (valueArr == null || valueArr.isEmpty) continue;

      final rawValue = valueArr[0];
      if (rawValue == null) continue; // Missing observation

      final obsValue = (rawValue as num).toDouble();
      final obsStatus = valueArr.length > 1 ? valueArr[1]?.toString() : null;

      // Build dimension map: {dimensionId → valueCode}
      final dimMap = <String, String>{};
      for (int i = 0; i < dimensions.length && i < indices.length; i++) {
        final idx = int.tryParse(indices[i]);
        if (idx == null) continue;
        final dim = dimensions[i];
        if (idx < dim.values.length) {
          dimMap[dim.id] = dim.values[idx];
        }
      }

      result.add(DataPoint.fromSdmxDimMap(
        dimMap: dimMap,
        value: obsValue,
        obsStatus: obsStatus,
      ));
    }

    return result;
  }

  // ─── Nested access helpers ────────────────────────────────────────────────

  Map<String, dynamic>? _nestedMap(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }
    return current is Map<String, dynamic> ? current : null;
  }

  List? _nestedList(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }
    return current is List ? current : null;
  }
}

/// Thrown when the SDMX-JSON response cannot be parsed.
class SdmxParseException implements Exception {
  const SdmxParseException(this.message);
  final String message;

  @override
  String toString() => 'SdmxParseException: $message';
}
