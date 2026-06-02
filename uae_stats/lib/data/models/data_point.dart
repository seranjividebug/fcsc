// lib/data/models/data_point.dart
//
// Represents one SDMX observation (one row of data).
// Supports two source formats:
//   • Live SDMX-JSON from the FCSC REST API
//   • Flat seed JSON (derived from CSV exports, bundled in assets)

/// A single statistical observation.
class DataPoint {
  const DataPoint({
    required this.timePeriod,
    required this.value,
    this.refArea,
    this.gender,
    this.citizenship,
    this.measure,
    this.unitMeasure,
    this.obsStatus,
  });

  /// The year or period string, e.g. "2024", "2024-Q1".
  final String timePeriod;

  /// The numeric observation value.
  final double value;

  /// Reference area code, e.g. "AE", "AE-DU" (Dubai), "AE-AZ" (Abu Dhabi).
  final String? refArea;

  /// Gender code: "_T" = total, "M" = male, "F" = female.
  final String? gender;

  /// Citizenship / nationality code (births only):
  /// "_T" = total, "EMIRATI", "NON-EMIRATI".
  final String? citizenship;

  /// Measure / indicator code, e.g. "POP", "B" (births), "POPGWTH".
  final String? measure;

  /// Unit of measure code, e.g. "PS" (persons), "PERCENT".
  final String? unitMeasure;

  /// Observation status, e.g. null = normal, "E" = estimated, "P" = provisional.
  final String? obsStatus;

  // ─── Convenience getters ──────────────────────────────────────────────────

  /// True if this observation represents the UAE national total
  /// (REF_AREA = AE, GENDER = _T).
  bool get isUaeTotal =>
      (refArea == 'AE' || refArea == null) &&
      (gender == '_T' || gender == null);

  /// Parsed year as integer (null if not a valid 4-digit year).
  int? get year {
    if (timePeriod.length >= 4) {
      return int.tryParse(timePeriod.substring(0, 4));
    }
    return null;
  }

  // ─── Factory constructors ─────────────────────────────────────────────────

  /// Parses from the flat seed JSON format (CSV-derived, in assets/data/seeds/).
  factory DataPoint.fromSeedJson(Map<String, dynamic> json) {
    return DataPoint(
      timePeriod: json['timePeriod'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      refArea: json['refArea'] as String?,
      gender: json['gender'] as String?,
      citizenship: json['citizenship'] as String?,
      measure: json['measure'] as String?,
      unitMeasure: json['unitMeasure'] as String?,
    );
  }

  /// Creates from a decoded SDMX-JSON dimension map.
  /// [dimMap] maps dimension IDs to their resolved value codes,
  /// e.g. {"REF_AREA": "AE", "GENDER": "_T", "TIME_PERIOD": "2024"}.
  factory DataPoint.fromSdmxDimMap({
    required Map<String, String> dimMap,
    required double value,
    String? obsStatus,
  }) {
    return DataPoint(
      timePeriod: dimMap['TIME_PERIOD'] ?? '',
      value: value,
      refArea: dimMap['REF_AREA'] ?? dimMap['AREA'] ?? dimMap['EMIRATE'],
      gender: dimMap['GENDER'] ?? dimMap['SEX'],
      citizenship: dimMap['CITIZENSHIP'] ??
          dimMap['NATIONALITY'] ??
          dimMap['CIVIL_STATUS'] ??
          dimMap['CITIZEN'],
      measure: dimMap['MEASURE'] ?? dimMap['INDICATOR'],
      unitMeasure: dimMap['UNIT_MEASURE'] ?? dimMap['UNIT'],
      obsStatus: obsStatus,
    );
  }

  // ─── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'timePeriod': timePeriod,
        'value': value,
        if (refArea != null) 'refArea': refArea,
        if (gender != null) 'gender': gender,
        if (citizenship != null) 'citizenship': citizenship,
        if (measure != null) 'measure': measure,
        if (unitMeasure != null) 'unitMeasure': unitMeasure,
        if (obsStatus != null) 'obsStatus': obsStatus,
      };

  factory DataPoint.fromJson(Map<String, dynamic> json) =>
      DataPoint.fromSeedJson(json);

  // ─── copyWith ─────────────────────────────────────────────────────────────

  DataPoint copyWith({
    String? timePeriod,
    double? value,
    String? refArea,
    String? gender,
    String? citizenship,
    String? measure,
    String? unitMeasure,
    String? obsStatus,
  }) {
    return DataPoint(
      timePeriod: timePeriod ?? this.timePeriod,
      value: value ?? this.value,
      refArea: refArea ?? this.refArea,
      gender: gender ?? this.gender,
      citizenship: citizenship ?? this.citizenship,
      measure: measure ?? this.measure,
      unitMeasure: unitMeasure ?? this.unitMeasure,
      obsStatus: obsStatus ?? this.obsStatus,
    );
  }

  @override
  String toString() => 'DataPoint($timePeriod, $value, $refArea, $gender)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataPoint &&
          other.timePeriod == timePeriod &&
          other.value == value &&
          other.refArea == refArea &&
          other.gender == gender;

  @override
  int get hashCode => Object.hash(timePeriod, value, refArea, gender);
}
