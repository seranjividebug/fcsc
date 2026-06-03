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

  /// UAE national total, sorted oldest → newest.
  ///
  /// Each FCSC dataflow uses different MEASURE dimension codes.
  /// Strategy:
  ///   1. Apply area + gender + citizenship filters first.
  ///   2. If a known measure code for this indicator exists in the data, use it.
  ///   3. If no known measure code matches (unknown dataflow version), fall back
  ///      to all area+gender+citizenship matched points — better to show data
  ///      than show zero.
  List<DataPoint> get uaeTotalSeries {
    final Set<String> allowedMeasures = switch (meta.id) {
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
      'labour_economic_activity'       => {'ECON_ACT'},
      'labour_employed_age_gender'     => {'EMP_AGE'},
      'labour_employed_education'      => {'EMP_EDU'},
      'labour_employment_sector'       => {'EMP_SEC'},
      'labour_unemployment_education'  => {'UNEMP_EDU'},
      'labour_workforce_occupation'    => {'WF_OCC'},
      'labour_unemployment_age_gender' => {'UNEMP_AGE'},
      _                   => {},
    };

    bool measureOk(DataPoint p) =>
        allowedMeasures.isEmpty ||
        p.measure == null ||
        allowedMeasures.contains(p.measure);

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
      if (!measureOk(p)) continue;
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
      if (!measureOk(p)) continue;
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
            (p.gender == '_T' || p.gender == null) &&
            (p.citizenship == '_T' || p.citizenship == null || p.citizenship == '_Z');
      }).toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (pts.isNotEmpty) result[code] = pts;
    }
    return result;
  }

  /// By-gender breakdown (UAE total, all citizenship).
  Map<String, List<DataPoint>> get byGender {
    final result = <String, List<DataPoint>>{};
    for (final g in ['M', 'F']) {
      final pts = allPoints.where((p) {
        return (p.refArea == 'AE' || p.refArea == null) &&
            p.gender == g &&
            (p.citizenship == '_T' || p.citizenship == null || p.citizenship == '_Z');
      }).toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (pts.isNotEmpty) result[g] = pts;
    }
    return result;
  }

  /// By-citizenship breakdown (births only — UAE total, both genders).
  Map<String, List<DataPoint>> get byCitizenship {
    final result = <String, List<DataPoint>>{};
    for (final c in ['EMIRATI', 'NON-EMIRATI']) {
      final pts = allPoints.where((p) {
        return (p.refArea == 'AE' || p.refArea == null) &&
            (p.gender == '_T' || p.gender == null) &&
            p.citizenship == c;
      }).toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (pts.isNotEmpty) result[c] = pts;
    }
    return result;
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
