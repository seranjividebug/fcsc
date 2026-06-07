// lib/data/models/indicator_data.dart

import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';

/// Full dataset for a single indicator, including all breakdowns.
/// This is what the IndicatorDetailScreen consumes.
class IndicatorData {
  const IndicatorData({
    required this.meta,
    required this.allPoints,
    required this.fetchedAt,
    required this.fromCache,
    this.apiPreparedAt,
  });

  final IndicatorMeta meta;

  /// All raw DataPoints returned by the API / seed (full dimensionality).
  final List<DataPoint> allPoints;

  final DateTime fetchedAt;

  /// True if this data came from the local Hive cache or bundled seed.
  final bool fromCache;

  /// ISO-8601 timestamp from the SDMX API's own `meta.prepared` field.
  /// Null when serving from cache or seed.
  final String? apiPreparedAt;

  // ─── Dynamic coverage derived from actual data ───────────────────────────

  /// First year in the actual data series (overrides the static meta value).
  String get dataStart {
    final s = uaeTotalSeries;
    return s.isEmpty ? meta.coverageStart : s.first.timePeriod;
  }

  /// Last year in the actual data series (overrides the static meta value).
  String get dataEnd {
    final s = uaeTotalSeries;
    return s.isEmpty ? meta.coverageEnd : s.last.timePeriod;
  }

  String get dataRange => '$dataStart – $dataEnd';

  /// Human-readable form of [apiPreparedAt], e.g. "15 January 2025".
  /// Falls back to null when the API timestamp is unavailable.
  String? get preparedAtForDisplay {
    if (apiPreparedAt == null) return null;
    try {
      final dt = DateTime.parse(apiPreparedAt!);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return apiPreparedAt;
    }
  }

  // ─── Filtered time series ─────────────────────────────────────────────────

  /// Measure codes considered valid for this indicator. Empty set means
  /// "accept any measure" (unknown dataflow version).
  Set<String> get _allowedMeasures => switch (meta.id) {
      'population'        => {'POP'},
      'births'            => {'B'},
      'deaths'            => {'DEATHS', 'D', 'D_TOTAL'},
      'marriages'         => {'MARRIAGES', 'M', 'MR'},
      'divorces'          => {'DIVORCES', 'DV', 'DV_TOTAL'},
      'student_enrolment'      => {'GENERAL', 'TOTAL', 'ENR'},
      'teaching_staff'         => {'GENERAL', 'TOTAL', 'STAFF'},
      'higher_education'       => {'HIGHER', 'TOTAL', 'HE'},
      'hospitals'              => {'HOSPITALS', 'TOTAL', 'FAC'},
      'health_services'        => {'HSP'},
      'health_clinics_centers' => {'CAH'},
      'health_hospital_beds'   => {'BED'},
      'health_professionals'           => {'HWF', 'TOTAL'},
      'prices_cpi_annual'              => {'CPI_ANN', 'CPI', 'TOTAL', '_T'},
      'tourism_hotel_arrivals'         => {'HTL_ARR', 'TOTAL', '_T'},
      'tourism_hotel_establishments'   => {'HTL_EST', 'TOTAL', '_T'},
      'tourism_main_indicators'        => {'TOUR_MAIN', 'TOTAL', '_T', 'GUESTS'},
      'aircraft_movement'              => {'ACFT_MOV', 'TOTAL', '_T'},
      'ecology_mean_temp'              => {'MEAN_TEMP', 'TEMP_MEAN', 'TEMP', '_T'},
      'crop_production'                => {'CROP_PROD', 'PRODUCTION', 'TOTAL', '_T'},
      'crop_area'                      => {'CROP_AREA', 'AREA', 'TOTAL', '_T'},
      'crop_land_total'                => {'LAND_TOTAL', 'TOTAL', 'TOTAL_AREA', '_T'},
      'trade_total'                    => {'TRADE_TOT'},
      'trade_imports_hs'               => {'IMP_HS', 'TOTAL', '_T'},
      'trade_non_oil_exports'          => {'NON_OIL_EXP', 'TOTAL', '_T'},
      'trade_sector_country'           => {'TRADE_SEC', 'TOTAL', '_T'},
      'trade_reexports_annual'         => {'REEXP_ANN', 'TOTAL', '_T'},
      'trade_reexports_monthly'        => {'REEXP_MON', 'MTH_CNT', 'TOTAL', '_T'},
      'gdp_current'                    => {'GDP_CUR', 'B1GQ', 'TOTAL', '_T'},
      'gdp_constant'                   => {'GDP_CON', 'B1GQ', 'TOTAL', '_T'},
      'gdp_quarterly_current'          => {'QGDP_CUR', 'B1GQ', 'TOTAL', '_T'},
      'gdp_quarterly_constant'         => {'QGDP_CON', 'B1GQ', 'TOTAL', '_T'},
      // Accept any measure — DF_LFEP_ECON is a single-measure % distribution.
      'labour_economic_activity'       => <String>{},
      // Accept any measure — DF_LFEP_AGE uses a single employment measure;
      // age/gender/total guards isolate the correct rows.
      'labour_employed_age_gender'     => <String>{},
      // Accept any measure — DF_LFEP_ED is a single-measure % distribution.
      'labour_employed_education'      => <String>{},
      // Accept any measure — DF_LFEP_SECT is a single-measure % distribution.
      'labour_employment_sector'       => <String>{},
      // Accept any measure — DF_LFUNEMP_ED is a single-measure % distribution.
      'labour_unemployment_education'  => <String>{},
      // Accept any measure — single-measure % distributions.
      'labour_workforce_occupation'    => <String>{},
      'labour_unemployment_age_gender' => <String>{},
      _                   => {},
    };

