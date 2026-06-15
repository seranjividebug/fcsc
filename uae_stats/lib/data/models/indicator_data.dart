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
      // Electricity: headline is national consumption; ELEC_* feed the
      // breakdown tabs and KPI cards only.
      'electricity'       => {'CONSUMPTION'},
      'births'            => {'B'},
      'deaths'            => {'DEATHS', 'D', 'D_TOTAL'},
      'marriages'         => {'MARRIAGES', 'M', 'MR'},
      'divorces'          => {'DIVORCES', 'DV', 'DV_TOTAL', 'D'},
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
      // Headline is tourism REVENUE (TOUR_REV); guests/other metrics are cards.
      'tourism_main_indicators'        => {'TOUR_REV', 'TOUR_MAIN', 'TOTAL', '_T'},
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
      'gdp_current'                    => {'GDP_CUR', 'GDP', 'B1GQ', 'TOTAL', '_T'},
      'gdp_constant'                   => {'GDP_CON', 'GDP', 'B1GQ', 'TOTAL', '_T'},
      // Quarterly Current: quarterly series (QGDP_CUR) is the headline; the
      // merged annual sector rows (GDP_CUR) feed the breakdown via byLevel.
      'gdp_quarterly_current'          => {'QGDP_CUR', 'GDP_CUR', 'B1GQ', 'TOTAL', '_T'},
      // Quarterly Constant: quarterly series (QGDP_CON) is the headline; the
      // merged annual sector rows (GDP_CON) feed the breakdown via byLevel.
      'gdp_quarterly_constant'         => {'QGDP_CON', 'GDP_CON', 'B1GQ', 'TOTAL', '_T'},
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
    // Employed by Age & Gender (% distribution): the headline is the PRIME
    // working-age share = sum of the 25–44 age-band Total shares per year.
    if (meta.id == 'labour_employed_age_gender') {
      const primeBands = {
        'Y25T29', 'Y30T34', 'Y35T39', 'Y40T44',
      };
      bool isPrime(String code) {
        final m = RegExp(r'(\d+)').firstMatch(code.toUpperCase());
        final start = m != null ? int.tryParse(m.group(1)!) : null;
        return primeBands.contains(code.toUpperCase()) ||
            (start != null && start >= 25 && start <= 40);
      }
      final byYear = <String, double>{};
      DataPoint? tmpl;
      for (final p in allPoints) {
        if (p.refArea != 'AE' && p.refArea != null) continue;
        if (!_isTotal(p.gender)) continue;
        if (p.ageGroup == null || _isTotal(p.ageGroup)) continue;
        if (!isPrime(p.ageGroup!)) continue;
        tmpl ??= p;
        byYear[p.timePeriod] = (byYear[p.timePeriod] ?? 0) + p.value;
      }
      if (byYear.isNotEmpty && tmpl != null) {
        return byYear.entries
            .map((e) => tmpl!.copyWith(
                ageGroup: '_T', value: e.value, timePeriod: e.key))
            .toList()
          ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      }
    }
    // Unemployment by Age & Gender (% distribution): the headline is the SINGLE
    // PEAK age group — the band with the highest Total share in the latest year
    // (e.g. 20–24 = 23.1%) — tracked over time, matching the breakdown's top
    // bar and the other top-category indicators.
    if (meta.id == 'labour_unemployment_age_gender') {
      final peakCode = topAgeBandCode;
      if (peakCode != null) {
        final s = byAge[peakCode];
        if (s != null && s.isNotEmpty) {
          return List<DataPoint>.from(s)
            ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
        }
      }
    }
    // Top-category % distributions (Economic Activity, Unemployment by
    // Education, Workforce by Occupation): the headline is the LEADING sector's
    // share — the single largest category in the latest year — so it matches
    // the breakdown's top bar (e.g. Construction 21.4%). Track that sector's
    // share over time.
    if (isTopCategoryShare) {
      final code = topSectorCode;
      if (code != null) {
        final s = byLevel[code];
        if (s != null && s.isNotEmpty) {
          return List<DataPoint>.from(s)
            ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
        }
      }
    }

    // Step 1: sum GENDER=_T, CITIZENSHIP=_T from the 7 emirate codes only.
    // This correctly aggregates datasets that publish per-emirate rows (Births, Deaths).
    const emirateCodes = {
      'AE-AZ', 'AE-DU', 'AE-SH', 'AE-AJ', 'AE-RK', 'AE-FJ', 'AE-UQ',
    };
    final emirateSums = <String, double>{};
    DataPoint? tmpl;
    for (final p in allPoints) {
      if (_isQuarterlyMergeRow(p)) continue; // GDP "By Quarter" rows only
      if (_isQuarterlyPageAnnualRow(p)) continue; // breakdown-only on Q page
      if (!emirateCodes.contains(p.refArea)) continue;
      if (p.gender != '_T' && p.gender != null) continue;
      if (p.citizenship != '_T' && p.citizenship != null && p.citizenship != '_Z') continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      tmpl ??= p;
      emirateSums[p.timePeriod] = (emirateSums[p.timePeriod] ?? 0) + p.value;
    }
    // Step 2: REF_AREA=AE national total directly.
    // Datasets like Marriages and Divorces only publish AE-level rows.
    final national = <String, DataPoint>{};
    for (final p in allPoints) {
      if (_isQuarterlyMergeRow(p)) continue; // GDP "By Quarter" rows only
      if (_isQuarterlyPageAnnualRow(p)) continue; // breakdown-only on Q page
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (p.gender != '_T' && p.gender != null) continue;
      if (p.citizenship != '_T' && p.citizenship != null && p.citizenship != '_Z') continue;
      if (!_isTotal(p.level)) continue;
      if (!_isTotal(p.ageGroup)) continue;
      if (!_measureOk(p)) continue;
      final existing = national[p.timePeriod];
      if (existing == null) {
        national[p.timePeriod] = p;
      } else if (_levelTotalRank(p.level) > _levelTotalRank(existing.level)) {
        // Prefer the canonical total level (`_T`/null) over ambiguous codes
        // like `T`, which collide with real category codes (e.g. ISIC `T` =
        // Households as Employers) and would otherwise hijack the headline.
        national[p.timePeriod] = p;
      } else if (_levelTotalRank(p.level) == _levelTotalRank(existing.level) &&
          p.citizenship == '_T' &&
          existing.citizenship != '_T') {
        national[p.timePeriod] = p;
      }
    }
    final nationalSeries = national.values.toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));

    // Prefer whichever series covers MORE years. This way a dataset that only
    // publishes per-emirate sub-rows for a single recent year (e.g. Hospitals'
    // emirate breakdown) doesn't collapse the long national trend to one point.
    if (emirateSums.isNotEmpty && tmpl != null &&
        emirateSums.length > nationalSeries.length) {
      return emirateSums.entries
          .map((e) =>
              tmpl!.copyWith(refArea: 'AE', value: e.value, timePeriod: e.key))
          .toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    if (nationalSeries.isNotEmpty) return nationalSeries;
    // Fallback: emirate sum even if shorter (datasets with only emirate rows).
    if (emirateSums.isNotEmpty && tmpl != null) {
      return emirateSums.entries
          .map((e) =>
              tmpl!.copyWith(refArea: 'AE', value: e.value, timePeriod: e.key))
          .toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    }
    return nationalSeries;
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

  /// True if this indicator is the Employed-by-Economic-Activity % distribution.
  bool get isEconomicActivity => meta.id == 'labour_economic_activity';

  /// True for % distributions whose headline is the single leading category
  /// (Economic Activity, Unemployment by Education, Workforce by Occupation).
  bool get isTopCategoryShare =>
      meta.id == 'labour_economic_activity' ||
      meta.id == 'labour_unemployment_education' ||
      meta.id == 'labour_workforce_occupation' ||
      meta.id == 'labour_employed_education' ||
      meta.id == 'labour_employment_sector';

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

  /// The peak age-band code in the latest year (gender-Total) — the band with
  /// the highest share, e.g. 'Y20T24'. Used by Unemployment by Age & Gender.
  String? get topAgeBandCode {
    String? best;
    double bestVal = -1;
    byAge.forEach((code, series) {
      if (series.isEmpty) return;
      final v = series.last.value;
      if (v > bestVal) {
        bestVal = v;
        best = code;
      }
    });
    return best;
  }

  // ─── GDP by economic activity (DF_NA_ISIC_*) ─────────────────────────────

  /// True for the annual GDP-by-ISIC indicators (current / constant prices),
  /// which carry an ISIC economic-activity breakdown in the `level` dimension.
  bool get isGdpIsic =>
      meta.id == 'gdp_current' ||
      meta.id == 'gdp_constant' ||
      meta.id == 'gdp_quarterly_current' ||
      meta.id == 'gdp_quarterly_constant';

  /// ISIC codes that are NOT a real producing sector and must be excluded from
  /// the sector ranking: `_TNO` (total non-oil aggregate) and `NFC`
  /// (Financial Intermediation Services Indirectly Measured — an adjustment).
  static const _gdpNonSectorCodes = {'_TNO', 'NFC'};

  /// Latest-year GDP value of the non-oil aggregate (ISIC `_TNO`), in the same
  /// unit as the headline (AED millions). Null when the breakdown is absent.
  double? get gdpNonOilLatest {
    if (!isGdpIsic) return null;
    final s = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if ((p.level ?? '').toUpperCase() != '_TNO') continue;
      s.add(p);
    }
    if (s.isEmpty) return null;
    s.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return s.last.value;
  }

  /// Annual GDP total series (level `_T`, measure `GDP_CUR`/`GDP_CON`), oldest
  /// → newest. On the Quarterly pages the headline is quarterly, so this gives
  /// access to the merged ANNUAL total for the KPI cards. Empty when absent.
  List<DataPoint> get gdpAnnualTotalSeries {
    if (!isGdpIsic) return const [];
    final s = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if (p.measure != 'GDP_CUR' && p.measure != 'GDP_CON') continue;
      if ((p.level ?? '_T') != '_T') continue;
      s.add(p);
    }
    s.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return s;
  }

  /// Non-oil GDP series (ISIC `_TNO`), oldest → newest. Empty when absent.
  List<DataPoint> get gdpNonOilSeries {
    if (!isGdpIsic) return const [];
    final s = <DataPoint>[];
    for (final p in allPoints) {
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if ((p.level ?? '').toUpperCase() != '_TNO') continue;
      s.add(p);
    }
    s.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return s;
  }

  /// Year-on-year growth (%) of non-oil GDP (latest vs prior year). Null when
  /// fewer than two non-oil points exist or the prior value is zero.
  double? get gdpNonOilYoY {
    final s = gdpNonOilSeries;
    if (s.length < 2) return null;
    final prev = s[s.length - 2].value;
    if (prev == 0) return null;
    return (s.last.value - prev) / prev * 100;
  }

  /// The prior-year period for the non-oil YoY label (e.g. "2023").
  String? get gdpNonOilPrevPeriod {
    final s = gdpNonOilSeries;
    if (s.length < 2) return null;
    return s[s.length - 2].timePeriod;
  }

  /// Latest-year leading GDP sector — its ISIC code, value and share of the
  /// headline total — excluding the non-sector aggregates. Null when absent.
  ({String code, double value, double share})? get gdpTopSector {
    if (!isGdpIsic) return null;
    final total = latestValue;
    if (total <= 0) return null;
    String? best;
    double bestVal = -1;
    byLevel.forEach((code, series) {
      if (series.isEmpty) return;
      if (_gdpNonSectorCodes.contains(code.toUpperCase())) return;
      final v = series.last.value;
      if (v > bestVal) {
        bestVal = v;
        best = code;
      }
    });
    if (best == null) return null;
    return (code: best!, value: bestVal, share: bestVal / total * 100);
  }

  /// Human-readable sector label resolved from the data's `categoryLabel`
  /// (set by dataflows that carry sector names, e.g. Quarterly GDP). Null when
  /// the breakdown has no embedded name — caller falls back to a code map.
  String? gdpSectorLabel(String code) {
    final series = byLevel[code];
    if (series == null || series.isEmpty) return null;
    final label = series.last.categoryLabel;
    return (label == null || label.isEmpty) ? null : label;
  }

  /// Latest-year GDP value per real sector (ISIC code → value), sorted highest
  /// first. Excludes the `_TNO` / `NFC` aggregates (already filtered by
  /// [byLevel]). Empty when no sector breakdown is present.
  List<({String code, double value})> get gdpSectorsLatest {
    if (!isGdpIsic) return const [];
    final out = <({String code, double value})>[];
    byLevel.forEach((code, series) {
      if (series.isEmpty) return;
      out.add((code: code, value: series.last.value));
    });
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Oil vs Non-Oil comparison rows for the latest year: the non-oil aggregate
  /// (`_TNO`) followed by the leading individual sectors. Sorted highest first.
  List<({String code, double value})> get gdpOilVsNonOil {
    if (!isGdpIsic) return const [];
    final nonOil = gdpNonOilLatest;
    final out = <({String code, double value})>[];
    if (nonOil != null) out.add((code: '_TNO', value: nonOil));
    out.addAll(gdpSectorsLatest);
    return out;
  }

  /// Per-sector cumulative growth (%) from the first to the last year present
  /// in each sector's series (e.g. 2015→2024), sorted highest first. Sectors
  /// with fewer than two points or a zero base are skipped.
  List<({String code, double growth, String fromYear, String toYear})>
      get gdpSectorGrowth {
    if (!isGdpIsic) return const [];
    final out =
        <({String code, double growth, String fromYear, String toYear})>[];
    byLevel.forEach((code, series) {
      if (series.length < 2) return;
      final first = series.first.value;
      if (first == 0) return;
      final g = (series.last.value - first) / first * 100;
      out.add((
        code: code,
        growth: g,
        fromYear: series.first.timePeriod,
        toYear: series.last.timePeriod,
      ));
    });
    out.sort((a, b) => b.growth.compareTo(a.growth));
    return out;
  }

  /// Quarterly GDP totals merged into the GDP-Constant page (measure
  /// `QGDP_CON`, timePeriod "<year>-Qn"). Returned as (label, value) sorted by
  /// value descending — matching the "By Quarter" reference layout. Empty when
  /// no quarterly rows are present.
  List<({String label, double value})> get gdpQuarterly {
    // Source 1: merged quarter-total rows (QGDP_CON / QGDP_CUR_Q) added on the
    // annual GDP pages. Source 2 (fallback): the page's own quarterly series
    // (e.g. Quarterly GDP indicators, periods like "2024-Q2"), restricted to
    // the latest year that publishes all four quarters.
    String labelFor(String tp) {
      final dash = tp.indexOf('-');
      return dash > 0
          ? '${tp.substring(dash + 1)} ${tp.substring(0, dash)}'
          : tp;
    }

    const quarterTabMeasures = {'QGDP_CUR_Q', 'QGDP_CON_Q'};
    final merged = <({String label, double value})>[];
    for (final p in allPoints) {
      // On the ANNUAL GDP pages the By Quarter tab uses the merged QGDP_CON
      // totals; the Quarterly pages use the dedicated *_Q rows.
      final isAnnualPage =
          meta.id == 'gdp_current' || meta.id == 'gdp_constant';
      final ok = quarterTabMeasures.contains(p.measure) ||
          (isAnnualPage && p.measure == 'QGDP_CON');
      if (!ok) continue;
      merged.add((label: labelFor(p.timePeriod), value: p.value));
    }
    if (merged.isNotEmpty) {
      merged.sort((a, b) => b.value.compareTo(a.value));
      return merged;
    }

    // Fallback: derive from the quarterly headline series.
    final quarterly =
        uaeTotalSeries.where((p) => p.timePeriod.contains('-Q')).toList();
    if (quarterly.isEmpty) return const [];
    final byYear = <String, List<DataPoint>>{};
    for (final p in quarterly) {
      final yr = p.timePeriod.split('-').first;
      (byYear[yr] ??= []).add(p);
    }
    final years = byYear.keys.toList()..sort();
    String target = years.last;
    for (final y in years.reversed) {
      if ((byYear[y]?.length ?? 0) >= 4) {
        target = y;
        break;
      }
    }
    final out = (byYear[target] ?? const [])
        .map((p) => (label: labelFor(p.timePeriod), value: p.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  // ─── Aircraft Movement by emirate (DF_AIRCRAFT_MOV) ──────────────────────

  bool get isAircraftMovement => meta.id == 'aircraft_movement';

  static const _emirateNames = <String, String>{
    'AE-DU': 'Dubai', 'AE-AZ': 'Abu Dhabi', 'AE-SH': 'Sharjah',
    'AE-AJ': 'Ajman', 'AE-RK': 'Ras Al Khaimah', 'AE-FJ': 'Fujairah',
    'AE-UQ': 'Umm Al Quwain',
  };

  /// Latest-year per-emirate aircraft movements for a given [level] code:
  /// null/`_T` = total movements, `ARR` = arrivals, `DEP` = departures.
  /// Returns (emirate label, value) sorted descending.
  List<({String label, double value})> aircraftByEmirate({String? level}) {
    if (!isAircraftMovement) return const [];
    // Latest year among the matching rows.
    String latest = '';
    bool match(DataPoint p) =>
        (p.refArea ?? '').startsWith('AE-') &&
        ((level == null) ? _isTotal(p.level) : (p.level ?? '') == level);
    for (final p in allPoints) {
      if (!match(p)) continue;
      if (p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
    }
    if (latest.isEmpty) {
      // No combined per-emirate total rows (some sources publish only the
      // ARR/DEP movement-type rows). Fall back to ARR + DEP per emirate so the
      // "By Emirate" tab is never empty when arrivals/departures exist.
      if (level == null) return _aircraftEmirateArrPlusDep();
      return const [];
    }
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (!match(p) || p.timePeriod != latest) continue;
      out.add((
        label: _emirateNames[p.refArea] ?? (p.refArea ?? ''),
        value: p.value,
      ));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Combined per-emirate movement = arrivals + departures for the latest year,
  /// used when the source has no explicit per-emirate total rows.
  List<({String label, double value})> _aircraftEmirateArrPlusDep() {
    final arr = aircraftByEmirate(level: 'ARR');
    final dep = aircraftByEmirate(level: 'DEP');
    if (arr.isEmpty && dep.isEmpty) return const [];
    final byLabel = <String, double>{};
    for (final r in arr) {
      byLabel[r.label] = (byLabel[r.label] ?? 0) + r.value;
    }
    for (final r in dep) {
      byLabel[r.label] = (byLabel[r.label] ?? 0) + r.value;
    }
    final out = byLabel.entries
        .map((e) => (label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// National sum of a movement [level] ('ARR' / 'DEP') for the latest year
  /// that publishes it. 0 when absent.
  double aircraftFlowTotal(String level) {
    final rows = aircraftByEmirate(level: level);
    return rows.fold<double>(0, (a, r) => a + r.value);
  }

  /// Share (%) of the national total held by a given emirate [code] in the
  /// latest year. Null when unavailable.
  double? aircraftEmirateShare(String code) {
    final total = latestValue;
    if (total <= 0) return null;
    for (final p in allPoints) {
      if (p.refArea != code) continue;
      if (!_isTotal(p.level)) continue;
      if (p.timePeriod != latestPeriod) continue;
      return p.value / total * 100;
    }
    // Fall back to the latest emirate-total year if it differs from national.
    final rows = aircraftByEmirate();
    for (final r in rows) {
      if ((_emirateNames[code] ?? code) == r.label) return r.value / total * 100;
    }
    return null;
  }

  /// Growth (%) of the latest national value vs a specific past [year]
  /// (e.g. 2019 pre-COVID, 2020 low). Null when either point is missing.
  double? aircraftGrowthVsYear(String year) {
    final s = uaeTotalSeries;
    if (s.isEmpty) return null;
    DataPoint? base;
    for (final p in s) {
      if (p.timePeriod == year) base = p;
    }
    if (base == null || base.value == 0) return null;
    return (s.last.value - base.value) / base.value * 100;
  }

  /// Per-emirate YoY growth (%) of total movements (latest vs prior year),
  /// sorted descending. Empty when fewer than two years of per-emirate data.
  List<({String label, double growth})> get aircraftEmirateGrowth {
    if (!isAircraftMovement) return const [];
    // emirate → year → total
    final byEm = <String, Map<String, double>>{};
    for (final p in allPoints) {
      final ra = p.refArea ?? '';
      if (!ra.startsWith('AE-')) continue;
      if (!_isTotal(p.level)) continue; // totals only (skip ARR/DEP)
      (byEm[ra] ??= {})[p.timePeriod] = p.value;
    }
    final out = <({String label, double growth})>[];
    byEm.forEach((ra, years) {
      final sorted = years.keys.toList()..sort();
      if (sorted.length < 2) return;
      final prev = years[sorted[sorted.length - 2]]!;
      final last = years[sorted.last]!;
      if (prev == 0) return;
      out.add((
        label: _emirateNames[ra] ?? ra,
        growth: (last - prev) / prev * 100,
      ));
    });
    out.sort((a, b) => b.growth.compareTo(a.growth));
    return out;
  }

  // ─── Total Trade (DF_TRADE_*) merged breakdown ───────────────────────────

  bool get isTradeTotal => meta.id == 'trade_total';

  /// Latest-year value of a merged trade FLOW (measure `TRADE_FLOW`), by code
  /// ('IMP' / 'NONOIL_EXP' / 'REEXP'). Null when absent.
  double? tradeFlow(String code) {
    double? v;
    String best = '';
    for (final p in allPoints) {
      if (p.measure != 'TRADE_FLOW') continue;
      if ((p.level ?? '') != code) continue;
      if (p.timePeriod.compareTo(best) >= 0) {
        best = p.timePeriod;
        v = p.value;
      }
    }
    return v;
  }

  /// Latest-year trade HS-section rows for a flow, sorted descending. [measure]
  /// is `TRADE_IMP_SEC` (imports) or `TRADE_EXP_SEC` (exports). Each row carries
  /// the section value (AED Mn) and its display label.
  List<({String label, double value})> _tradeSections(String measure) {
    // Find latest year for this measure.
    String latest = '';
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      if (p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
    }
    if (latest.isEmpty) return const [];
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure || p.timePeriod != latest) continue;
      out.add((label: p.categoryLabel ?? (p.level ?? ''), value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  List<({String label, double value})> get tradeImportSections =>
      _tradeSections('TRADE_IMP_SEC');

  /// Latest-year import rows for a given [measure] tag (suppliers / regions),
  /// labelled by categoryLabel, sorted descending.
  List<({String label, double value})> _tradeNamed(String measure) {
    String latest = '';
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      if (p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
    }
    if (latest.isEmpty) return const [];
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure || p.timePeriod != latest) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Top supplier countries by import value (latest year).
  List<({String label, double value})> get tradeImportSuppliers =>
      _tradeNamed('TRADE_IMP_SUP');

  /// Imports grouped by world region (latest year).
  List<({String label, double value})> get tradeImportRegions =>
      _tradeNamed('TRADE_IMP_REG');

  /// Number of partner nations (measure `TRADE_IMP_PARTNERS`). Null when absent.
  int? get tradeImportPartnerCount {
    for (final p in allPoints) {
      if (p.measure == 'TRADE_IMP_PARTNERS') return p.value.round();
    }
    return null;
  }

  /// The leading supplier (name + % share of total imports). Null when absent.
  ({String name, double share})? get tradeTopSupplier {
    final sup = tradeImportSuppliers;
    if (sup.isEmpty) return null;
    final total = latestValue;
    if (total <= 0) return null;
    return (name: sup.first.label, share: sup.first.value / total * 100);
  }

  // ─── Annual Rainfall breakdown (DF_CLIMATE_RAIN) ─────────────────────────

  /// Rainfall scalar (value + optional note in obsStatus) by RF_* measure.
  ({double value, String? note})? _rfScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return (value: p.value, note: p.obsStatus);
    }
    return null;
  }

  ({double value, String? note})? get rfWettestYear => _rfScalar('RF_WETYEAR');
  ({double value, String? note})? get rfRainyDays => _rfScalar('RF_RAINYDAYS');
  ({double value, String? note})? get rfWettestStation =>
      _rfScalar('RF_WETSTATION');
  ({double value, String? note})? get rfDriestStation =>
      _rfScalar('RF_DRYSTATION');

  /// Rainfall breakdown rows for [measure] (label, mm value), desc.
  List<({String label, double value})> rfBreakdown(String measure) {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  // ─── Mean Temperature (DF_CLIMATE_TEMP) ──────────────────────────────────

  bool get isMeanTemp => meta.id == 'ecology_mean_temp';

  /// Scalar temperature value (+ optional month label in obsStatus) by measure.
  ({double value, String? month})? _mtScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return (value: p.value, month: p.obsStatus);
    }
    return null;
  }

  ({double value, String? month})? get mtPeakMonth => _mtScalar('MT_PEAK');
  ({double value, String? month})? get mtCoolestMonth => _mtScalar('MT_COOL');
  ({double value, String? month})? get mtAnnualRange => _mtScalar('MT_RANGE');
  ({double value, String? month})? get mtMeanMaxAvg => _mtScalar('MT_MAXAVG');

  /// Temperature breakdown rows for [measure] (label, °C value), desc.
  List<({String label, double value})> mtBreakdown(String measure) {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  // ─── Tourism Main Indicators (DF_HOT_INDICATOR) ──────────────────────────

  bool get isTourismMain => meta.id == 'tourism_main_indicators';

  /// Scalar tourism KPI (value + optional YoY/percent in obsStatus) by measure.
  ({double value, double? pct})? _tmScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure != measure) {
        continue;
      }
      return (
        value: p.value,
        pct: p.obsStatus != null ? double.tryParse(p.obsStatus!) : null,
      );
    }
    return null;
  }

  /// Tourism guests series (measure TOUR_GUESTS), oldest → newest.
  List<DataPoint> get tmGuestsSeries {
    final s = <DataPoint>[];
    for (final p in allPoints) {
      if (p.measure != 'TOUR_GUESTS') continue;
      s.add(p);
    }
    s.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return s;
  }

  /// Latest tourism guests value + YoY (%).
  ({double value, double? yoy})? get tmGuests {
    final s = tmGuestsSeries;
    if (s.isEmpty) return null;
    double? yoy;
    if (s.length >= 2 && s[s.length - 2].value != 0) {
      yoy = (s.last.value - s[s.length - 2].value) / s[s.length - 2].value * 100;
    }
    return (value: s.last.value, yoy: yoy);
  }

  ({double value, double? pct})? get tmRevenue => _tmScalar('TM_REVENUE');
  ({double value, double? pct})? get tmAvgRoomRate => _tmScalar('TM_ARR');
  ({double value, double? pct})? get tmRoomNights => _tmScalar('TM_ROOMNIGHTS');
  ({double value, double? pct})? get tmOccupancy => _tmScalar('TM_OCCUPANCY');
  ({double value, double? pct})? get tmAvgStay => _tmScalar('TM_AVGSTAY');
  ({double value, double? pct})? get tmHotels => _tmScalar('TM_HOTELS');
  ({double value, double? pct})? get tmRooms => _tmScalar('TM_ROOMS');

  /// Tourism breakdown rows for [measure] (label, value, optional pct), desc.
  List<({String label, double value, double? pct})> tmBreakdown(String measure) {
    final out = <({String label, double value, double? pct})>[];
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      out.add((
        label: p.categoryLabel ?? '',
        value: p.value,
        pct: p.obsStatus != null ? double.tryParse(p.obsStatus!) : null,
      ));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  // ─── Hotel Establishments (DF_HOT_TYPE) ──────────────────────────────────

  bool get isHotelEstablishments => meta.id == 'tourism_hotel_establishments';

  /// Hotel-establishment breakdown rows for [measure], latest year. Each row
  /// carries an optional published share/percent (parsed from obsStatus).
  List<({String label, double value, double? pct})> _heRows(String measure) {
    String latest = '';
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      if (p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
    }
    if (latest.isEmpty) return const [];
    final out = <({String label, double value, double? pct})>[];
    for (final p in allPoints) {
      if (p.measure != measure || p.timePeriod != latest) continue;
      out.add((
        label: p.categoryLabel ?? '',
        value: p.value,
        pct: p.obsStatus != null ? double.tryParse(p.obsStatus!) : null,
      ));
    }
    return out;
  }

  List<({String label, double value, double? pct})> get heByClass =>
      _heRows('HE_CLASS')..sort((a, b) => b.value.compareTo(a.value));
  List<({String label, double value, double? pct})> get heHotelsVsApts =>
      _heRows('HE_HVA');
  List<({String label, double value, double? pct})> get heByRoomShare =>
      _heRows('HE_ROOM')..sort((a, b) => b.value.compareTo(a.value));
  List<({String label, double value, double? pct})> get heClassGrowth =>
      _heRows('HE_GROWTH');

  double? _heScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return p.value;
    }
    return null;
  }

  double? get heTotalRooms => _heScalar('HE_TOTAL_ROOMS');
  double? get heHotels => _heScalar('HE_HOTELS');
  double? get heApts => _heScalar('HE_APTS');

  // ─── Hotel Guest Arrivals by Nationality (DF_GUEST_REGION) ───────────────

  bool get isHotelArrivals => meta.id == 'tourism_hotel_arrivals';

  /// Latest-year guest arrivals by nationality region (label, value), desc.
  List<({String label, double value})> get hotelArrivalsByNationality =>
      _tradeNamed('HTL_ARR_NAT');

  /// Market-share rows (% of total) by nationality, desc.
  List<({String label, double value})> get hotelArrivalsShare {
    final n = hotelArrivalsByNationality;
    final total = n.fold<double>(0, (a, r) => a + r.value);
    if (total <= 0) return const [];
    return n
        .map((r) => (label: r.label, value: r.value / total * 100))
        .toList();
  }

  /// Number of nationality region groups.
  int get hotelArrivalsRegionCount => hotelArrivalsByNationality.length;

  /// Top origin region (name + % share). Null when absent.
  ({String name, double share})? get hotelArrivalsTopOrigin {
    final s = hotelArrivalsShare;
    if (s.isEmpty) return null;
    return (name: _shortRegion(s.first.label), share: s.first.value);
  }

  /// Peak year (highest annual total) + its value.
  ({String year, double value})? get hotelArrivalsPeakYear {
    final s = uaeTotalSeries;
    if (s.isEmpty) return null;
    final peak = s.reduce((a, b) => b.value > a.value ? b : a);
    return (year: peak.timePeriod, value: peak.value);
  }

  /// "Asian Countries" → "Asia" for the compact Top-Origin card.
  static String _shortRegion(String name) {
    final n = name.toLowerCase();
    if (n.startsWith('asian')) return 'Asia';
    if (n.startsWith('european')) return 'Europe';
    if (n.startsWith('arab')) return 'Arab';
    if (n.startsWith('gcc')) return 'GCC';
    if (n.startsWith('american')) return 'Americas';
    if (n.startsWith('african')) return 'Africa';
    return name;
  }

  // ─── CPI Annual (DF_CPI_ANN) ─────────────────────────────────────────────

  bool get isCpiAnnual => meta.id == 'prices_cpi_annual';

  /// CPI division rows for a given [measure] ('CPI_DIV_IDX' / 'CPI_DIV_CHG')
  /// and [year], sorted by value descending.
  List<({String label, double value})> cpiDivisions(String measure, String year) {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure || p.timePeriod != year) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Latest CPI all-items index value.
  double get cpiLatest => latestValue;

  /// Annual inflation (%) — latest all-items index vs prior year.
  double? get cpiInflation {
    final s = uaeTotalSeries;
    if (s.length < 2 || s[s.length - 2].value == 0) return null;
    return (s.last.value - s[s.length - 2].value) / s[s.length - 2].value * 100;
  }

  /// The division with the highest index in the latest year (name + points).
  ({String name, double points})? get cpiPeakDivision {
    final divs = cpiDivisions('CPI_DIV_IDX', latestPeriod)
        .where((d) => d.label.toLowerCase() != 'all items')
        .toList();
    if (divs.isEmpty) return null;
    return (name: divs.first.label, points: divs.first.value);
  }

  // ─── Monthly Re-Exports (DF_TRADE_REXP_COUNTRY_MTH) ──────────────────────

  bool get isMonthlyReExports => meta.id == 'trade_reexports_monthly';

  List<({String label, double value})> get monthlyReExportDestinations =>
      _tradeNamed('MRE_CTRY');

  List<({String label, double value})> get monthlyReExportRegions =>
      _tradeNamed('MRE_REG');

  int? get monthlyReExportDestinationCount {
    for (final p in allPoints) {
      if (p.measure == 'MRE_DEST') return p.value.round();
    }
    return null;
  }

  /// Full prior-year total (measure `MRE_FULLYR`). Null when absent.
  ({String year, double value})? get monthlyReExportFullYear {
    for (final p in allPoints) {
      if (p.measure == 'MRE_FULLYR') {
        return (year: p.timePeriod, value: p.value);
      }
    }
    return null;
  }

  /// Top destination of monthly re-exports (name + % of latest month value).
  ({String name, double share})? get monthlyReExportTopDest {
    final c = monthlyReExportDestinations;
    if (c.isEmpty) return null;
    // Share is a published headline figure (12.6%); approximate from the
    // annual full-year total when available, else the destinations sum.
    final base = monthlyReExportFullYear?.value ??
        c.fold<double>(0, (a, r) => a + r.value);
    if (base <= 0) return null;
    return (name: c.first.label, share: c.first.value / base * 100);
  }

  /// YTD growth (%) — sum of the latest year's months vs the same months of the
  /// prior year. Months come from the monthly series (period "YYYY-MM").
  ({double growth, String fromLabel})? get monthlyReExportYtdGrowth {
    final months = uaeTotalSeries.where((p) => p.timePeriod.contains('-')).toList();
    if (months.isEmpty) return null;
    final years = months.map((p) => p.timePeriod.split('-').first).toSet().toList()
      ..sort();
    if (years.length < 2) return null;
    final cur = years.last, prev = years[years.length - 2];
    // Restrict prior year to the same set of months present in the current year.
    final curMonths = months
        .where((p) => p.timePeriod.startsWith(cur))
        .map((p) => p.timePeriod.split('-')[1])
        .toSet();
    double sum(String yr) => months
        .where((p) =>
            p.timePeriod.startsWith(yr) &&
            curMonths.contains(p.timePeriod.split('-')[1]))
        .fold<double>(0, (a, p) => a + p.value);
    final c = sum(cur), pv = sum(prev);
    if (pv == 0) return null;
    // Label like "Jan–Sep <prevYear>".
    final lastM = int.tryParse(
            (months.where((p) => p.timePeriod.startsWith(cur)).toList()
                  ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod)))
                .last
                .timePeriod
                .split('-')[1]) ??
        12;
    const mn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];
    return (growth: (c - pv) / pv * 100, fromLabel: 'Jan–${mn[lastM]} $prev');
  }

  /// Per-month YoY growth (%) of the latest year's months vs the same month a
  /// year earlier, sorted by growth descending. Empty when <13 months.
  List<({String label, double growth})> get monthlyReExportGrowth {
    final months = uaeTotalSeries.where((p) => p.timePeriod.contains('-')).toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    if (months.length < 13) return const [];
    final byPeriod = {for (final p in months) p.timePeriod: p.value};
    final years = months.map((p) => p.timePeriod.split('-').first).toSet().toList()
      ..sort();
    final cur = years.last;
    const mn = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];
    final out = <({String label, double growth})>[];
    for (final p in months.where((p) => p.timePeriod.startsWith(cur))) {
      final m = p.timePeriod.split('-')[1];
      final prevKey = '${int.parse(cur) - 1}-$m';
      final prev = byPeriod[prevKey];
      if (prev == null || prev == 0) continue;
      out.add((
        label: '${mn[int.parse(m)]} $cur',
        growth: (p.value - prev) / prev * 100,
      ));
    }
    out.sort((a, b) => b.growth.compareTo(a.growth));
    return out;
  }

  // ─── Non-Oil Exports breakdown (DF_TRADE_TEXP_*) ──────────────────────────

  /// Export "By Trade Type" rows (Total Non-Oil / Re-Exports / Domestic).
  List<({String label, double value})> get exportByType =>
      _tradeNamed('EXP_FLOW');

  /// Export HS-section rows (latest year), sorted descending.
  List<({String label, double value})> get exportSections =>
      _tradeNamed('EXP_HS');

  /// Export destination-country rows (latest year), sorted descending.
  List<({String label, double value})> get exportCountries =>
      _tradeNamed('EXP_CTRY');

  /// Export rows grouped by world region (latest year), sorted descending.
  List<({String label, double value})> get exportRegions =>
      _tradeNamed('EXP_REG');

  /// Number of export destination markets (measure `EXP_DEST`). Null if absent.
  int? get exportDestinationCount {
    for (final p in allPoints) {
      if (p.measure == 'EXP_DEST') return p.value.round();
    }
    return null;
  }

  /// Latest-year value of a named export flow ('Re-Exports' / 'Domestic …').
  double? exportFlow(String labelContains) {
    for (final r in exportByType) {
      if (r.label.toLowerCase().contains(labelContains.toLowerCase())) {
        return r.value;
      }
    }
    return null;
  }

  /// The leading export destination (name + % share of total). Null if absent.
  ({String name, double share})? get exportTopMarket {
    // Exclude the "Other Markets" catch-all from the top pick.
    final real = exportCountries
        .where((c) => !c.label.toLowerCase().contains('other'))
        .toList();
    if (real.isEmpty) return null;
    final total = latestValue;
    if (total <= 0) return null;
    return (name: real.first.label, share: real.first.value / total * 100);
  }

  List<({String label, double value})> get tradeExportSections =>
      _tradeSections('TRADE_EXP_SEC');

  /// "By Trade Type" rows: Imports / Total Non-Oil Exp / Re-Exports, sorted
  /// descending. Empty when no flow totals were merged.
  List<({String label, double value})> get tradeByType {
    final imp = tradeFlow('IMP');
    final nonOil = tradeFlow('NONOIL_EXP');
    final reExp = tradeFlow('REEXP');
    final out = <({String label, double value})>[];
    if (imp != null) out.add((label: 'Imports', value: imp));
    if (nonOil != null) out.add((label: 'Total Non-Oil Exp', value: nonOil));
    if (reExp != null) out.add((label: 'Re-Exports', value: reExp));
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Per-year YoY growth (%) of the headline series, newest year first. Used by
  /// the "Annual Growth" breakdown tab.
  List<({String year, double growth})> get seriesAnnualGrowth {
    final s = uaeTotalSeries;
    final out = <({String year, double growth})>[];
    for (var i = 1; i < s.length; i++) {
      final prev = s[i - 1].value;
      if (prev == 0) continue;
      out.add((year: s[i].timePeriod, growth: (s[i].value - prev) / prev * 100));
    }
    out.sort((a, b) => b.year.compareTo(a.year));
    return out;
  }

  /// Latest-year value of the headline total-trade series (AED Mn).
  double get tradeTotalLatest => latestValue;

  /// Year-on-year growth (%) of total trade (latest vs prior year).
  double? get tradeTotalYoY {
    final s = uaeTotalSeries;
    if (s.length < 2 || s[s.length - 2].value == 0) return null;
    return (s.last.value - s[s.length - 2].value) / s[s.length - 2].value * 100;
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

  /// True for the marriage/divorce contract dataflows (DF_MR_NA / DF_DV_NA),
  /// where emirates publish only couple-type sub-rows (no per-emirate total),
  /// so the emirate total must be summed from the sub-types.
  bool get isMarriageDivorce =>
      meta.id == 'marriages' || meta.id == 'divorces';

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
      // Marriages/Divorces: emirates carry only couple-type sub-rows, so sum
      // them per year to get that emirate's total. Prefer an explicit total
      // row (M_TOT/D_TOT) if one exists; otherwise sum the sub-types.
      if (isMarriageDivorce) {
        final emiratePts =
            allPoints.where((p) => p.refArea == code && _measureOk(p)).toList();
        if (emiratePts.isEmpty) continue;
        final hasTotalRow = emiratePts.any((p) => _isTotal(p.level));
        final byYear = <String, double>{};
        DataPoint? tmpl;
        for (final p in emiratePts) {
          if (hasTotalRow ? !_isTotal(p.level) : _isTotal(p.level)) continue;
          tmpl ??= p;
          byYear[p.timePeriod] = (byYear[p.timePeriod] ?? 0) + p.value;
        }
        if (byYear.isEmpty || tmpl == null) continue;
        result[code] = byYear.entries
            .map((e) =>
                tmpl!.copyWith(value: e.value, timePeriod: e.key, level: '_T'))
            .toList()
          ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
        continue;
      }
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
  static const _totalCodes = {
    '_T', '_Z', 'T', 'TOTAL', 'ALL', '_O',
    'M_TOT', 'D_TOT', // DF_MR_NA / DF_DV_NA total marriage/divorce contracts
  };

  static bool _isTotal(String? code) =>
      code == null || _totalCodes.contains(code.toUpperCase());

  /// True for the quarterly GDP rows merged into the annual GDP-ISIC pages
  /// (measure `QGDP_CON`). These power the "By Quarter" tab only and must never
  /// enter the annual headline series or sector maps. Scoped by [isGdpIsic] so
  /// the genuinely-quarterly indicators (Quarterly GDP) are unaffected.
  bool _isQuarterlyMergeRow(DataPoint p) =>
      isGdpIsic &&
      (p.measure == 'QGDP_CUR_Q' || p.measure == 'QGDP_CON_Q' ||
          // On the ANNUAL GDP pages, the merged plain quarterly totals
          // (QGDP_CON) feed the By Quarter tab only — never the annual series.
          ((meta.id == 'gdp_current' || meta.id == 'gdp_constant') &&
              p.measure == 'QGDP_CON'));

  /// True for the annual sector aggregates merged into a Quarterly GDP page
  /// (measure `GDP_CUR`/`GDP_CON`). On those pages the QUARTERLY series is the
  /// headline, so these annual rows feed the breakdown (byLevel) only and stay
  /// out of the headline [uaeTotalSeries].
  bool _isQuarterlyPageAnnualRow(DataPoint p) =>
      (meta.id == 'gdp_quarterly_current' && p.measure == 'GDP_CUR') ||
      (meta.id == 'gdp_quarterly_constant' && p.measure == 'GDP_CON');

  /// Ranks how strongly a level code represents the "total" row, used to break
  /// ties in the national series. Canonical sentinels (`_T`, `_Z`, null) rank
  /// above ambiguous aggregate words (`TOTAL`, `ALL`), which in turn rank above
  /// single letters like `T` that collide with real category codes (ISIC `T`).
  static int _levelTotalRank(String? code) {
    if (code == null) return 3;
    final c = code.toUpperCase();
    if (c == '_T' || c == '_Z' || c == '_O') return 3;
    if (c == 'TOTAL' || c == 'ALL') return 2;
    if (c == 'T') return 1; // ambiguous: also ISIC "Households as Employers"
    return 0;
  }

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
      if (_isQuarterlyMergeRow(p)) continue; // GDP "By Quarter" rows only
      if (p.refArea != 'AE' && p.refArea != null) continue;
      if (!_isTotal(p.gender)) continue;
      if (_isTotal(p.level)) continue;
      // GDP-by-ISIC: `_TNO` (non-oil aggregate) and `NFC` (FISIM adjustment)
      // are not producing sectors — exclude them from the category breakdown.
      if (isGdpIsic && _gdpNonSectorCodes.contains((p.level ?? '').toUpperCase())) {
        continue;
      }
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
  /// Deduped to ONE row per year — the grand total — so the appended water-
  /// source split rows (SW/GW) never appear as extra yearly rows in the table.
  List<DataPoint> get _producedWaterTotalSeries {
    final byYear = <String, DataPoint>{};
    for (final p in allPoints) {
      if (!_isTotal(p.level)) continue;        // PWT_ENTITY = _T
      if (!_isTotal(p.citizenship)) continue;  // WATER_SOURCE = _T
      final existing = byYear[p.timePeriod];
      // Keep the largest value for the year (the grand total ≥ any component).
      if (existing == null || p.value > existing.value) {
        byYear[p.timePeriod] = p;
      }
    }
    final out = byYear.values.toList()
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
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

  // ─── Produced Water KPI helpers (computed from live data) ────────────────

  /// Peak production year (highest national total) + its MCM value.
  ({String year, double value})? get pwPeakYear {
    final s = uaeTotalSeries;
    if (s.isEmpty) return null;
    final peak = s.reduce((a, b) => b.value > a.value ? b : a);
    return (year: peak.timePeriod, value: peak.value);
  }

  /// Desalination share (%) — Sea Water source ÷ total of all sources.
  double? get pwDesalinationShare {
    final src = producedWaterBySource;
    if (src.isEmpty) return null;
    final total = src.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return null;
    String? seaKey;
    for (final k in src.keys) {
      final u = k.toUpperCase();
      if (u.contains('SEA') || u.contains('DESAL') || u == 'SW') seaKey = k;
    }
    seaKey ??= src.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    return src[seaKey]! / total * 100;
  }

  /// Top producing entity (code + % share of the latest-year total).
  ({String code, double share})? get pwTopProducer {
    final ent = producedWaterByEntity;
    if (ent.isEmpty) return null;
    final total = ent.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return null;
    final top = ent.entries.reduce((a, b) => b.value > a.value ? b : a);
    return (code: top.key, share: top.value / total * 100);
  }

  // ─── Energy & natural-reserve helpers ─────────────────────────────────────

  bool get isGenerationCapacity => meta.id == 'energy_generation_capacity';

  double? _gcScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return p.value;
    }
    return null;
  }

  // KPI cards: Solar PV capacity (MW), total RE output (GWh), Solar PV share %.
  double? get gcSolarPv => _gcScalar('GC_SOLAR_PV');
  double? get gcReOutput => _gcScalar('GC_RE_OUTPUT');
  double? get gcSolarShare => _gcScalar('GC_SOLAR_SHARE');

  /// Renewable capacity by type 2024 (label, MW), desc.
  List<({String label, double value})> get gcByCapacity =>
      _gcTypeList('GC_CAP_TYPE');

  /// Renewable production by type 2024 (label, GWh), desc.
  List<({String label, double value})> get gcByProduction =>
      _gcTypeList('GC_PROD_TYPE');

  List<({String label, double value})> _gcTypeList(String measure) {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Total renewable capacity trend per year (year, MW), newest first.
  List<({String year, double mw})> get gcReTrend {
    final out = <({String year, double mw})>[];
    for (final p in allPoints) {
      if (p.measure != 'GC_RE_TREND') continue;
      out.add((year: p.timePeriod, mw: p.value));
    }
    out.sort((a, b) => b.year.compareTo(a.year));
    return out;
  }
  bool get isCrudeOil => meta.id == 'energy_crude_oil';
  bool get isRenewableEnergy => meta.id == 'energy_renewable';
  bool get isNaturalReserves => meta.id == 'ecology_natural_reserves';

  /// Protected-areas scalar (value + optional note) by NR_* measure.
  ({double value, String? note})? _nrScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return (value: p.value, note: p.obsStatus);
    }
    return null;
  }

  ({double value, String? note})? get nrTerrestrial => _nrScalar('NR_TERRESTRIAL');
  ({double value, String? note})? get nrMarine => _nrScalar('NR_MARINE');
  ({double value, String? note})? get nrRamsar => _nrScalar('NR_RAMSAR');
  ({double value, String? note})? get nrOldest => _nrScalar('NR_OLDEST');

  /// Top individual reserve sites (label, km²), desc.
  List<({String label, double value})> get nrTopReserves {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != 'NR_SITE') continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }
  bool get isRamsarWetlands => meta.id == 'ecology_ramsar_wetlands';

  double? _rwScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return p.value;
    }
    return null;
  }

  double? get rwTotalSites => _rwScalar('RW_TOTAL');
  double? get rwMarineArea => _rwScalar('RW_MARINE');
  double? get rwTerrestrialArea => _rwScalar('RW_TERRESTRIAL');

  /// RAMSAR site counts by type (label, count), desc.
  List<({String label, double value})> get rwSiteCount {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != 'RW_SITECOUNT') continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

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
      if ((p.measure ?? '').startsWith('GC_')) continue; // gen-capacity extras
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

  // ─── Electricity Consumption helpers ──────────────────────────────────────

  bool get isElectricity => meta.id == 'electricity';

  double? _elecScalar(String measure) {
    for (final p in allPoints) {
      if (p.measure == measure) return p.value;
    }
    return null;
  }

  double? get elecCommercial => _elecScalar('ELEC_COMMERCIAL');
  double? get elecResidential => _elecScalar('ELEC_RESIDENTIAL');
  double? get elecAbuDhabiShare => _elecScalar('ELEC_AD_SHARE');

  /// 10-year growth of national consumption (first→last CONSUMPTION year), %.
  double? get elecGrowthSince {
    final s = uaeTotalSeries;
    if (s.length < 2 || s.first.value == 0) return null;
    return (s.last.value - s.first.value) / s.first.value * 100;
  }

  String? get elecGrowthFromYear =>
      uaeTotalSeries.isEmpty ? null : uaeTotalSeries.first.timePeriod;

  List<({String label, double value})> _elecTypeList(String measure) {
    final out = <({String label, double value})>[];
    for (final p in allPoints) {
      if (p.measure != measure) continue;
      out.add((label: p.categoryLabel ?? '', value: p.value));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  List<({String label, double value})> get elecByEmirate =>
      _elecTypeList('ELEC_EMIRATE');
  List<({String label, double value})> get elecBySector =>
      _elecTypeList('ELEC_SECTOR');
  List<({String label, double value})> get elecByConsumer =>
      _elecTypeList('ELEC_CONSUMER');

  // ─── Crop Statistics helpers ──────────────────────────────────────────────

  bool get isCropProduction => meta.id == 'crop_production';

  double? get cropFarmArea => _elecScalar('CROP_FARMAREA');
  double? get cropFarmValue => _elecScalar('CROP_FARMVALUE');
  double? get cropProducingEmirates => _elecScalar('CROP_EMIRATES');

  List<({String label, double value})> get cropByEmirate =>
      _elecTypeList('CROP_EMIRATE');
  List<({String label, double value})> get cropByType =>
      _elecTypeList('CROP_TYPE');
  List<({String label, double value})> get cropByArea =>
      _elecTypeList('CROP_BYAREA');

  // ─── Total Agricultural Land Use helpers ──────────────────────────────────

  bool get isCropLandTotal => meta.id == 'crop_land_total';

  double? get landAbuDhabiShare => _elecScalar('LAND_AD_SHARE');
  double? get landFruitTrees => _elecScalar('LAND_FRUIT');
  double? get landProductiveShare => _elecScalar('LAND_PROD_SHARE');

  /// Total agricultural-area growth (first→last LAND_TOTAL year), %.
  double? get landGrowthSince {
    final s = uaeTotalSeries;
    if (s.length < 2 || s.first.value == 0) return null;
    return (s.last.value - s.first.value) / s.first.value * 100;
  }

  String? get landGrowthFromYear =>
      uaeTotalSeries.isEmpty ? null : uaeTotalSeries.first.timePeriod;
  String? get landGrowthToYear =>
      uaeTotalSeries.isEmpty ? null : uaeTotalSeries.last.timePeriod;

  List<({String label, double value})> get landByEmirate =>
      _elecTypeList('LAND_EMIRATE');
  List<({String label, double value})> get landByUseType =>
      _elecTypeList('LAND_USE');
  List<({String label, double value})> get landByCover =>
      _elecTypeList('LAND_COVER');

  // ─── Cultivated Area helpers ──────────────────────────────────────────────

  bool get isCropArea => meta.id == 'crop_area';

  static const _cropEmirateNames = {
    'AE-AZ': 'Abu Dhabi',
    'AE-DU': 'Dubai',
    'AE-SH': 'Sharjah',
    'AE-AJ': 'Ajman',
    'AE-RK': 'Ras Al Khaimah',
    'AE-FJ': 'Fujairah',
    'AE-UQ': 'Umm Al Quwain',
  };

  /// Latest per-emirate cultivated area (label, value), largest first.
  List<({String label, double value})> get cropAreaByEmirate {
    final out = <({String label, double value})>[];
    final emirates = byEmirate;
    for (final entry in emirates.entries) {
      final series = entry.value;
      if (series.isEmpty) continue;
      final latest = series.reduce(
          (a, b) => b.timePeriod.compareTo(a.timePeriod) > 0 ? b : a);
      out.add((
        label: _cropEmirateNames[entry.key] ?? entry.key,
        value: latest.value,
      ));
    }
    out.sort((a, b) => b.value.compareTo(a.value));
    return out;
  }

  /// Per-emirate YoY growth (label, pct) for the latest two years, desc by pct.
  List<({String label, double pct})> get cropAreaEmirateGrowth {
    final out = <({String label, double pct})>[];
    for (final entry in byEmirate.entries) {
      final series = [...entry.value]
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (series.length < 2) continue;
      final prev = series[series.length - 2].value;
      final last = series.last.value;
      if (prev == 0) continue;
      out.add((
        label: _cropEmirateNames[entry.key] ?? entry.key,
        pct: (last - prev) / prev * 100,
      ));
    }
    out.sort((a, b) => b.pct.compareTo(a.pct));
    return out;
  }

  /// Average of the UAE total series (annual average).
  double? get averageValue {
    final s = uaeTotalSeries;
    if (s.isEmpty) return null;
    return s.map((p) => p.value).reduce((a, b) => a + b) / s.length;
  }

  /// Year-over-year growth of the headline series (last vs previous year), %.
  double? get yoyGrowth {
    final s = uaeTotalSeries;
    if (s.length < 2 || s[s.length - 2].value == 0) return null;
    return (s.last.value - s[s.length - 2].value) /
        s[s.length - 2].value *
        100;
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
    // RAMSAR: headline is the designated wetland AREA (km²), supplied as the
    // RAMSAR_AREA measure — never the site-count or the unreliable live total.
    if (isRamsarWetlands) {
      final area = allPoints
          .where((p) => p.measure == 'RAMSAR_AREA')
          .toList()
        ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
      if (area.isNotEmpty) return area;
    }
    final out = <DataPoint>[];
    for (final p in allPoints) {
      if (_isReserveExtraRow(p)) continue;      // NR_* cards/sites only
      if (p.measure == 'RAMSAR_AREA') continue; // handled above
      if (p.refArea != 'AE') continue;          // national total only
      if (!_isTotal(p.level)) continue;         // NR_TYPE = _T
      if (!_isTotal(p.ageGroup)) continue;      // EST_YEAR = _T
      out.add(p);
    }
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// True for the synthesized Protected-Areas card/site rows (measure NR_*),
  /// which must feed the cards/Top-Reserves tab only — never the headline or
  /// the By Type / By Emirate maps.
  static bool _isReserveExtraRow(DataPoint p) {
    final m = p.measure ?? '';
    return m.startsWith('NR_') || m.startsWith('RW_');
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

  /// Latest female head-count (value + period) from the female total series.
  ({double value, String period})? get livestockFemaleLatest {
    final s = livestockGenderSeries('F');
    if (s.isEmpty) return null;
    return (value: s.last.value, period: s.last.timePeriod);
  }

  /// Latest milch-female head-count (sum of *_MIL female classes) + period.
  ({double value, String period})? get livestockMilchLatest {
    final detail = livestockFemaleDetail;
    if (detail.isEmpty) return null;
    double sum = 0;
    var found = false;
    for (final e in detail.entries) {
      if (e.key.toUpperCase().endsWith('_MIL')) {
        sum += e.value;
        found = true;
      }
    }
    if (!found) return null;
    return (value: sum, period: latestPeriod);
  }

  /// Abu Dhabi share of the national head-count total for the latest year (%).
  double? get livestockAbuDhabiShare {
    final national = uaeTotalSeries;
    if (national.isEmpty) return null;
    final latest = national.last.timePeriod;
    final nationalVal = national.last.value;
    if (nationalVal <= 0) return null;
    final ad = byEmirate['AE-AZ'];
    if (ad == null || ad.isEmpty) return null;
    final adLatest = ad.where((p) => p.timePeriod == latest).toList();
    if (adLatest.isEmpty) return null;
    return adLatest.first.value / nationalVal * 100;
  }

  /// Total head-count growth (first→last UAE total year), %.
  double? get livestockGrowthSince {
    final s = uaeTotalSeries;
    if (s.length < 2 || s.first.value == 0) return null;
    return (s.last.value - s.first.value) / s.first.value * 100;
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
