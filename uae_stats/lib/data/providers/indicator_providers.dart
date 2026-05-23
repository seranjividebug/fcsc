// lib/data/providers/indicator_providers.dart
//
// All Riverpod providers for indicator data access.
// Uses plain Provider syntax (no codegen) — works without build_runner.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';
import 'package:uae_stats/data/repositories/indicator_repository.dart';
import 'package:uae_stats/data/repositories/indicator_repository_impl.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

/// The single IndicatorRepository instance used throughout the app.
/// To swap the implementation (e.g. to PocketBase in v2), change this one line.
final repositoryProvider = Provider<IndicatorRepository>((ref) {
  return IndicatorRepositoryImpl();
});

// ─── Indicator index ──────────────────────────────────────────────────────────

/// All IndicatorMeta entries from indicators_index.json.
final allMetaProvider = FutureProvider<List<IndicatorMeta>>((ref) {
  return ref.watch(repositoryProvider).getAllMeta();
});

// ─── Full indicator data ──────────────────────────────────────────────────────

/// Full IndicatorData for a given indicator ID.
/// Usage: ref.watch(indicatorDataProvider('births'))
final indicatorDataProvider =
    FutureProvider.family<IndicatorData, String>((ref, indicatorId) {
  return ref.watch(repositoryProvider).getIndicator(indicatorId);
});

// ─── Indicator summaries ──────────────────────────────────────────────────────

/// Lightweight IndicatorSummary for a given indicator ID.
/// Used by tiles, sheet rows, and KPI cards.
final indicatorSummaryProvider =
    FutureProvider.family<IndicatorSummary, String>((ref, indicatorId) {
  return ref.watch(repositoryProvider).getIndicatorSummary(indicatorId);
});

// ─── POC-specific convenience providers ──────────────────────────────────────

/// Population Estimates data — used by the Population tile and detail screen.
final populationDataProvider = FutureProvider<IndicatorData>((ref) {
  return ref.watch(repositoryProvider).getIndicator('population');
});

/// Population summary — for the Population tile on the Home screen.
final populationSummaryProvider = FutureProvider<IndicatorSummary>((ref) {
  return ref.watch(repositoryProvider).getIndicatorSummary('population');
});

/// Births data — used by the Vitals sheet row and Births detail screen.
final birthsDataProvider = FutureProvider<IndicatorData>((ref) {
  return ref.watch(repositoryProvider).getIndicator('births');
});

/// Births summary — for the Vitals bottom sheet row.
final birthsSummaryProvider = FutureProvider<IndicatorSummary>((ref) {
  return ref.watch(repositoryProvider).getIndicatorSummary('births');
});

// ─── Refresh notifier ────────────────────────────────────────────────────────

/// Calling [refresh(indicatorId)] forces a live API re-fetch.
class RefreshNotifier extends StateNotifier<void> {
  RefreshNotifier(this._repo) : super(null);

  final IndicatorRepository _repo;

  Future<IndicatorData> refresh(String indicatorId) {
    return _repo.refreshIndicator(indicatorId);
  }

  Future<void> clearCache() => _repo.clearCache();
}

final refreshNotifierProvider = StateNotifierProvider<RefreshNotifier, void>(
  (ref) => RefreshNotifier(ref.watch(repositoryProvider)),
);