  /// True if [p]'s measure code is acceptable for this indicator.
  bool _measureOk(DataPoint p) =>
      _allowedMeasures.isEmpty ||
      p.measure == null ||
      _allowedMeasures.contains(p.measure);

  /// UAE national total, sorted oldest → newest.
  List<DataPoint> get uaeTotalSeries {
    // ── Special case: Employed-by-Age is a % distribution dataflow (DF_LFEP_AGE).
    // There is no headcount — each age band is a % share and the age-Total row
    // is 100. The headline metric is the PRIME working-age share (25–44),
    // i.e. the sum of the gender-Total shares for the 25–29…40–44 bands.
    // Annual Rainfall — national annual-average across stations.
    if (isRainfall) {
      final s = _rainfallNationalSeries;
      if (s.isNotEmpty) return s;
    }
    // Produced Water — grand-total MCM (entity total × source total).
    if (isProducedWater) {
      final s = _producedWaterTotalSeries;
      if (s.isNotEmpty) return s;
    }
    // Generation / Renewable capacity — category-total (MW) series.
    if (isGenerationCapacity || isRenewableEnergy) {
      final s = _categoryTotalSeries;
      if (s.isNotEmpty) return s;
    }
    // Crude Oil — headline is proven reserves (OG_SECTOR = RE).
    if (isCrudeOil) {
      final s = crudeOilSeries('RE');
      if (s.isNotEmpty) return s;
    }
    // Protected Natural Areas / RAMSAR — national grand-total (km²) series.
    if (isNaturalReserves || isRamsarWetlands) {
      final s = _reserveTotalSeries;
      if (s.isNotEmpty) return s;
    }
    if (meta.id == 'labour_employed_age_gender') {
      final s = _primeAgeShareSeries;
      if (s.isNotEmpty) return s;
    }
    // Unemployment by Age (% distribution). Headline = Youth (15–34) share.
    if (meta.id == 'labour_unemployment_age_gender') {
      final s = _youthShareSeries;
      if (s.isNotEmpty) return s;
    }
    // Employed-by-Education (DF_LFEP_ED) is also a % distribution. Headline =
    // University Degree+ share (Bachelor's + Higher Diploma + Master's + PhD).
    if (meta.id == 'labour_employed_education') {
      final s = _universityShareSeries;
      if (s.isNotEmpty) return s;
    }
    // Top-category % distributions (Economic Activity sectors; Unemployment by
    // Education levels; Workforce by Occupation). Headline = leading category.
    if (meta.id == 'labour_economic_activity' ||
        meta.id == 'labour_unemployment_education' ||
        meta.id == 'labour_workforce_occupation') {
      final s = _topSectorShareSeries;
      if (s.isNotEmpty) return s;
    }
    // Employment by Sector (DF_LFEP_SECT) is a % distribution. Headline =
    // the Private Sector ('PRI') share over time.
    if (meta.id == 'labour_employment_sector') {
      final s = sectorShareSeries('PRI', '_T');
      if (s.isNotEmpty) return s;
    }

    // Step 1: sum GENDER=_T, CITIZENSHIP=_T from the 7 emirate codes only.
    // This correctly aggregates datasets that publish per-emirate rows (Births, Deaths).
    const emirateCodes = {
      'AE-AZ', 'AE-DU', 'AE-SH', 'AE-AJ', 'AE-RK', 'AE-FJ', 'AE-UQ',
    };
    final emirateSums = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (!emirateCodes.contains(p.refArea)) continue;
      if (p.gender != '_T' && p.gender != null) continue;
      if (p.citizenship != '_T' && p.citizenship != null && p.citizenship != '_Z') continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      tmpl ??= p;
      emirateSums[p.timePeriod] = (emirateSums[p.timePeriod] ?? 0) + p.value;
    }
    if (emirateSums.isNotEmpty && tmpl != null) {
      return emirateSums.entries
          .map((e) => tmpl!.copyWith(refArea: 'AE', value: e.value, timePeriod: e.key))
          .toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }

