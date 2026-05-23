// lib/core/constants/api_constants.dart
// FCSC SDMX REST API — endpoint definitions

abstract final class ApiConstants {
  // ─── Base ────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://releaseeuaestat.fcsc.gov.ae';
  static const String restBase = '$baseUrl/rest';

  // ─── Headers ─────────────────────────────────────────────────────────────
  static const Map<String, String> sdmxJsonHeaders = {
    'Accept': 'application/vnd.sdmx.data+json;version=1.0',
  };

  static const Map<String, String> sdmxStructureHeaders = {
    'Accept': 'application/vnd.sdmx.structure+json;version=1.0',
  };

  // ─── Common query params ──────────────────────────────────────────────────
  static const String flatDimension = 'dimensionAtObservation=AllDimensions';
  static const String defaultStartPeriod = '2015';

  // ─── Dataflow IDs ────────────────────────────────────────────────────────
  static const String _agencyId = 'FCSA';

  static const String dfPopulation = 'DF_POP';
  static const String dfPopulationVersion = '2.7.0';

  static const String dfBirths = 'DF_BIRTHS';
  static const String dfBirthsVersion = '1.9.0';

  static const String dfDivorces = 'DF_DV_NA';
  static const String dfDivorcesVersion = '1.5.0';

  static const String dfDeaths = 'DF_DEATHS';
  static const String dfDeathsVersion = '2.9.0';

  static const String dfMarriages = 'DF_MR_NA';
  static const String dfMarriagesVersion = '1.5.0';

  // ─── URL builders ────────────────────────────────────────────────────────

  /// Data endpoint for Population Estimates (full history from 1970).
  /// Key: ....A.. → MEASURE=all, UNIT=all, REF_AREA=all, FREQ=A, GENDER=all, POP_IND=all, SOURCE=all
  static String get populationDataUrl =>
      '$restBase/data/$_agencyId,$dfPopulation,$dfPopulationVersion/....A..'
      '?startPeriod=1970&$flatDimension';

  /// Data endpoint for Births.
  /// Key: ...A....... → all dimensions, freq=Annual
  static String get birthsDataUrl =>
      '$restBase/data/$_agencyId,$dfBirths,$dfBirthsVersion/...A.......'
      '?startPeriod=$defaultStartPeriod&$flatDimension';

  /// Data endpoint for Divorces (DF_DV_NA 1.5.0).
  static String get divorcesDataUrl =>
      '$restBase/data/$_agencyId,$dfDivorces,$dfDivorcesVersion/.A....'
      '?startPeriod=2015&endPeriod=2021&$flatDimension';

  /// Data endpoint for Deaths (DF_DEATHS 2.9.0).
  /// Filter: ...A...... → all dimension slots, frequency=Annual
  static String get deathsDataUrl =>
      '$restBase/data/$_agencyId,$dfDeaths,$dfDeathsVersion/...A......'
      '?startPeriod=$defaultStartPeriod&$flatDimension';

  /// Data endpoint for Marriages (DF_MR_NA 1.5.0).
  /// Filter: .A........ → all dimension slots, frequency=Annual
  static String get marriagesDataUrl =>
      '$restBase/data/$_agencyId,$dfMarriages,$dfMarriagesVersion/.A........'
      '?startPeriod=2016&$flatDimension';

  /// Structure/metadata endpoint for Population.
  static String get populationStructureUrl =>
      '$restBase/dataflow/$_agencyId/$dfPopulation/$dfPopulationVersion'
      '?references=all';

  /// Structure/metadata endpoint for Births.
  static String get birthsStructureUrl =>
      '$restBase/dataflow/$_agencyId/$dfBirths/$dfBirthsVersion'
      '?references=all';

  // ─── Economy dataflows ───────────────────────────────────────────────────
  static const String dfGdpConst        = 'DF_NA_ISIC_CON';
  static const String dfGdpConstVersion = '3.4.0';
  static const String dfGdpCurr         = 'DF_NA_ISIC_CUR';
  static const String dfGdpCurrVersion  = '3.4.0';
  static const String dfGdpQ            = 'DF_QGDP_CON';
  static const String dfGdpQVersion     = '1.8.0';
  static const String dfTradeHs         = 'DF_TRADE_TOT_YR';
  static const String dfTradeHsVersion  = '5.1.0';
  static const String dfCpi             = 'DF_CPI_ANN';
  static const String dfCpiVersion      = '3.2.0';
  static const String dfHotels          = 'DF_ALL_HOT';
  static const String dfHotelsVersion   = '4.3.0';
  static const String dfAir             = 'DF_AIRCRAFT_MOV';
  static const String dfAirVersion      = '1.6.0';

  // ─── Social dataflows ────────────────────────────────────────────────────
  // Population reuses DF_POP (already defined above)
  static const String dfEducation       = 'DF_EDU_STUD';
  static const String dfEducationVersion= '1.3.0';

  /// General Education Students — canonical endpoint.
  /// Filter: ...A..... → all dimension slots, frequency=Annual
  static String get educationDataUrl =>
      '$restBase/data/$_agencyId,$dfEducation,$dfEducationVersion/...A.....'
      '?startPeriod=2022&$flatDimension';

  static const String dfHealth          = 'DF_HEALTH_FACILITIES';
  static const String dfHealthVersion   = '3.1.0';
  static const String dfLabour          = 'DF_LF_ALL';
  static const String dfLabourVersion   = '2.0.0';

  // ─── Environment dataflows ───────────────────────────────────────────────
  static const String dfCrops           = 'DF_CROP_ALL';
  static const String dfCropsVersion    = '3.0.0';
  static const String dfLivestock       = 'DF_LSALL';
  static const String dfLivestockVersion= '1.2.0';
  static const String dfClimateTemp     = 'DF_CLIMATE_TEMP';
  static const String dfClimateTempVersion = '3.7.0';
  static const String dfClimateRain     = 'DF_CLIMATE_RAIN';
  static const String dfClimateRainVersion = '3.7.0';
  static const String dfWaterDesal      = 'DF_PW_QUANTITY_DESL_WATER';
  static const String dfWaterDesalVersion = '5.7.0';
  static const String dfNatReserves     = 'DF_NR_ALL';
  static const String dfNatReservesVersion = '5.8.0';
  static const String dfElectricity     = 'DF_CE';
  static const String dfElectricityVersion = '5.3.0';
  static const String dfRenewable       = 'DF_RE';
  static const String dfRenewableVersion= '1.9.0';
  static const String dfOilGas          = 'DF_CO';
  static const String dfOilGasVersion   = '4.1.0';

  // ─── Generic SDMX data URL builder ───────────────────────────────────────
  static String dataUrl({
    required String dataflowId,
    required String version,
    required String filter,
    String agency = _agencyId,
    String startPeriod = defaultStartPeriod,
  }) =>
      '$restBase/data/$agency,$dataflowId,$version/$filter'
      '?startPeriod=$startPeriod&$flatDimension';

  // ─── Cache keys ──────────────────────────────────────────────────────────
  static const String cacheKeyPopulation = 'indicator_population';
  static const String cacheKeyBirths     = 'indicator_births';
  static const String cacheKeyDivorces   = 'indicator_divorces';
  static const String cacheKeyDeaths     = 'indicator_deaths';
  static const String cacheKeyMarriages  = 'indicator_marriages';

  // ─── Timeouts ────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration cacheTtl       = Duration(hours: 24);
}
