// lib/data/models/indicator_meta.dart

import 'package:uae_stats/data/models/localized_string.dart';

/// Static metadata about a statistical indicator.
class IndicatorMeta {
  const IndicatorMeta({
    required this.id,
    required this.dataflowId,
    required this.dataflowVersion,
    required this.agencyId,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.unit,
    required this.unitCode,
    required this.frequency,
    required this.sourceCode,
    required this.sourceName,
    required this.coverageStart,
    required this.coverageEnd,
    this.comingSoon = false,
    this.navDirect = false,
    this.parentSheet,
  });

  /// Unique identifier used in routing and cache keys, e.g. "births".
  final String id;

  /// SDMX dataflow ID, e.g. "DF_BIRTHS".
  final String dataflowId;

  /// Dataflow version, e.g. "1.9.0".
  final String dataflowVersion;

  /// Agency identifier, typically "FCSA".
  final String agencyId;

  /// Bilingual indicator name.
  final LocalizedString name;

  /// Top-level category: "demography" | "economy" | "environment".
  final String category;

  /// Sub-category: "population" | "vitals" | etc.
  final String subCategory;

  /// Bilingual unit label, e.g. "Persons" / "أشخاص".
  final LocalizedString unit;

  /// SDMX unit code, e.g. "PS".
  final String unitCode;

  /// SDMX frequency code: "A" = annual, "M" = monthly, "Q" = quarterly.
  final String frequency;

  /// Source organisation code, e.g. "FCSC", "MHP".
  final String sourceCode;

  /// Bilingual source organisation name.
  final LocalizedString sourceName;

  /// First year data is available, e.g. "1970".
  final String coverageStart;

  /// Last year data is available, e.g. "2024".
  final String coverageEnd;

  /// If true, no live data available yet — show "Coming Soon" UI.
  final bool comingSoon;

  /// If true, tapping the tile navigates directly (single-metric indicator).
  final bool navDirect;

  /// ID of the bottom sheet this indicator belongs to, if any.
  final String? parentSheet;

  // ─── Computed ─────────────────────────────────────────────────────────────

  String get frequencyLabel => switch (frequency) {
        'A' => 'Annual',
        'M' => 'Monthly',
        'Q' => 'Quarterly',
        _ => frequency,
      };

  String get coverageRange => '$coverageStart – $coverageEnd';

  // ─── Factory ──────────────────────────────────────────────────────────────

  factory IndicatorMeta.fromJson(Map<String, dynamic> json) {
    return IndicatorMeta(
      id: json['id'] as String,
      dataflowId: json['dataflowId'] as String? ?? '',
      dataflowVersion: json['dataflowVersion'] as String? ?? '1.0.0',
      agencyId: json['agencyId'] as String? ?? 'FCSA',
      name: LocalizedString.fromJson(json['name'] as Map<String, dynamic>),
      category: json['category'] as String? ?? '',
      subCategory: json['subCategory'] as String? ?? '',
      unit: json['unit'] != null
          ? LocalizedString.fromJson(json['unit'] as Map<String, dynamic>)
          : const LocalizedString(en: 'Persons', ar: 'أشخاص'),
      unitCode: json['unitCode'] as String? ?? 'PS',
      frequency: json['frequency'] as String? ?? 'A',
      sourceCode: json['sourceCode'] as String? ?? 'FCSC',
      sourceName: json['sourceName'] != null
          ? LocalizedString.fromJson(
              json['sourceName'] as Map<String, dynamic>)
          : const LocalizedString(
              en: 'Federal Competitiveness and Statistics Centre',
              ar: 'المركز الاتحادي للتنافسية والإحصاء',
            ),
      coverageStart: json['coverageStart'] as String? ?? '2015',
      coverageEnd: json['coverageEnd'] as String? ?? '2024',
      comingSoon: json['comingSoon'] as bool? ?? false,
      navDirect: json['navDirect'] as bool? ?? false,
      parentSheet: json['parentSheet'] as String?,
    );
  }

  @override
  String toString() => 'IndicatorMeta($id, ${name.en})';
}