    // Step 2: no emirate rows — use REF_AREA=AE national total directly.
    // Datasets like Marriages and Divorces only publish AE-level rows.
    final national = <String, DataPoint>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (p.gender != '_T' && p.gender != null) continue;
      if (p.citizenship != '_T' && p.citizenship != null && p.citizenship != '_Z') continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      final existing = national[p.timePeriod];
      if (existing == null) {
        national[p.timePeriod] = p;
      } else if (p.citizenship == '_T' && existing.citizenship != '_T') {
        national[p.timePeriod] = p;
      }
    }
    return national.values.toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// True if [code] represents one of the prime working-age bands (25–44):
  /// matches "25-29", "Y25T29", "30 to 34 years", etc. up to 40–44.
  static bool _isPrimeAgeBand(String? code) {
    if (code == null) return false;
    final lower = RegExp(r'(\d+)').firstMatch(code);
    if (lower == null) return false;
    final start = int.tryParse(lower.group(1)!);
    return start != null && start >= 25 && start <= 40;
  }

  /// Prime working-age (25–44) share per year — sum of gender-Total shares for
  /// the 25–29 … 40–44 bands. Drives the hero value, chart and growth for the
  /// Employed-by-Age (% distribution) indicator.
  List<DataPoint> get _primeAgeShareSeries {
    final byYear = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;          // gender = Total column
      if (!_isTotal(p.citizenship)) continue;
      if (!_isPrimeAgeBand(p.ageGroup)) continue; // 25–44 bands only
      tmpl ??= p;
      byYear[p.timePeriod] = (byYear[p.timePeriod] ?? 0) + p.value;
    }
    if (byYear.isEmpty || tmpl == null) return const [];
    return byYear.entries
        .map((e) => tmpl!.copyWith(
            refArea: 'AE', ageGroup: '_T', value: e.value, timePeriod: e.key))
        .toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// True if [code] is a youth age band (15–34): the 15–19 … 30–34 bands.
  static bool _isYouthBand(String? code) {
    if (code == null) return false;
    final m = RegExp(r'(\d+)').firstMatch(code);
    if (m == null) return false;
    final start = int.tryParse(m.group(1)!);
    return start != null && start >= 15 && start <= 30;
  }

  /// Youth (15–34) share per year — sum of gender-Total shares for the
  /// 15–19 … 30–34 bands. Drives the hero value, chart and growth for the
  /// Unemployment-by-Age (% distribution) indicator.
  List<DataPoint> get _youthShareSeries {
    final byYear = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;        // gender = Total column
      if (!_isTotal(p.citizenship)) continue;
      if (!_isTotal(p.level)) continue;
      if (!_isYouthBand(p.ageGroup)) continue;  // 15–34 bands only
      tmpl ??= p;
      byYear[p.timePeriod] = (byYear[p.timePeriod] ?? 0) + p.value;
    }
    if (byYear.isEmpty || tmpl == null) return const [];
    return byYear.entries
        .map((e) => tmpl!.copyWith(
            refArea: 'AE', ageGroup: '_T', value: e.value, timePeriod: e.key))
        .toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// True if [code] is a university-tier education level. University Degree+ =
  /// Bachelor or equivalent + Higher Diploma + Masters or equivalent +
  /// Doctoral or equivalent. Explicitly EXCLUDES "Short-Cycle Tertiary
  /// Education" (a sub-degree level that also contains the word "tertiary").
  static bool _isUniversityLevel(String? code) {
    if (code == null) return false;
    final c = code.toUpperCase();
    if (c.contains('SHORT') || c.contains('SCTE')) {
      return false; // Short-Cycle Tertiary — not a university degree
    }
    // DF_LFEP_ED uses exact codes: BACH, HDIP, MAST, DOCT.
    const exactCodes = {'BACH', 'HDIP', 'MAST', 'DOCT'};
    if (exactCodes.contains(c)) return true;
    // Label fallbacks for other dataflows.
    const keys = [
      'BACHELOR', 'BSC',
      'HIGHER DIPLOMA', 'HIGHER_DIPLOMA', 'HIGHERDIPLOMA',
      'MASTER', 'MSC',
      'DOCTOR', 'DOCTORAL', 'PHD',
    ];
    return keys.any(c.contains);
  }

  /// True if this indicator is the Employed-by-Education % distribution.
  bool get isEmployedEducation => meta.id == 'labour_employed_education';

  /// University Degree+ share per year for a given [genderCode]
  /// ('_T' total, 'M', 'F') — sum of that gender's university-tier level
  /// shares (Bachelor + Higher Diploma + Masters + Doctoral).
  List<DataPoint> universityShareSeries(String genderCode) {
    final byYear = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if ((p.gender ?? '_T') != genderCode) continue;
      if (!_isTotal(p.citizenship)) continue;
      if (!_isUniversityLevel(p.level)) continue;
      tmpl ??= p;
      byYear[p.timePeriod] = (byYear[p.timePeriod] ?? 0) + p.value;
    }
    if (byYear.isEmpty || tmpl == null) return const [];
    return byYear.entries
        .map((e) => tmpl!.copyWith(
            refArea: 'AE', gender: genderCode, level: '_T',
            value: e.value, timePeriod: e.key))
        .toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// University Degree+ share (gender-Total) — drives the hero / chart / growth
  /// for the Employed-by-Education indicator.
  List<DataPoint> get _universityShareSeries => universityShareSeries('_T');

  /// True if this indicator is the Employed-by-Economic-Activity % distribution.
  bool get isEconomicActivity => meta.id == 'labour_economic_activity';

  /// True for % distributions whose headline is the single leading category
  /// (Economic Activity, Unemployment by Education, Workforce by Occupation).
  bool get isTopCategoryShare =>
      meta.id == 'labour_economic_activity' ||
      meta.id == 'labour_unemployment_education' ||
      meta.id == 'labour_workforce_occupation';

  /// The leading economic-activity sector code in the latest year
  /// (gender-Total), e.g. 'F' (Construction). Null if no sector data.
  String? get topSectorCode {
    final byCode = byLevel; // sector breakdown (gender-Total)
    String? best;
    double bestVal = -1;
    byCode.forEach((code, series) {
      if (series.isEmpty) return;
      final v = series.last.value;
      if (v > bestVal) {
        bestVal = v;
        best = code;
      }
    });
    return best;
  }

  /// Leading-sector share per year — drives the hero / chart / growth for the
  /// Economic Activity indicator. Tracks the latest-year top sector over time.
  List<DataPoint> get _topSectorShareSeries {
    final code = topSectorCode;
    if (code == null) return const [];
    final series = byLevel[code];
    if (series == null || series.isEmpty) return const [];
    return List<DataPoint>.from(series)
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// Latest-year category→value map for a given [genderCode] ('M'/'F'/'_T'),
  /// keyed by the category code (level dimension). Excludes the _T total row.
  /// Used by the Male/Female profile breakdown tabs.
  Map<String, double> latestCategoryByGender(String genderCode) {
    // Find the latest year present for this gender.
    String? latestYear;
    for (final p in allPoints) {
      if ((p.gender ?? '_T') != genderCode) continue;
      if (p.timePeriod.compareTo(latestYear ?? '') > 0) {
        latestYear = p.timePeriod;
      }
    }
    final result = <String, double>{};
    if (latestYear == null) return result;
    for (final p in allPoints) {
      if (p.timePeriod != latestYear) continue;
      if ((p.gender ?? '_T') != genderCode) continue;
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (_isTotal(p.level)) continue;
      result[p.level!] = p.value;
    }
    return result;
  }

  /// True if this indicator is the Employment-by-Sector % distribution.
  bool get isEmploymentSector => meta.id == 'labour_employment_sector';

  /// Share series for a specific category [sectorCode] (matched against the
  /// 'level' dimension) and [genderCode] ('_T'/'M'/'F'), per year.
  List<DataPoint> sectorShareSeries(String sectorCode, String genderCode) {
    final byYear = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if ((p.gender ?? '_T') != genderCode) continue;
      if (!_isTotal(p.citizenship)) continue;
      if ((p.level ?? '').toUpperCase() != sectorCode.toUpperCase()) continue;
      tmpl ??= p;
      byYear[p.timePeriod] = p.value;
    }
    if (byYear.isEmpty || tmpl == null) return const [];
    return byYear.entries
        .map((e) => tmpl!.copyWith(
            refArea: 'AE', gender: genderCode, level: sectorCode,
            value: e.value, timePeriod: e.key))
        .toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
  }

  /// By-emirate breakdown (UAE total gender, total citizenship).
  Map<String, List<DataPoint>> get byEmirate {
    final codes = {
      'AE-AZ': 'Abu Dhabi',
      'AE-DU': 'Dubai',
      'AE-SH': 'Sharjah',
      'AE-AJ': 'Ajman',
      'AE-RK': 'Ras Al Khaimah',
      'AE-FJ': 'Fujairah',
      'AE-UQ': 'Umm Al Quwain',
    };
    final result = <String, List<DataPoint>>{};
    for (final code in codes.keys) {
      final pts = allPoints.where((p) {
        return p.refArea == code &&
            _isTotal(p.gender) &&
            _isTotal(p.citizenship) &&
            _isTotal(p.level) &&
            _isTotal(p.ageGroup) && // avoid summing parent + child age classes
            _measureOk(p);
      }).toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (pts.isNotEmpty) result[code] = pts;
    }
    return result;
  }

  /// Dimension "total" sentinels that should never be treated as a breakdown
  /// category (they represent the aggregated total, not a sub-group).
  static const _totalCodes = {'_T', '_Z', 'T', 'TOTAL', 'ALL', '_O'};

  static bool _isTotal(String? code) =>
      code == null || _totalCodes.contains(code.toUpperCase());

  /// By-gender breakdown (UAE total, citizenship-total).
  ///
  /// Discovers whatever GENDER codes actually exist in the data instead of
  /// assuming a fixed {M, F} set — different FCSC dataflows use different
  /// codes. Total/aggregate codes are excluded.
  Map<String, List<DataPoint>> get byGender {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.citizenship)) continue;
      if (!_isTotal(p.level)) continue; // only level-total rows (avoid double count)
      if (!_isTotal(p.ageGroup)) continue; // only age-total rows
      if (_isTotal(p.gender)) continue; // skip totals; keep real categories
      if (!_measureOk(p)) continue;
      (result[p.gender!] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  /// By-citizenship / nationality breakdown (UAE total, gender-total).
  ///
  /// Discovers whatever CITIZENSHIP/NATIONALITY codes exist in the data rather
  /// than hardcoding {EMIRATI, NON-EMIRATI}. Total/aggregate codes excluded.
  Map<String, List<DataPoint>> get byCitizenship {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (_isTotal(p.citizenship)) continue;
      if (!_measureOk(p)) continue;
      (result[p.citizenship!] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  /// True if any point carries an education-level dimension.
  bool get hasLevelDimension =>
      allPoints.any((p) => !_isTotal(p.level));

  /// By education-level breakdown (UAE total, gender-total).
  /// Discovers whatever LEVEL codes exist in the data. Order is preserved by
  /// first appearance (so the natural curriculum order from the API is kept).
  Map<String, List<DataPoint>> get byLevel {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if (_isTotal(p.level)) continue;
      if (!_measureOk(p)) continue;
      (result[p.level!] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  /// By gender × level cross-breakdown (UAE total). Keys are "GENDER|LEVEL".
  Map<String, List<DataPoint>> get byGenderLevel {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (_isTotal(p.gender)) continue;
      if (_isTotal(p.level)) continue;
      if (!_measureOk(p)) continue;
      (result['${p.gender}|${p.level}'] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  /// True if any point carries an age-group dimension.
  bool get hasAgeDimension => allPoints.any((p) => !_isTotal(p.ageGroup));

  /// By age-group breakdown (UAE total, gender-total). Insertion order follows
  /// the API's natural age-band ordering. Total/aggregate codes excluded.
  Map<String, List<DataPoint>> get byAge {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if (_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      (result[p.ageGroup!] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  /// By gender × age cross-breakdown (UAE total). Keys are "GENDER|AGE".
  Map<String, List<DataPoint>> get byAgeGender {
    final result = <String, List<DataPoint>>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (_isTotal(p.gender)) continue;
      if (_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      (result['${p.gender}|${p.ageGroup}'] ??= []).add(p);
    }
    for (final list in result.values) {
      list.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return result;
  }

  // ─── Livestock (head-count census) helpers ───────────────────────────────

  /// True for the livestock census indicators (DF_LSCAMEL/CATTLE/GOAT/SHEEP).
  /// These are absolute head counts with a parent/child age hierarchy
  /// (4YR = 4YR_MIL + 4YR_NMIL) and a milch/non-milch female split.
  bool get isLivestock => meta.id.startsWith('livestock_');

  /// True for the Annual Rainfall indicator (DF_CLIMATE_RAIN). Monthly per
  /// weather station; headline = national annual average (mean of stations).
  bool get isRainfall => meta.id == 'ecology_rainfall';

  /// True for the Produced Water indicator (DF_PW_Q_PRODWATER_SOURCE). Annual
  /// MCM by entity (level) × water source (citizenship); headline = grand total.
  bool get isProducedWater => meta.id == 'ecology_produced_water';

  /// Rainfall: national annual-average series — mean across stations of each
  /// station's summed monthly RAIN_TOTAL for the year.
  List<DataPoint> get _rainfallNationalSeries {
    // year → station → summed monthly total
    final byYearStation = <String, Map<String, double>>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      // RAIN_TOTAL only (exclude RAINY_DAYS); station rows only.
      if (p.measure != null && p.measure != 'RAIN_TOTAL') continue;
      final station = p.level;
      if (station == null || _isTotal(station)) continue;
      final year = p.timePeriod.length >= 4 ? p.timePeriod.substring(0, 4) : p.timePeriod;
      tmpl ??= p;
      (byYearStation[year] ??= {}).update(
          station, (v) => v + p.value, ifAbsent: () => p.value);
    }
    if (byYearStation.isEmpty || tmpl == null) return const [];
    final out = <DataPoint>[];
    byYearStation.forEach((year, stations) {
      if (stations.isEmpty) return;
      final mean =
          stations.values.reduce((a, b) => a + b) / stations.length;
      out.add(tmpl!.copyWith(
          refArea: 'AE', level: '_T', value: mean, timePeriod: year));
    });
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Rainfall: latest-year annual total per station (code → mm), for By Station.
  Map<String, double> get rainfallByStation {
    // Find latest year.
    String latest = '';
    for (final p in allPoints) {
      if (p.measure != null && p.measure != 'RAIN_TOTAL') continue;
      final y = p.timePeriod.length >= 4 ? p.timePeriod.substring(0, 4) : p.timePeriod;
      if (y.compareTo(latest) > 0) latest = y;
    }
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.measure != null && p.measure != 'RAIN_TOTAL') continue;
      final station = p.level;
      if (station == null || _isTotal(station)) continue;
      final y = p.timePeriod.length >= 4 ? p.timePeriod.substring(0, 4) : p.timePeriod;
      if (y != latest) continue;
      out.update(station, (v) => v + p.value, ifAbsent: () => p.value);
    }
    return out;
  }

  /// Produced Water: grand-total MCM series (entity total × source total).
  List<DataPoint> get _producedWaterTotalSeries {
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (!_isTotal(p.level)) continue;        // PWT_ENTITY = _T
      if (!_isTotal(p.citizenship)) continue;  // WATER_SOURCE = _T
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Produced Water: latest-year MCM by entity (code → value), source-total.
  Map<String, double> get producedWaterByEntity {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.timePeriod != latest) continue;
      if (_isTotal(p.level)) continue;         // skip entity total
      if (!_isTotal(p.citizenship)) continue;  // source total only
      out[p.level!] = p.value;
    }
    return out;
  }

  /// Produced Water: latest-year MCM by water source (code → value), entity-total.
  Map<String, double> get producedWaterBySource {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.timePeriod != latest) continue;
      if (!_isTotal(p.level)) continue;        // entity total only
      if (_isTotal(p.citizenship)) continue;   // skip source total
      out[p.citizenship!] = p.value;
    }
    return out;
  }

  // ─── Energy & natural-reserve helpers ─────────────────────────────────────

  bool get isGenerationCapacity => meta.id == 'energy_generation_capacity';
  bool get isCrudeOil => meta.id == 'energy_crude_oil';
  bool get isRenewableEnergy => meta.id == 'energy_renewable';
  bool get isNaturalReserves => meta.id == 'ecology_natural_reserves';
  bool get isRamsarWetlands => meta.id == 'ecology_ramsar_wetlands';

  /// Indicators whose headline value carries one decimal place (MW/km²).
  bool get isDecimalCount =>
      isGenerationCapacity ||
      isRenewableEnergy ||
      isNaturalReserves ||
      isRamsarWetlands;

  /// Generation capacity (or renewable capacity): grand-total series — the
  /// GEN_TYPE/PLANT_TYPE = _T rows. For renewable, restrict to REP (capacity).
  List<DataPoint> get _categoryTotalSeries {
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.level)) continue; // GEN_TYPE/PLANT_TYPE total
      if (isRenewableEnergy && p.measure != null && p.measure != 'REP') continue;
      if (!_isTotal(p.ageGroup)) continue;
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Latest-year category → value map (GEN_TYPE / PLANT_TYPE), excluding total.
  /// For renewable, [reMeasure] selects REP (MW capacity) or EP (GWh output).
  Map<String, double> categoryBreakdown({String? reMeasure}) {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (p.timePeriod != latest) continue;
      if (_isTotal(p.level)) continue;
      if (reMeasure != null && p.measure != reMeasure) continue;
      out[p.level!] = p.value;
    }
    return out;
  }

  /// Crude oil: series for a given OG_SECTOR ('RE' reserves, 'PR', 'EX', 'IM').
  List<DataPoint> crudeOilSeries(String sectorCode) {
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (p.level != sectorCode) continue;
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Crude oil: latest-year trade-flow map (Production / Exports / Imports).
  Map<String, double> get crudeOilTradeFlow {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.timePeriod != latest) continue;
      const flows = {'PR', 'EX', 'IM'};
      if (!flows.contains(p.level)) continue;
      out[p.level!] = p.value;
    }
    return out;
  }

  /// Natural reserves: national grand-total series (REF_AREA=AE, type=_T,
  /// cohort=_T). Falls back to the latest year that publishes a total.
  List<DataPoint> get _reserveTotalSeries {
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE') continue;          // national total only
      if (!_isTotal(p.level)) continue;         // NR_TYPE = _T
      if (!_isTotal(p.ageGroup)) continue;      // EST_YEAR = _T
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Natural reserves: latest-year area by emirate (REF_AREA = AE-xx totals).
  Map<String, double> get reservesByEmirate {
    // Latest year that has emirate-total rows.
    String latest = '';
    for (final p in allPoints) {
      if ((p.refArea ?? '').startsWith('AE-') &&
          _isTotal(p.level) &&
          _isTotal(p.ageGroup) &&
          p.timePeriod.compareTo(latest) > 0) {
        latest = p.timePeriod;
      }
    }
    final out = <String, double>{};
    for (final p in allPoints) {
      final ra = p.refArea ?? '';
      if (!ra.startsWith('AE-')) continue;
      if (!_isTotal(p.level) || !_isTotal(p.ageGroup)) continue;
      if (p.timePeriod != latest) continue;
      out[ra] = p.value;
    }
    return out;
  }

  /// Reserves / RAMSAR: latest-year area by reserve type (Marine/Terrestrial/
  /// Ramsar) — sums each NR_TYPE across sites/cohorts (excludes totals).
  Map<String, double> get reservesByType {
    // Use the AE-level cohort-total rows when present (RAMSAR), else sum sites.
    final latest = latestPeriod;
    final out = <String, double>{};
    // Prefer AE + EST_YEAR=_T per NR_TYPE (works for RAMSAR).
    for (final p in allPoints) {
      if (p.refArea != 'AE') continue;
      if (p.timePeriod != latest) continue;
      if (!_isTotal(p.ageGroup)) continue;   // cohort total
      if (_isTotal(p.level)) continue;        // skip NR_TYPE total
      out[p.level!] = (out[p.level!] ?? 0) + p.value;
    }
    if (out.isNotEmpty) return out;
    // Fallback: sum across all sites by NR_TYPE (DF_NR_RESERVE).
    for (final p in allPoints) {
      if (p.timePeriod != latest) continue;
      if (_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      final ra = p.refArea ?? '';
      if (ra == 'AE' || ra.startsWith('AE-')) continue; // skip aggregates
      out[p.level!] = (out[p.level!] ?? 0) + p.value;
    }
    return out;
  }

  /// RAMSAR: latest-year area by designation-year cohort (EST_YEAR, type=_T).
  Map<String, double> get ramsarByCohort {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE') continue;
      if (p.timePeriod != latest) continue;
      if (!_isTotal(p.level)) continue;       // NR_TYPE = _T
      if (_isTotal(p.ageGroup)) continue;     // skip cohort total
      final v = p.value;
      if (v <= 0) continue;                   // omit empty cohorts
      out[p.ageGroup!] = v;
    }
    return out;
  }

  /// True if [code] is the "four/three years and above" PARENT age class —
  /// excluded from age-class breakdowns because it double-counts its children
  /// (Milch + Non-milch). Children: 4YR_MIL / 4YR_NMIL / 3YR_MIL / 3YR_NMIL.
  static bool _isLivestockParentAge(String? code) {
    if (code == null) return false;
    final c = code.toUpperCase();
    return c == '4YR' || c == '3YR' || c == '1YR';
  }

  /// All distinct (gender, ageClass) child cells present at UAE level for the
  /// latest year — excludes gender/age totals and the parent age class.
  /// Returned as a code→value map keyed "GENDER|AGE".
  Map<String, double> get livestockAgeClassCells {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (p.timePeriod != latest) continue;
      if (_isTotal(p.gender)) continue;
      if (_isTotal(p.ageGroup)) continue;
      if (_isLivestockParentAge(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      out['${p.gender}|${p.ageGroup}'] = p.value;
    }
    return out;
  }

  /// Female age-class detail (Milch / Non-milch / young) for the latest year —
  /// code→value keyed by the LS_AGE code (e.g. 4YR_MIL, 4YR_NMIL, L4YR).
  Map<String, double> get livestockFemaleDetail {
    final latest = latestPeriod;
    final out = <String, double>{};
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (p.timePeriod != latest) continue;
      if (p.gender != 'F') continue;
      if (_isTotal(p.ageGroup)) continue;
      if (_isLivestockParentAge(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      out[p.ageGroup!] = p.value;
    }
    return out;
  }

  /// Female / Male total head-count series (LS_AGE total), for the gender table.
  List<DataPoint> livestockGenderSeries(String genderCode) {
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if ((p.gender ?? '_T') != genderCode) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.citizenship)) continue;
      if (!_measureOk(p)) continue;
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  // ─── Summary helpers ──────────────────────────────────────────────────────

  /// Returns an [IndicatorSummary] (for tiles, sheet rows, related cards).
  IndicatorSummary toSummary() {
    final series = uaeTotalSeries;
    final values = series.map((p) => p.value).toList();
    final periods = series.map((p) => p.timePeriod).toList();
    return IndicatorSummary.fromDataPoints(
      id: meta.id,
      name: meta.name,
      sortedValues: values,
      sortedPeriods: periods,
      unitCode: meta.unitCode,
    );
  }

  /// Public SDMX REST data URL for this indicator's dataset.
  /// Used by the "View UAE Stats" action to open the official source.
  String get sourceUrl {
    final df = meta.dataflowId;
    if (df.isEmpty) return 'https://uaestat.fcsa.gov.ae';
    final freq = meta.frequency; // A | M | Q
    final start = switch (freq) {
      'M' => '${meta.coverageStart}-01',
      'Q' => '${meta.coverageStart}-Q1',
      _   => meta.coverageStart,
    };
    return 'https://releaseeuaestat.fcsc.gov.ae/rest/data/'
        '${meta.agencyId},$df,${meta.dataflowVersion}/all'
        '?startPeriod=$start&dimensionAtObservation=AllDimensions';
  }

  /// Latest value from the UAE total series.
  double get latestValue {
    final series = uaeTotalSeries;
    return series.isEmpty ? 0 : series.last.value;
  }

  /// Latest period string from the UAE total series.
  String get latestPeriod {
    final series = uaeTotalSeries;
    return series.isEmpty ? '—' : series.last.timePeriod;
  }

  // ─── 5-year statistics ────────────────────────────────────────────────────

  double get fiveYearMin {
    final vals = _last5Values;
    return vals.isEmpty ? 0 : vals.reduce((a, b) => a < b ? a : b);
  }

  double get fiveYearMax {
    final vals = _last5Values;
    return vals.isEmpty ? 0 : vals.reduce((a, b) => a > b ? a : b);
  }

  double get fiveYearAvg {
    final vals = _last5Values;
    return vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Growth from first to last in the 5-year window (%).
  double get fiveYearGrowth {
    final vals = _last5Values;
    if (vals.length < 2 || vals.first == 0) return 0;
    return ((vals.last - vals.first) / vals.first) * 100;
  }

  List<double> get _last5Values {
    final series = uaeTotalSeries;
    final slice = series.length > 5 ? series.sublist(series.length - 5) : series;
    return slice.map((p) => p.value).toList();
  }

  // ─── Range filters ────────────────────────────────────────────────────────

  /// Returns the UAE total series filtered by the last N years.
  List<DataPoint> rangeYears(int n) {
    final all = uaeTotalSeries;
    return all.length > n ? all.sublist(all.length - n) : all;
  }

  @override
  String toString() =>
      'IndicatorData(${meta.id}, ${allPoints.length} pts, '
      'latest: $latestValue @ $latestPeriod)';
}
