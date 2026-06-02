// lib/data/providers/search_providers.dart
//
// Riverpod providers for the dynamic search system.
// - searchHistoryProvider  : live list of recent search strings
// - trendingIdsProvider    : top-N indicator IDs by view count
// - searchQueryProvider    : current debounced query string
// - searchResultsProvider  : filtered IndicatorMeta list for the current query

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/data/services/search_history_service.dart';

// ─── Service singleton ────────────────────────────────────────────────────────

final searchHistoryServiceProvider = Provider<SearchHistoryService>(
  (_) => SearchHistoryService(),
);

// ─── Recent search history ────────────────────────────────────────────────────

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier(this._svc) : super([]) {
    _load();
  }

  final SearchHistoryService _svc;

  Future<void> _load() async {
    state = await _svc.loadHistory();
  }

  Future<void> add(String query) async {
    await _svc.addSearch(query);
    state = await _svc.loadHistory();
  }

  Future<void> remove(String query) async {
    await _svc.removeSearch(query);
    state = await _svc.loadHistory();
  }

  Future<void> clearAll() async {
    await _svc.clearHistory();
    state = [];
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier(ref.read(searchHistoryServiceProvider));
});

// ─── Trending indicators (by view count) ─────────────────────────────────────

/// Default trending IDs used when the user has no view history yet.
const _defaultTrendingIds = [
  'population',
  'gdp_current',
  'prices_cpi_annual',
  'births',
  'trade_total',
  'renewable_energy',
];

final trendingIdsProvider = FutureProvider<List<String>>((ref) async {
  final svc = ref.read(searchHistoryServiceProvider);
  final top = await svc.topIndicators(limit: 6);
  if (top.isEmpty) return _defaultTrendingIds;

  // Merge with defaults so we always show at least 4 cards
  final merged = [...top];
  for (final id in _defaultTrendingIds) {
    if (!merged.contains(id)) merged.add(id);
    if (merged.length >= 6) break;
  }
  return merged.take(6).toList();
});

// ─── Current search query (debounced in the UI layer) ─────────────────────────

final searchQueryProvider = StateProvider<String>((_) => '');

// ─── Category filter ──────────────────────────────────────────────────────────

final searchCategoryProvider = StateProvider<String>((_) => 'All');

// ─── Filtered search results ──────────────────────────────────────────────────

final searchResultsProvider = Provider<AsyncValue<List<IndicatorMeta>>>((ref) {
  final query    = ref.watch(searchQueryProvider).trim().toLowerCase();
  final category = ref.watch(searchCategoryProvider);
  final allMeta  = ref.watch(allMetaProvider);

  if (query.isEmpty) return const AsyncValue.data([]);

  return allMeta.when(
    loading: () => const AsyncValue.loading(),
    error:   (e, st) => AsyncValue.error(e, st),
    data: (all) {
      final filtered = all.where((meta) {
        final nameEn  = meta.name.en.toLowerCase();
        final nameAr  = meta.name.ar.toLowerCase();
        final cat     = meta.category.toLowerCase();
        final subCat  = meta.subCategory.toLowerCase();

        final matchesQuery = nameEn.contains(query) ||
            nameAr.contains(query) ||
            cat.contains(query) ||
            subCat.contains(query);

        final matchesCat = category == 'All' ||
            meta.category.toLowerCase() == category.toLowerCase();

        return matchesQuery && matchesCat;
      }).toList();

      // Sort: exact name starts-with first, then contains
      filtered.sort((a, b) {
        final aStarts = a.name.en.toLowerCase().startsWith(query) ? 0 : 1;
        final bStarts = b.name.en.toLowerCase().startsWith(query) ? 0 : 1;
        if (aStarts != bStarts) return aStarts - bStarts;
        return a.name.en.compareTo(b.name.en);
      });

      return AsyncValue.data(filtered);
    },
  );
});

// ─── Distinct categories derived from allMeta ─────────────────────────────────

final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  final allMeta = ref.watch(allMetaProvider);
  return allMeta.when(
    loading: () => const AsyncValue.loading(),
    error:   (e, st) => AsyncValue.error(e, st),
    data: (all) {
      final cats = all.map((m) => _capitalize(m.category)).toSet().toList()
        ..sort();
      return AsyncValue.data(cats);
    },
  );
});

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
