// lib/data/services/search_history_service.dart
//
// Persists and retrieves recent search history and per-indicator view counts
// using SharedPreferences. View counts drive the trending rankings.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _keyHistory  = 'search_history_v1';
  static const _keyViewCounts = 'indicator_view_counts_v1';
  static const _maxHistory  = 20;

  // ─── Recent searches ───────────────────────────────────────────────────────

  Future<List<String>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_keyHistory) ?? [];
    return raw;
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList(_keyHistory) ?? [];
    list.remove(query);          // remove duplicate if present
    list.insert(0, query);       // most-recent first
    if (list.length > _maxHistory) list.removeLast();
    await prefs.setStringList(_keyHistory, list);
  }

  Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list  = prefs.getStringList(_keyHistory) ?? [];
    list.remove(query);
    await prefs.setStringList(_keyHistory, list);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  // ─── View / search counts (drives trending) ───────────────────────────────

  Future<Map<String, int>> loadViewCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyViewCounts);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> incrementView(String indicatorId) async {
    final prefs  = await SharedPreferences.getInstance();
    final raw    = prefs.getString(_keyViewCounts);
    final counts = raw != null
        ? (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int))
        : <String, int>{};
    counts[indicatorId] = (counts[indicatorId] ?? 0) + 1;
    await prefs.setString(_keyViewCounts, jsonEncode(counts));
  }

  /// Returns indicator IDs sorted by view count descending, up to [limit].
  Future<List<String>> topIndicators({int limit = 6}) async {
    final counts = await loadViewCounts();
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
