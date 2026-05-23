// lib/data/models/localized_string.dart

import 'package:flutter/material.dart';

/// A string that has both an English and Arabic value.
/// Call [resolve(context)] or [of(locale)] to get the
/// language-appropriate string at runtime.
class LocalizedString {
  const LocalizedString({required this.en, required this.ar});

  final String en;
  final String ar;

  /// Returns the string for the current app locale.
  String resolve(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return lang == 'ar' ? ar : en;
  }

  /// Returns the string for an explicit locale code.
  String of(String languageCode) => languageCode == 'ar' ? ar : en;

  /// Convenience: always returns the English value.
  String get english => en;

  /// Convenience: always returns the Arabic value.
  String get arabic => ar;

  factory LocalizedString.fromJson(Map<String, dynamic> json) {
    return LocalizedString(
      en: json['en'] as String? ?? '',
      ar: json['ar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'en': en, 'ar': ar};

  LocalizedString copyWith({String? en, String? ar}) {
    return LocalizedString(en: en ?? this.en, ar: ar ?? this.ar);
  }

  @override
  String toString() => 'LocalizedString(en: $en, ar: $ar)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedString && other.en == en && other.ar == ar;

  @override
  int get hashCode => Object.hash(en, ar);
}
