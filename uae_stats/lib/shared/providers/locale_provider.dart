// lib/shared/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uae_stats/core/constants/app_constants.dart';

/// Provides the current app [Locale]. Default is English.
/// Persisted via SharedPreferences so the user's choice survives app restarts.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.prefLocale);
    if (saved != null && AppConstants.supportedLocales.contains(saved)) {
      state = Locale(saved);
    }
  }

  /// Toggle between English and Arabic.
  Future<void> toggle() async {
    final next = state.languageCode == 'en' ? 'ar' : 'en';
    state = Locale(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, next);
  }

  /// Set a specific locale.
  Future<void> setLocale(String languageCode) async {
    if (!AppConstants.supportedLocales.contains(languageCode)) return;
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefLocale, languageCode);
  }

  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}
