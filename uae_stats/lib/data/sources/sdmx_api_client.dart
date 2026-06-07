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

  /// Fetches Total Trade by HS Section (DF_TRADE_SECT_YR).
  Future<SdmxResult> fetchTradeTotal() async {
    return _fetch(ApiConstants.tradeTotalDataUrl);
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

  /// Fetches GDP at Constant Prices (DF_NA_ISIC_CON).
  Future<SdmxResult> fetchGdpConstant() async {
    return _fetch(ApiConstants.gdpConstantDataUrl);
  }

  /// Fetches Quarterly GDP at Constant Prices (DF_QGDP_CON).
  Future<SdmxResult> fetchGdpQuarterlyConstant() async {
    return _fetch(ApiConstants.gdpQuarterlyConstantDataUrl);
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

  /// Fetches Quarterly GDP at Current Prices (DF_NA_ISIC_CUR quarterly).
  Future<SdmxResult> fetchGdpQuarterlyCurrent() async {
    return _fetch(ApiConstants.gdpQuarterlyCurrentDataUrl);
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

  /// Fetches Annual Rainfall by weather station (DF_CLIMATE_RAIN).
  Future<SdmxResult> fetchRainfall() async {
    return _fetch(ApiConstants.rainfallDataUrl);
  }

  /// Fetches Produced Water by entity & source (DF_PW_Q_PRODWATER_SOURCE).
  Future<SdmxResult> fetchProducedWater() async {
    return _fetch(ApiConstants.producedWaterDataUrl);
  }

  /// Fetches Installed Generation Capacity by type (DF_GEN_TYPE).
  Future<SdmxResult> fetchGenerationCapacity() async {
    return _fetch(ApiConstants.generationCapacityDataUrl);
  }

  /// Fetches Crude Oil reserves/production/trade (DF_CO).
  Future<SdmxResult> fetchCrudeOil() async {
    return _fetch(ApiConstants.crudeOilDataUrl);
  }

  /// Fetches Renewable Energy capacity & production (DF_RE).
  Future<SdmxResult> fetchRenewableEnergy() async {
    return _fetch(ApiConstants.renewableEnergyDataUrl);
  }

  /// Fetches Protected Natural Areas / reserves (DF_NR_RESERVE).
  Future<SdmxResult> fetchNaturalReserves() async {
    return _fetch(ApiConstants.naturalReservesDataUrl);
  }

  /// Fetches RAMSAR Wetland protected areas (DF_NR_RAMSAR).
  Future<SdmxResult> fetchRamsarWetlands() async {
    return _fetch(ApiConstants.ramsarWetlandsDataUrl);
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
