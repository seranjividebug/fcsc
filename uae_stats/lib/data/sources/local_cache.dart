// lib/data/sources/local_cache.dart
//
// Hive-based local cache for parsed indicator data.
// TTL: 24 hours per indicator (configurable via ApiConstants.cacheTtl).
// Storage format: JSON string → decode on read.

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/data_point.dart';

class LocalCache {
  static const _boxName = 'indicator_cache';
  static const _metaSuffix = '_meta'; // stores fetch timestamp

  Box<String> get _box => Hive.box<String>(_boxName);

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns cached DataPoints for [cacheKey] if still fresh (< 24hr old).
  /// Returns null if cache is missing or stale.
  List<DataPoint>? getIfFresh(String cacheKey) {
    final metaKey = '$cacheKey$_metaSuffix';
    final timestampStr = _box.get(metaKey);
    if (timestampStr == null) return null;

    final fetchedAt = DateTime.tryParse(timestampStr);
    if (fetchedAt == null) return null;

    final age = DateTime.now().difference(fetchedAt);
    if (age > ApiConstants.cacheTtl) return null; // Stale

    return _readPoints(cacheKey);
  }

  /// Returns cached DataPoints regardless of age.
  /// Used as last-resort fallback when API fails and no seed exists.
  List<DataPoint>? getAny(String cacheKey) => _readPoints(cacheKey);

  List<DataPoint>? _readPoints(String cacheKey) {
    final raw = _box.get(cacheKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .cast<Map<String, dynamic>>()
          .map(DataPoint.fromJson)
          .toList();
    } catch (_) {
      return null; // Corrupted cache — treat as miss
    }
  }

  // ─── Write ────────────────────────────────────────────────────────────────

  /// Stores [points] under [cacheKey] and records the current timestamp.
  Future<void> put(String cacheKey, List<DataPoint> points) async {
    final json = jsonEncode(points.map((p) => p.toJson()).toList());
    await _box.put(cacheKey, json);
    await _box.put(
      '$cacheKey$_metaSuffix',
      DateTime.now().toIso8601String(),
    );
  }

  // ─── Invalidate ───────────────────────────────────────────────────────────

  /// Removes a specific indicator's cache entry.
  Future<void> invalidate(String cacheKey) async {
    await _box.delete(cacheKey);
    await _box.delete('$cacheKey$_metaSuffix');
  }

  /// Clears the entire cache.
  Future<void> clearAll() async {
    await _box.clear();
  }

  // ─── Diagnostics ─────────────────────────────────────────────────────────

  /// Returns the age of a cache entry, or null if not cached.
  Duration? cacheAge(String cacheKey) {
    final ts = _box.get('$cacheKey$_metaSuffix');
    if (ts == null) return null;
    final dt = DateTime.tryParse(ts);
    if (dt == null) return null;
    return DateTime.now().difference(dt);
  }

  bool isCached(String cacheKey) => _box.containsKey(cacheKey);
}
