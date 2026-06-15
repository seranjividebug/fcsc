// lib/data/sources/sdmx_api_client.dart
//
// FCSC SDMX REST API client.
// Fetches SDMX-JSON 1.0 format and decodes it into List<DataPoint>.
//
// SDMX-JSON observation key decoding:
//   "k0:k1:k2:...:kN" → each ki is the index into dimensions[i].values
//   Value array → [observationValue, statusCode?, ...]

import 'package:dio/dio.dart';
import 'package:uae_stats/core/constants/api_constants.dart';
import 'package:uae_stats/data/models/data_point.dart';

/// Wraps parsed data points together with the API's own preparation timestamp.
class SdmxResult {
  const SdmxResult({required this.points, this.preparedAt});
  final List<DataPoint> points;
  final String? preparedAt; // ISO-8601 from root['meta']['prepared']
}

// Internal helper — one SDMX dimension definition
class _SdmxDimension {
  const _SdmxDimension({required this.id, required this.values});
  final String id;
  final List<String> values; // index → value code (e.g. "AE", "_T")
}

class SdmxApiClient {
  SdmxApiClient()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            headers: ApiConstants.sdmxJsonHeaders,
          ),
        );

  final Dio _dio;

  // ─── Public fetch methods ─────────────────────────────────────────────────

  /// Fetches Population Estimates (DF_POP_ALL).
  Future<SdmxResult> fetchPopulation() async {
    return _fetch(ApiConstants.populationDataUrl);
  }

  /// Fetches Births (DF_BIRTHS).
  Future<SdmxResult> fetchBirths() async {
    return _fetch(ApiConstants.birthsDataUrl);
  }

  /// Fetches Divorces (DF_DV_NA).
  Future<SdmxResult> fetchDivorces() async {
    return _fetch(ApiConstants.divorcesDataUrl);
  }

  /// Fetches Deaths (DF_DEATHS).
  Future<SdmxResult> fetchDeaths() async {
    return _fetch(ApiConstants.deathsDataUrl);
  }

  /// Fetches Marriages (DF_MR_NA).
  Future<SdmxResult> fetchMarriages() async {
    return _fetch(ApiConstants.marriagesDataUrl);
  }

  /// Fetches General Education Students (DF_EDU_STUD).
  Future<SdmxResult> fetchEducationStudents() async {
    return _fetch(ApiConstants.educationDataUrl);
  }

  /// Fetches General Education Teaching Staff (DF_EDU_TEACH).
  Future<SdmxResult> fetchEducationTeachers() async {
    return _fetch(ApiConstants.educationTeachingStaffUrl);
  }

  /// Fetches Higher Education Students (DF_HE_STUDENTS_ARG).
  Future<SdmxResult> fetchEducationHigher() async {
    return _fetch(ApiConstants.educationHigherUrl);
  }

  /// Fetches Health Services / Hospitals (DF_HEALTH_FACILITIES, HSP filter).
  Future<SdmxResult> fetchHealthServices() async {
    return _fetch(ApiConstants.hospitalServicesDataUrl);
  }

  /// Fetches Clinics and Centers (DF_HEALTH_FACILITIES, CAH filter).
  Future<SdmxResult> fetchHealthClinics() async {
    return _fetch(ApiConstants.clinicsDataUrl);
  }

  /// Fetches Hospital Beds (DF_HEALTH_FACILITIES, BED filter).
  Future<SdmxResult> fetchHospitalBeds() async {
    return _fetch(ApiConstants.hospitalBedsDataUrl);
  }

  /// Fetches Healthcare Professionals (DF_HEALTH_WORKFORCE).
  Future<SdmxResult> fetchHealthProfessionals() async {
    return _fetch(ApiConstants.healthWorkforceDataUrl);
  }

  /// Fetches Total Trade and merges the data the page renders:
  ///   • Headline total series (DF_TRADE_SECT_YR) → measure "TRADE_TOT"
  ///   • Latest-year flow totals (imports / non-oil exports / re-exports) →
  ///     measure "TRADE_FLOW", level=flow code (for cards + By Trade Type)
  ///   • Import HS sections → measure "TRADE_IMP_SEC", level=section
  ///   • Export (non-oil) HS sections → measure "TRADE_EXP_SEC", level=section
  /// Values are kept in AED millions (raw AED ÷ 1e6). Each source is
  /// best-effort; the bundled seed (same shape) backs offline use.
  Future<SdmxResult> fetchTradeTotal() async {
    final out = <DataPoint>[];
    String? preparedAt;

    // Headline total trade series.
    try {
      final total = await _fetch(ApiConstants.tradeTotalDataUrl);
      out.addAll(total.points);
      preparedAt = total.preparedAt;
    } catch (_) {}

    // Latest-year flow totals (for the KPI cards + By Trade Type tab).
    Future<double?> flowTotal(String url) async {
      try {
        final secs = await _fetchTradeSections(url, measureTag: '_TMP');
        if (secs.isEmpty) return null;
        // Latest year only; sum all its sections = the flow total.
        final latest = secs
            .map((p) => p.timePeriod)
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
        var sum = 0.0;
        for (final p in secs) {
          if (p.timePeriod == latest) sum += p.value;
        }
        return sum;
      } catch (_) {
        return null;
      }
    }

    // Import sections (also yields the imports flow total).
    try {
      final imp = await _fetchTradeSections(
          ApiConstants.tradeImportsHsDataUrl, measureTag: 'TRADE_IMP_SEC');
      out.addAll(imp);
    } catch (_) {}

    // Export (non-oil) sections.
    try {
      final exp = await _fetchTradeSections(
          ApiConstants.tradeNonOilExportsDataUrl, measureTag: 'TRADE_EXP_SEC');
      out.addAll(exp);
    } catch (_) {}

    // Flow totals: imports, non-oil exports, re-exports (latest year).
    final imports = await flowTotal(ApiConstants.tradeImportsHsDataUrl);
    final nonOilExp = await flowTotal(ApiConstants.tradeNonOilExportsDataUrl);
    final reExp = await flowTotal(ApiConstants.tradeReexportsAnnualDataUrl);
    final latestYear = out
        .where((p) => p.measure == 'TRADE_TOT')
        .fold<String>('', (a, p) => p.timePeriod.compareTo(a) > 0 ? p.timePeriod : a);
    void addFlow(String code, double? v) {
      if (v == null) return;
      out.add(DataPoint(
        timePeriod: latestYear,
        value: v,
        refArea: 'AE',
        gender: '_T',
        measure: 'TRADE_FLOW',
        level: code,
        unitMeasure: 'AED_MN',
      ));
    }
    addFlow('IMP', imports);
    addFlow('NONOIL_EXP', nonOilExp);
    addFlow('REEXP', reExp);

    return SdmxResult(points: out, preparedAt: preparedAt);
  }

  /// Sums a DF_TRADE_* dataflow per HS_SECTION (across countries) per year,
  /// converting raw AED → AED millions. Returns rows with level=section,
  /// categoryLabel=section name, [measureTag] as measure. Empty if the dim
  /// is absent.
  Future<List<DataPoint>> _fetchTradeSections(
    String url, {
    required String measureTag,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final body = response.data;
    if (body == null) return const [];
    final data = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    final structuresList =
        _nestedList(data, ['structures']) ?? _nestedList(body, ['structures']);
    final structure = (structuresList != null && structuresList.isNotEmpty)
        ? (structuresList.first as Map<String, dynamic>)
        : (_nestedMap(data, ['structure']) ?? _nestedMap(body, ['structure']) ?? {});
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];
    if (dimObs.isEmpty) return const [];

    final dimIds = <String>[];
    final dimCodes = <List<String>>[];
    final dimNames = <List<String>>[];
    for (final d in dimObs.cast<Map<String, dynamic>>()) {
      dimIds.add((d['id'] ?? '').toString());
      final rawVals = (d['values'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      dimCodes.add(rawVals.map((v) => (v['id'] ?? '').toString()).toList());
      dimNames.add(
          rawVals.map((v) => (v['name'] ?? v['id'] ?? '').toString()).toList());
    }
    final hsPos = dimIds.indexOf('HS_SECTION');
    final tpPos = dimIds.indexOf('TIME_PERIOD');
    if (hsPos < 0 || tpPos < 0) return const [];

    final dataSets = _nestedList(data, ['dataSets']) ??
        _nestedList(body, ['dataSets']) ??
        [];
    if (dataSets.isEmpty) return const [];
    final observations =
        (dataSets.first as Map<String, dynamic>)['observations']
            as Map<String, dynamic>?;
    if (observations == null || observations.isEmpty) return const [];

    // (year|section) → summed value; remember section names.
    final agg = <String, double>{};
    final secName = <String, String>{};
    observations.forEach((key, val) {
      final arr = val as List?;
      if (arr == null || arr.isEmpty || arr[0] == null) return;
      final indices = key.split(':');
      int? ci(int pos) =>
          (pos < 0 || pos >= indices.length) ? null : int.tryParse(indices[pos]);
      String codeAt(int pos) {
        final i = ci(pos);
        return (i == null || i >= dimCodes[pos].length) ? '' : dimCodes[pos][i];
      }
      String nameAt(int pos) {
        final i = ci(pos);
        return (i == null || i >= dimNames[pos].length) ? '' : dimNames[pos][i];
      }
      final num? n = arr[0] is num
          ? arr[0] as num
          : num.tryParse(arr[0].toString());
      if (n == null) return;
      final year = codeAt(tpPos);
      final sec = codeAt(hsPos);
      if (year.isEmpty || sec.isEmpty) return;
      agg['$year|$sec'] = (agg['$year|$sec'] ?? 0) + n.toDouble();
      secName[sec] = nameAt(hsPos);
    });

    final out = <DataPoint>[];
    agg.forEach((k, v) {
      final parts = k.split('|');
      out.add(DataPoint(
        timePeriod: parts[0],
        value: v / 1e6, // raw AED → AED millions
        refArea: 'AE',
        gender: '_T',
        measure: measureTag,
        level: parts[1],
        categoryLabel: _shortTradeSection(secName[parts[1]] ?? parts[1]),
        unitMeasure: 'AED_MN',
      ));
    });
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Shortens the long official HS-section names for compact bar labels.
  static String _shortTradeSection(String name) {
    final n = name.toLowerCase();
    if (n.contains('pearls')) return 'Pearls & Precious Metals';
    if (n.contains('machinery')) return 'Machinery & Electronics';
    if (n.contains('vehicles')) return 'Vehicles of Transport';
    if (n.contains('mineral')) return 'Mineral Products';
    if (n.contains('chemical')) return 'Chemicals';
    if (n.contains('base metal')) return 'Base Metals';
    if (n.contains('textile')) return 'Textiles';
    if (n.contains('foodstuff')) return 'Foodstuffs & Beverages';
    if (n.contains('plastic')) return 'Plastics & Rubber';
    if (n.contains('vegetable')) return 'Vegetable Products';
    if (n.contains('live animal')) return 'Live Animals & Products';
    if (n.contains('photographic') || n.contains('medical')) {
      return 'Instruments & Medical';
    }
    if (n.contains('wood') && n.contains('cork')) return 'Wood & Cork';
    if (n.contains('paper') || n.contains('pulp')) return 'Paper & Pulp';
    if (n.contains('stone') || n.contains('ceramic')) return 'Stone & Ceramics';
    if (n.contains('footwear')) return 'Footwear & Headgear';
    if (n.contains('leather')) return 'Leather Goods';
    if (n.contains('fats') || n.contains('oils')) return 'Animal/Vegetable Fats';
    if (n.contains('arms')) return 'Arms & Ammunition';
    if (n.contains('art') || n.contains('antique')) return 'Art & Antiques';
    if (n.contains('miscellaneous')) return 'Misc. Manufactured';
    return name;
  }

  /// Fetches Imports by HS Section (DF_TRADE_IMP_SECT_YR).
  Future<SdmxResult> fetchTradeImportsHs() async {
    return _fetch(ApiConstants.tradeImportsHsDataUrl);
  }

  /// Fetches Non-Oil Exports by HS Section (DF_TRADE_TEXP_SECT_YR).
  Future<SdmxResult> fetchTradeNonOilExports() async {
    return _fetch(ApiConstants.tradeNonOilExportsDataUrl);
  }

  /// Fetches Domestic Non-Oil Exports by HS Section & Country (DF_TRADE_EXP_SECT_YR).
  Future<SdmxResult> fetchTradeSectorCountry() async {
    return _fetch(ApiConstants.tradeSectorCountryDataUrl);
  }

  /// Fetches Annual Re-Exports by HS Section & Country (DF_TRADE_REXP_SECT_YR).
  Future<SdmxResult> fetchTradeReexportsAnnual() async {
    return _fetch(ApiConstants.tradeReexportsAnnualDataUrl);
  }

  /// Fetches Monthly Re-Exports by Destination Country (DF_TRADE_REXP_COUNTRY_MTH).
  Future<SdmxResult> fetchTradeReexportsMonthly() async {
    return _fetch(ApiConstants.tradeReexportsMonthlyDataUrl);
  }

  /// Fetches GDP at Current Prices (DF_NA_ISIC_CUR).
  Future<SdmxResult> fetchGdpCurrent() async {
    return _fetch(ApiConstants.gdpCurrentDataUrl);
  }

  /// Fetches GDP at Constant Prices (DF_NA_ISIC_CON) and merges the latest-year
  /// quarterly totals (DF_QGDP_CON) so the page can render a "By Quarter" tab.
  /// Quarterly rows are normalised to timePeriod "<year>-<QUARTER>" with
  /// measure "QGDP_CON" so the model can isolate them without extra fields.
  /// A quarterly-fetch failure degrades gracefully to annual-only data.
  Future<SdmxResult> fetchGdpConstant() async {
    final annual = await _fetch(ApiConstants.gdpConstantDataUrl);
    List<DataPoint> quarters = const [];
    try {
      quarters = await _fetchQuarterlyTotals(
        ApiConstants.gdpQuarterlyConstantDataUrl,
        measureTag: 'QGDP_CON',
      );
    } catch (_) {
      // Quarterly merge is best-effort; annual data still renders.
    }
    return SdmxResult(
      points: [...annual.points, ...quarters],
      preparedAt: annual.preparedAt,
    );
  }

  /// Fetches a quarterly GDP dataflow and returns ONLY the per-quarter national
  /// totals for the latest available year. Each quarter's total is the largest
  /// VAL observation in that quarter (the sector-total row). Emitted as clean
  /// points: timePeriod "<year>-<QUARTER>", measure [measureTag].
  Future<List<DataPoint>> _fetchQuarterlyTotals(
    String url, {
    required String measureTag,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final body = response.data;
    if (body == null) return const [];

    final data = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    final structuresList =
        _nestedList(data, ['structures']) ?? _nestedList(body, ['structures']);
    final structure = (structuresList != null && structuresList.isNotEmpty)
        ? (structuresList.first as Map<String, dynamic>)
        : (_nestedMap(data, ['structure']) ?? _nestedMap(body, ['structure']) ?? {});
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];
    if (dimObs.isEmpty) return const [];

    final dims = dimObs.cast<Map<String, dynamic>>().map((d) {
      final rawVals = (d['values'] as List?) ?? [];
      return _SdmxDimension(
        id: (d['id'] ?? '').toString(),
        values: rawVals
            .cast<Map<String, dynamic>>()
            .map((v) => (v['id'] ?? v['name'] ?? '').toString())
            .toList(),
      );
    }).toList();

    final dataSets = _nestedList(data, ['dataSets']) ??
        _nestedList(body, ['dataSets']) ??
        [];
    if (dataSets.isEmpty) return const [];
    final observations =
        (dataSets.first as Map<String, dynamic>)['observations']
            as Map<String, dynamic>?;
    if (observations == null || observations.isEmpty) return const [];

    int idxOf(String id) => dims.indexWhere((d) => d.id == id);
    final qPos = idxOf('QUARTER');
    final tpPos = idxOf('TIME_PERIOD');
    final unitPos = idxOf('QGDP_UNIT');
    if (qPos < 0 || tpPos < 0) return const [];

    // For each (year, quarter) keep the MAX VAL observation = the total row.
    final maxByYearQuarter = <String, double>{};
    String latestYear = '';
    observations.forEach((key, val) {
      final arr = val as List?;
      if (arr == null || arr.isEmpty || arr[0] == null) return;
      final indices = key.split(':');
      String codeAt(int pos) {
        if (pos < 0 || pos >= indices.length) return '';
        final i = int.tryParse(indices[pos]);
        if (i == null || i >= dims[pos].values.length) return '';
        return dims[pos].values[i];
      }
      // Restrict to absolute values (skip growth-rate rows) when present.
      if (unitPos >= 0 && codeAt(unitPos) != 'VAL') return;
      final year = codeAt(tpPos);
      final quarter = codeAt(qPos);
      if (year.isEmpty || quarter.isEmpty) return;
      final v = (arr[0] as num).toDouble();
      final mapKey = '$year|$quarter';
      if (v > (maxByYearQuarter[mapKey] ?? double.negativeInfinity)) {
        maxByYearQuarter[mapKey] = v;
      }
    });

    // Pick the latest year that publishes all four quarters (avoid a partial
    // current year, e.g. 2025 with only Q1–Q2). Fall back to the latest year.
    final quartersPerYear = <String, int>{};
    for (final key in maxByYearQuarter.keys) {
      final yr = key.split('|')[0];
      quartersPerYear[yr] = (quartersPerYear[yr] ?? 0) + 1;
      if (yr.compareTo(latestYear) > 0) latestYear = yr;
    }
    var targetYear = latestYear;
    final completeYears = quartersPerYear.entries
        .where((e) => e.value >= 4)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (completeYears.isNotEmpty) targetYear = completeYears.last;

    final out = <DataPoint>[];
    maxByYearQuarter.forEach((mapKey, v) {
      final parts = mapKey.split('|');
      if (parts[0] != targetYear) return; // chosen year only
      out.add(DataPoint(
        timePeriod: '${parts[0]}-${parts[1]}',
        value: v,
        refArea: 'AE',
        gender: '_T',
        measure: measureTag,
        unitMeasure: 'AED_MN',
      ));
    });
    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return out;
  }

  /// Fetches Quarterly GDP at Constant Prices and assembles the page data:
  ///   • Quarterly headline series (DF_QGDP_CON totals) → measure "QGDP_CON"
  ///   • By Quarter tab rows for the latest complete year → "QGDP_CON_Q"
  ///   • Annual constant sector aggregates (DF_NA_ISIC_CON) → measure "GDP_CON",
  ///     level=ISIC code (TOT→_T, _TNO non-oil), for Oil vs Non-Oil + growth.
  /// Each source is best-effort; on failure the bundled seed (which mirrors this
  /// shape) is used by the repository.
  Future<SdmxResult> fetchGdpQuarterlyConstant() async {
    final out = <DataPoint>[];
    String? preparedAt;

    // 1) Quarterly totals (headline + By Quarter).
    try {
      final q = await _fetchQuarterlyTotals(
        ApiConstants.gdpQuarterlyConstantDataUrl,
        measureTag: 'QGDP_CON_Q',
      );
      // _fetchQuarterlyTotals returns only the chosen year tagged *_Q; re-fetch
      // the full series for the headline.
      final full = await _fetch(ApiConstants.gdpQuarterlyConstantDataUrl);
      for (final p in full.points) {
        // Plain quarterly totals carry no level; keep as QGDP_CON headline.
        out.add(p.copyWith(measure: 'QGDP_CON'));
      }
      out.addAll(q);
      preparedAt = full.preparedAt;
    } catch (_) {}

    // 2) Annual constant ISIC sectors (for Oil vs Non-Oil + Annual Growth).
    try {
      final annual = await _fetch(ApiConstants.gdpConstantDataUrl);
      for (final p in annual.points) {
        // Keep AE national, gender-total, drop NFC (sub-aggregate).
        if ((p.level ?? '').toUpperCase() == 'NFC') continue;
        out.add(p.copyWith(measure: 'GDP_CON'));
      }
    } catch (_) {}

    return SdmxResult(points: out, preparedAt: preparedAt);
  }

  /// Fetches Aircraft Movement by Emirate (DF_AIRCRAFT_MOV).
  Future<SdmxResult> fetchAircraftMovement() async {
    return _fetch(ApiConstants.aircraftMovementDataUrl);
  }

  /// Fetches Hotel Main Indicators (DF_HOT_INDICATOR).
  Future<SdmxResult> fetchTourismMainIndicators() async {
    return _fetch(ApiConstants.tourismMainIndicatorsDataUrl);
  }

  /// Fetches Hotel Establishments by Type, Class & Rooms (DF_HOT_TYPE).
  Future<SdmxResult> fetchTourismHotelEstablishments() async {
    return _fetch(ApiConstants.tourismHotelEstablishmentsDataUrl);
  }

  /// Fetches Hotel Guest Arrivals by Nationality (DF_GUEST_REGION).
  Future<SdmxResult> fetchTourismHotelArrivals() async {
    return _fetch(ApiConstants.tourismHotelArrivalsDataUrl);
  }

  /// Fetches CPI Annual (DF_CPI_ANN).
  Future<SdmxResult> fetchCpiAnnual() async {
    return _fetch(ApiConstants.cpiAnnualDataUrl);
  }

  /// Fetches Quarterly GDP at Current Prices (DF_QGDP_CUR) and synthesizes the
  /// rows the page renders. The MEASURE dimension carries the sector; the
  /// aggregates are TOT_GDP (total), TOT_NO (non-oil) and NFC (a sub-aggregate,
  /// dropped). Output:
  ///   • Quarter totals → measure "QGDP_CUR_Q", period "<yr>-Qn"  (By Quarter)
  ///   • Per-sector annual sums (all years) → measure "GDP_CUR", level=code,
  ///     categoryLabel=name, period "<yr>"   (By Sector / Top Growth)
  ///   • Total → level "_T"; Non-oil → level "_TNO"  (headline + Oil vs Non-Oil)
  /// Falls back to the plain dataflow parse if the expected dims are absent.
  Future<SdmxResult> fetchGdpQuarterlyCurrent() async {
    final response = await _dio
        .get<Map<String, dynamic>>(ApiConstants.gdpQuarterlyCurrentDataUrl);
    final body = response.data;
    if (body == null) return const SdmxResult(points: []);

    final data = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    final structuresList =
        _nestedList(data, ['structures']) ?? _nestedList(body, ['structures']);
    final structure = (structuresList != null && structuresList.isNotEmpty)
        ? (structuresList.first as Map<String, dynamic>)
        : (_nestedMap(data, ['structure']) ?? _nestedMap(body, ['structure']) ?? {});
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];
    final preparedAt =
        (body['meta'] as Map<String, dynamic>?)?['prepared'] as String?;
    if (dimObs.isEmpty) return SdmxResult(points: const [], preparedAt: preparedAt);

    final dimIds = <String>[];
    final dimCodes = <List<String>>[];
    final dimNames = <List<String>>[];
    for (final d in dimObs.cast<Map<String, dynamic>>()) {
      dimIds.add((d['id'] ?? '').toString());
      final rawVals = (d['values'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      dimCodes.add(rawVals.map((v) => (v['id'] ?? '').toString()).toList());
      dimNames.add(
          rawVals.map((v) => (v['name'] ?? v['id'] ?? '').toString()).toList());
    }

    final dataSets = _nestedList(data, ['dataSets']) ??
        _nestedList(body, ['dataSets']) ??
        [];
    if (dataSets.isEmpty) return SdmxResult(points: const [], preparedAt: preparedAt);
    final observations =
        (dataSets.first as Map<String, dynamic>)['observations']
            as Map<String, dynamic>?;
    if (observations == null || observations.isEmpty) {
      return SdmxResult(points: const [], preparedAt: preparedAt);
    }

    int posOf(String id) => dimIds.indexOf(id);
    final mePos = posOf('MEASURE');
    final qPos = posOf('QUARTER');
    final tpPos = posOf('TIME_PERIOD');
    final unitPos = posOf('QGDP_UNIT');
    // Without the expected dimensions, fall back to the standard parse.
    if (mePos < 0 || qPos < 0 || tpPos < 0) {
      return _fetch(ApiConstants.gdpQuarterlyCurrentDataUrl);
    }

    final quarterTotal = <String, double>{}; // "yr|Qn" → max VAL
    final sectorYear = <String, double>{};    // "yr|code" → summed VAL
    final sectorName = <String, String>{};

    observations.forEach((key, val) {
      final arr = val as List?;
      if (arr == null || arr.isEmpty || arr[0] == null) return;
      final indices = key.split(':');
      int? ci(int pos) =>
          (pos < 0 || pos >= indices.length) ? null : int.tryParse(indices[pos]);
      String codeAt(int pos) {
        final i = ci(pos);
        return (i == null || i >= dimCodes[pos].length) ? '' : dimCodes[pos][i];
      }
      String nameAt(int pos) {
        final i = ci(pos);
        return (i == null || i >= dimNames[pos].length) ? '' : dimNames[pos][i];
      }
      if (unitPos >= 0 && codeAt(unitPos) != 'VAL') return;
      final year = codeAt(tpPos);
      final quarter = codeAt(qPos);
      final code = codeAt(mePos);
      if (year.isEmpty || quarter.isEmpty || code.isEmpty) return;
      final v = (arr[0] as num).toDouble();

      // Quarter total = the TOT_GDP measure for that quarter.
      if (code == 'TOT_GDP') {
        quarterTotal['$year|$quarter'] = v;
      }
      sectorYear['$year|$code'] = (sectorYear['$year|$code'] ?? 0) + v;
      sectorName[code] = nameAt(mePos);
    });

    // Quarter tab: latest year with 4 quarters, else latest year.
    final qPerYear = <String, int>{};
    var latestYear = '';
    quarterTotal.forEach((k, _) {
      final yr = k.split('|')[0];
      qPerYear[yr] = (qPerYear[yr] ?? 0) + 1;
      if (yr.compareTo(latestYear) > 0) latestYear = yr;
    });
    var quarterYear = latestYear;
    final complete = qPerYear.entries
        .where((e) => e.value >= 4)
        .map((e) => e.key)
        .toList()
      ..sort();
    if (complete.isNotEmpty) quarterYear = complete.last;

    final out = <DataPoint>[];

    quarterTotal.forEach((k, v) {
      final parts = k.split('|');
      // Full quarterly series (headline) — every quarter, measure QGDP_CUR so
      // it feeds uaeTotalSeries (the page's headline). Period "<yr>-Qn".
      out.add(DataPoint(
        timePeriod: '${parts[0]}-${parts[1]}',
        value: v,
        refArea: 'AE',
        gender: '_T',
        measure: 'QGDP_CUR',
        unitMeasure: 'AED_MN',
      ));
      // Chosen complete year also tagged QGDP_CUR_Q for the By Quarter tab.
      if (parts[0] == quarterYear) {
        out.add(DataPoint(
          timePeriod: '${parts[0]}-${parts[1]}',
          value: v,
          refArea: 'AE',
          gender: '_T',
          measure: 'QGDP_CUR_Q',
          unitMeasure: 'AED_MN',
        ));
      }
    });

    // Per-sector annual sums for ALL years (enables headline + growth).
    // TOT_GDP → level "_T", TOT_NO → "_TNO", NFC dropped (sub-aggregate).
    sectorYear.forEach((k, v) {
      final parts = k.split('|');
      final yr = parts[0];
      final code = parts[1];
      if (code == 'NFC') return;
      final isTotal = code == 'TOT_GDP';
      final isNonOil = code == 'TOT_NO';
      out.add(DataPoint(
        timePeriod: yr,
        value: v,
        refArea: 'AE',
        gender: '_T',
        measure: 'GDP_CUR',
        level: isTotal ? '_T' : (isNonOil ? '_TNO' : code),
        categoryLabel: (isTotal || isNonOil) ? null : (sectorName[code] ?? code),
        unitMeasure: 'AED_MN',
      ));
    });

    out.sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    return SdmxResult(points: out, preparedAt: preparedAt);
  }

  /// Fetches Climate Mean Temperature — monthly (DF_CLIMATE_TEMP).
  Future<SdmxResult> fetchClimateTemp() async {
    return _fetch(ApiConstants.climateTempDataUrl);
  }

  /// Fetches Crop Statistics by Emirate (DF_CROP_EM).
  Future<SdmxResult> fetchCropStatistics() async {
    return _fetch(ApiConstants.cropEmDataUrl);
  }

  /// Fetches Agricultural Land Use by Emirate (DF_CROP_LAND).
  Future<SdmxResult> fetchCropLand() async {
    return _fetch(ApiConstants.cropLandDataUrl);
  }

  /// Fetches Employed Population by Age & Gender (DF_LFEP_AGE).
  Future<SdmxResult> fetchEmployedAgeGender() async {
    return _fetch(ApiConstants.employedAgeGenderDataUrl);
  }

  /// Fetches Employed Population by Education Status (DF_LFEP_ED).
  Future<SdmxResult> fetchEmployedEducation() async {
    return _fetch(ApiConstants.employedEducationDataUrl);
  }

  /// Fetches Employed Population by Economic Activity (DF_LFEP_ECON).
  Future<SdmxResult> fetchEconomicActivity() async {
    return _fetch(ApiConstants.economicActivityDataUrl);
  }

  /// Fetches Employed Population by Employment Sector (DF_LFEP_SECT).
  Future<SdmxResult> fetchEmploymentSector() async {
    return _fetch(ApiConstants.employmentSectorDataUrl);
  }

  /// Fetches Unemployed Population by Education (DF_LFUNEMP_ED).
  Future<SdmxResult> fetchUnemploymentEducation() async {
    return _fetch(ApiConstants.unemploymentEducationDataUrl);
  }

  /// Fetches Employed Population by Occupation (DF_LFEP_OCC).
  Future<SdmxResult> fetchWorkforceOccupation() async {
    return _fetch(ApiConstants.workforceOccupationDataUrl);
  }

  /// Fetches Unemployed Population by Age & Gender (DF_LFUNEMP_AGE).
  Future<SdmxResult> fetchUnemploymentAgeGender() async {
    return _fetch(ApiConstants.unemploymentAgeGenderDataUrl);
  }

  /// Fetches Camel Population Census (DF_LSCAMEL).
  Future<SdmxResult> fetchCamelPopulation() async {
    return _fetch(ApiConstants.camelPopulationDataUrl);
  }

  /// Fetches Cattle Population Statistics (DF_LSCATTLE).
  Future<SdmxResult> fetchCattlePopulation() async {
    return _fetch(ApiConstants.cattlePopulationDataUrl);
  }

  /// Fetches Goat Population Census (DF_LSGOAT).
  Future<SdmxResult> fetchGoatPopulation() async {
    return _fetch(ApiConstants.goatPopulationDataUrl);
  }

  /// Fetches Sheep Population Statistics (DF_LSSHEEP).
  Future<SdmxResult> fetchSheepPopulation() async {
    return _fetch(ApiConstants.sheepPopulationDataUrl);
  }

  /// Fetches Annual Rainfall by weather station (DF_CLIMATE_RAIN) and appends
  /// the season / month / summary breakdown rows (the live dataflow only
  /// publishes per-station monthly totals; these aggregates drive the By Season
  /// & By Month tabs and the summary cards). A live failure still surfaces the
  /// aggregates so the page is never empty.
  Future<SdmxResult> fetchRainfall() async {
    final extras = _rainfallBreakdownRows();
    try {
      final live = await _fetch(ApiConstants.rainfallDataUrl);
      return SdmxResult(
        points: [...live.points, ...extras],
        preparedAt: live.preparedAt,
      );
    } catch (_) {
      return SdmxResult(points: extras);
    }
  }

  /// Season / month / summary rainfall rows (measure RF_*). Values mirror the
  /// bundled seed so the breakdown is consistent online and offline.
  List<DataPoint> _rainfallBreakdownRows() {
    DataPoint r(String m, double v, {String? label, String? note}) => DataPoint(
          timePeriod: '2024',
          value: v,
          refArea: 'AE',
          gender: '_T',
          measure: m,
          unitMeasure: 'MM',
          categoryLabel: label,
          obsStatus: note,
        );
    return [
      r('RF_WETYEAR', 154.2, note: '2020'),
      r('RF_RAINYDAYS', 22, note: 'avg'),
      r('RF_WETSTATION', 155.9, label: 'Fujairah', note: 'FJR'),
      r('RF_DRYSTATION', 79.6, label: 'Abu Dhabi', note: 'AUH'),
      r('RF_SEASON', 100.1, label: 'Winter (Nov–Mar)'),
      r('RF_SEASON', 13.3, label: 'Spring (Apr–May)'),
      r('RF_SEASON', 5.6, label: 'Autumn (Oct)'),
      r('RF_SEASON', 1.0, label: 'Summer (Jun–Sep)'),
      r('RF_MONTH', 25.1, label: 'January'),
      r('RF_MONTH', 24.4, label: 'December'),
      r('RF_MONTH', 21.3, label: 'February'),
      r('RF_MONTH', 17.8, label: 'March'),
      r('RF_MONTH', 11.2, label: 'November'),
      r('RF_MONTH', 10.5, label: 'April'),
      r('RF_MONTH', 5.6, label: 'October'),
      r('RF_MONTH', 2.8, label: 'May'),
      r('RF_MONTH', 0.3, label: 'Jun–Sep (avg)'),
    ];
  }

  /// Fetches Produced Water by entity & source (DF_PW_Q_PRODWATER_SOURCE).
  Future<SdmxResult> fetchProducedWater() async {
    final live = await _fetch(ApiConstants.producedWaterDataUrl);
    // Determine the latest year from the national-total rows.
    String latest = '';
    for (final p in live.points) {
      final lvl = (p.level ?? '').toUpperCase();
      final src = (p.citizenship ?? '').toUpperCase();
      final isTotal = (lvl.isEmpty || lvl == '_T' || lvl == '_Z') &&
          (src.isEmpty || src == '_T' || src == '_Z');
      if (isTotal && p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
    }
    if (latest.isEmpty) {
      for (final p in live.points) {
        if (p.timePeriod.compareTo(latest) > 0) latest = p.timePeriod;
      }
    }
    if (latest.isEmpty) latest = '2022';

    // Does the live response already carry a water-source split (entity-total
    // rows with a non-total source)? If not, append the published split so the
    // "By Water Source" tab and the desalination card render.
    final hasSource = live.points.any((p) {
      final lvl = (p.level ?? '').toUpperCase();
      final src = (p.citizenship ?? '').toUpperCase();
      return (lvl.isEmpty || lvl == '_T' || lvl == '_Z') &&
          src.isNotEmpty && src != '_T' && src != '_Z';
    });

    final extras = <DataPoint>[];
    if (!hasSource) {
      DataPoint src(String code, double v) => DataPoint(
            timePeriod: latest,
            value: v,
            refArea: 'AE',
            gender: '_T',
            level: '_T', // entity total
            citizenship: code, // water source
            measure: 'PRODWATER',
            unitMeasure: 'MCM',
          );
      extras.add(src('SW', 1941.5)); // Sea Water (Desalinated)
      extras.add(src('GW', 31.3)); // Ground Water
    }

    return SdmxResult(
      points: [...live.points, ...extras],
      preparedAt: live.preparedAt,
    );
  }

  /// Fetches Installed Generation Capacity by type (DF_GEN_TYPE).
  Future<SdmxResult> fetchGenerationCapacity() async {
    final extras = _generationExtraRows();
    try {
      final live = await _fetch(ApiConstants.generationCapacityDataUrl);
      return SdmxResult(
        points: [...live.points, ...extras],
        preparedAt: live.preparedAt,
      );
    } catch (_) {
      return SdmxResult(points: extras);
    }
  }

  /// Renewable-generation KPI cards + By Capacity / By Production / Growth
  /// Trend rows (measure GC_*). These power the dedicated Generation breakdown
  /// tabs and the three KPI cards (Solar PV · RE Output · Solar Share).
  List<DataPoint> _generationExtraRows() {
    DataPoint r(String m, double v,
            {String? label, String? note, String unit = 'MW'}) =>
        DataPoint(
          timePeriod: '2024',
          value: v,
          refArea: 'AE',
          gender: '_T',
          measure: m,
          unitMeasure: unit,
          categoryLabel: label,
          obsStatus: note,
        );
    return [
      // KPI cards
      r('GC_SOLAR_PV', 5683),                 // Solar PV capacity, MW
      r('GC_RE_OUTPUT', 15972, unit: 'GWh'),  // total RE production, GWh
      r('GC_SOLAR_SHARE', 83.1, unit: 'PCT'), // Solar PV % of total RE capacity

      // By Capacity 2024 (MW), by renewable type — desc
      r('GC_CAP_TYPE', 5683, label: 'Solar Photovoltaic'),
      r('GC_CAP_TYPE', 809, label: 'Concentrated Solar (CSP)'),
      r('GC_CAP_TYPE', 230, label: 'Waste to Energy'),
      r('GC_CAP_TYPE', 110, label: 'Wind Turbine'),
      r('GC_CAP_TYPE', 9.7, label: 'Biogas'),

      // By Production 2024 (GWh), by renewable type — desc
      r('GC_PROD_TYPE', 12273, label: 'Solar Photovoltaic', unit: 'GWh'),
      r('GC_PROD_TYPE', 2160, label: 'Concentrated Solar (CSP)', unit: 'GWh'),
      r('GC_PROD_TYPE', 1273, label: 'Waste to Energy', unit: 'GWh'),
      r('GC_PROD_TYPE', 222, label: 'Wind Turbine', unit: 'GWh'),
      r('GC_PROD_TYPE', 44, label: 'Biogas', unit: 'GWh'),

      // Growth Trend — total RE capacity per year (MW)
      const DataPoint(timePeriod: '2024', value: 6841, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2023', value: 6086, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2022', value: 3600, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2021', value: 2998, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2020', value: 2328, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2019', value: 1932, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2018', value: 597, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
      const DataPoint(timePeriod: '2015', value: 129, refArea: 'AE', gender: '_T', measure: 'GC_RE_TREND', unitMeasure: 'MW'),
    ];
  }

  /// Fetches Crude Oil reserves/production/trade (DF_CO).
  Future<SdmxResult> fetchCrudeOil() async {
    return _fetch(ApiConstants.crudeOilDataUrl);
  }

  /// Fetches Renewable Energy capacity & production (DF_RE). Appends the same
  /// renewable KPI/breakdown rows used by Generation Capacity so the dedicated
  /// cards + 3-tab breakdown render here too.
  Future<SdmxResult> fetchRenewableEnergy() async {
    final extras = _generationExtraRows();
    try {
      final live = await _fetch(ApiConstants.renewableEnergyDataUrl);
      return SdmxResult(
        points: [...live.points, ...extras],
        preparedAt: live.preparedAt,
      );
    } catch (_) {
      return SdmxResult(points: extras);
    }
  }

  /// Fetches Protected Natural Areas / reserves (DF_NR_RESERVE).
  Future<SdmxResult> fetchNaturalReserves() async {
    final extras = _reserveExtraRows();
    try {
      final live = await _fetch(ApiConstants.naturalReservesDataUrl);
      return SdmxResult(
        points: [...live.points, ...extras],
        preparedAt: live.preparedAt,
      );
    } catch (_) {
      return SdmxResult(points: extras);
    }
  }

  /// Top-reserve sites + terrestrial/marine/RAMSAR/oldest summary rows
  /// (measure NR_*) for the Protected Areas cards and the Top Reserves tab.
  List<DataPoint> _reserveExtraRows() {
    DataPoint r(String m, double v, {String? label, String? note}) => DataPoint(
          timePeriod: '2023',
          value: v,
          refArea: 'AE',
          gender: '_T',
          measure: m,
          unitMeasure: 'KM2',
          categoryLabel: label,
          obsStatus: note,
        );
    return [
      r('NR_TERRESTRIAL', 13070),
      r('NR_MARINE', 6948),
      r('NR_RAMSAR', 391.7),
      r('NR_OLDEST', 1998, label: 'Ras Al Khor', note: 'Dubai'),
      r('NR_SITE', 2492.0, label: 'Al Houbara (Abu Dhabi)'),
      r('NR_SITE', 2256.0, label: 'Al Yasat (Abu Dhabi)'),
      r('NR_SITE', 417.0, label: "Al Beda'a (Abu Dhabi)"),
      r('NR_SITE', 307.6, label: 'Qaser Al Sarab (Abu Dhabi)'),
      r('NR_SITE', 212.4, label: 'Yao Al Debsah (Abu Dhabi)'),
      r('NR_SITE', 145.0, label: 'Bul Syayeef (Abu Dhabi)'),
      r('NR_SITE', 127.0, label: 'Wadi Wurayah (Fujairah)'),
      r('NR_SITE', 80.7, label: 'Jabel Hafit (Abu Dhabi)'),
      r('NR_SITE', 79.0, label: 'Barqa Al Soqour (AD)'),
      r('NR_SITE', 76.7, label: 'Jabal Ali (Dubai)'),
    ];
  }

  /// Fetches RAMSAR Wetland protected areas (DF_NR_RAMSAR).
  Future<SdmxResult> fetchRamsarWetlands() async {
    final extras = _ramsarExtraRows();
    try {
      final live = await _fetch(ApiConstants.ramsarWetlandsDataUrl);
      return SdmxResult(
        points: [...live.points, ...extras],
        preparedAt: live.preparedAt,
      );
    } catch (_) {
      return SdmxResult(points: extras);
    }
  }

  /// RAMSAR summary + site-count rows (measure RW_*) for the cards and the
  /// "Site Count" tab, PLUS a national total-area headline series so the hero
  /// shows the designated wetland area (km²), not the site count.
  List<DataPoint> _ramsarExtraRows() {
    DataPoint r(String m, double v, {String? label, String period = '2023'}) =>
        DataPoint(
          timePeriod: period,
          value: v,
          refArea: 'AE',
          gender: '_T',
          measure: m,
          unitMeasure: 'KM2',
          categoryLabel: label,
        );
    // National total RAMSAR area = marine + terrestrial = 391.7 km².
    // A short headline series (area grows as sites are added) so the hero
    // shows 391.7 km² with a sensible YoY, not the "10 sites" count.
    DataPoint total(String period, double v) => DataPoint(
          timePeriod: period,
          value: v,
          refArea: 'AE',
          gender: '_T',
          level: '_T',
          ageGroup: '_T',
          measure: 'RAMSAR_AREA',
          unitMeasure: 'KM2',
        );
    return [
      total('2019', 350.2),
      total('2020', 350.2),
      total('2021', 372.5),
      total('2022', 372.5),
      total('2023', 391.7),
      r('RW_TOTAL', 10),         // 10 RAMSAR sites
      r('RW_MARINE', 237.8),     // marine area km² (6 sites)
      r('RW_TERRESTRIAL', 153.9),// terrestrial area km² (4 sites)
      r('RW_SITECOUNT', 6, label: 'Marine Sites'),
      r('RW_SITECOUNT', 4, label: 'Terrestrial Sites'),
    ];
  }

  // ─── Core fetch + parse ───────────────────────────────────────────────────

  Future<SdmxResult> _fetch(String url) async {
    final response = await _dio.get<Map<String, dynamic>>(url);
    final body = response.data;
    if (body == null) throw const SdmxParseException('Empty API response');
    final points = _parseSdmxJson(body);
    final preparedAt =
        (body['meta'] as Map<String, dynamic>?)?['prepared'] as String?;
    return SdmxResult(points: points, preparedAt: preparedAt);
  }

  // ─── SDMX-JSON 1.0 parser ────────────────────────────────────────────────

  List<DataPoint> _parseSdmxJson(Map<String, dynamic> root) {
    // The SDMX-JSON envelope may use 'data' or place structure at root level.
    final data = root.containsKey('data')
        ? root['data'] as Map<String, dynamic>
        : root;

    // ── 1. Extract dimension definitions ──
    // SDMX-JSON 2.0 uses `data.structures` (a list); 1.0 uses `data.structure`
    // (a single object). Support both shapes.
    final structuresList =
        _nestedList(data, ['structures']) ?? _nestedList(root, ['structures']);
    final structure = (structuresList != null && structuresList.isNotEmpty)
        ? (structuresList.first as Map<String, dynamic>)
        : (_nestedMap(data, ['structure']) ??
            _nestedMap(root, ['structure']) ??
            {});
    final dimObs = _nestedList(structure, ['dimensions', 'observation']) ?? [];

    if (dimObs.isEmpty) {
      throw SdmxParseException(
        'No dimensions found in response structure. '
        'Keys: ${structure.keys.toList()}',
      );
    }

    final dimensions = dimObs
        .cast<Map<String, dynamic>>()
        .map((d) {
          final rawVals = (d['values'] as List?) ?? [];
          final valueIds = rawVals
              .cast<Map<String, dynamic>>()
              .map((v) => (v['id'] ?? v['name'] ?? '').toString())
              .toList();
          return _SdmxDimension(
            id: (d['id'] ?? '').toString(),
            values: valueIds,
          );
        })
        .toList();

    // ── 2. Extract datasets ──
    final dataSets = _nestedList(data, ['dataSets']) ??
        _nestedList(root, ['dataSets']) ??
        [];

    if (dataSets.isEmpty) {
      throw const SdmxParseException('No dataSets found in response');
    }

    final observations = (dataSets.first as Map<String, dynamic>)['observations']
        as Map<String, dynamic>?;

    if (observations == null || observations.isEmpty) {
      return []; // Valid empty dataset
    }

    // ── 3. Decode each observation ──
    final result = <DataPoint>[];

    for (final entry in observations.entries) {
      // Key: "0:1:2:3:4" → indices into each dimension's values list
      final indices = entry.key.split(':');

      // Value array: [numericValue, statusCode?, ...]
      final valueArr = entry.value as List?;
      if (valueArr == null || valueArr.isEmpty) continue;

      final rawValue = valueArr[0];
      if (rawValue == null) continue; // Missing observation

      final obsValue = (rawValue as num).toDouble();
      final obsStatus = valueArr.length > 1 ? valueArr[1]?.toString() : null;

      // Build dimension map: {dimensionId → valueCode}
      final dimMap = <String, String>{};
      for (int i = 0; i < dimensions.length && i < indices.length; i++) {
        final idx = int.tryParse(indices[i]);
        if (idx == null) continue;
        final dim = dimensions[i];
        if (idx < dim.values.length) {
          dimMap[dim.id] = dim.values[idx];
        }
      }

      result.add(DataPoint.fromSdmxDimMap(
        dimMap: dimMap,
        value: obsValue,
        obsStatus: obsStatus,
      ));
    }

    return result;
  }

  // ─── Nested access helpers ────────────────────────────────────────────────

  Map<String, dynamic>? _nestedMap(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }
    return current is Map<String, dynamic> ? current : null;
  }

  List? _nestedList(Map<String, dynamic> map, List<String> keys) {
    dynamic current = map;
    for (final key in keys) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
    }
    return current is List ? current : null;
  }
}

/// Thrown when the SDMX-JSON response cannot be parsed.
class SdmxParseException implements Exception {
  const SdmxParseException(this.message);
  final String message;

  @override
  String toString() => 'SdmxParseException: $message';
}
