// lib/shared/providers/bookmark_provider.dart
//
// Persistent indicator bookmarks, backed by a Hive box ('bookmarks').
// The box stores one entry per saved indicator: key = indicator id,
// value = ISO timestamp of when it was added (used for "Recently Added" sort).
//
// Exposes:
//   • bookmarkProvider      — ordered list of saved indicator ids (newest first)
//   • isBookmarkedProvider  — family<bool> for a single id (cheap watch)
//   • BookmarkNotifier.toggle / add / remove / clear

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _bookmarksBox = 'bookmarks';

/// Ordered list of bookmarked indicator ids — most recently added first.
final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, List<String>>((ref) {
  return BookmarkNotifier();
});

/// Convenience: is a given indicator id currently bookmarked?
final isBookmarkedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(bookmarkProvider).contains(id);
});

class BookmarkNotifier extends StateNotifier<List<String>> {
  BookmarkNotifier() : super(const []) {
    _load();
  }

  Box<String> get _box => Hive.box<String>(_bookmarksBox);

  void _load() {
    final entries = _box.toMap().entries.toList()
      // newest (latest timestamp) first
      ..sort((a, b) => (b.value).compareTo(a.value));
    state = entries.map((e) => e.key.toString()).toList();
  }

  bool isBookmarked(String id) => state.contains(id);

  Future<void> add(String id) async {
    if (state.contains(id)) return;
    await _box.put(id, DateTime.now().toIso8601String());
    _load();
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
    _load();
  }

  /// Toggles and returns the new state (true = now bookmarked).
  Future<bool> toggle(String id) async {
    if (state.contains(id)) {
      await remove(id);
      return false;
    }
    await add(id);
    return true;
  }

  Future<void> clear() async {
    await _box.clear();
    state = const [];
  }
}
