// lib/data/repositories/indicator_repository.dart

import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';

/// Abstract contract for all indicator data access.
/// The UI depends only on this interface — never on a concrete implementation.
/// Swap [JsonIndicatorRepository] for a [PocketBaseIndicatorRepository]
/// (future v2) by changing one line in [repositoryProvider].
abstract class IndicatorRepository {
  /// Returns the full [IndicatorData] for [indicatorId].
  /// Data chain: live API → Hive cache (24hr) → bundled seed fallback.
  Future<IndicatorData> getIndicator(String indicatorId);

  /// Returns a lightweight [IndicatorSummary] for tile/sheet display.
  Future<IndicatorSummary> getIndicatorSummary(String indicatorId);

  /// Returns all known [IndicatorMeta] entries from indicators_index.json.
  Future<List<IndicatorMeta>> getAllMeta();

  /// Forces a fresh fetch from the live API, bypassing cache.
  Future<IndicatorData> refreshIndicator(String indicatorId);

  /// Clears all cached data.
  Future<void> clearCache();
}
