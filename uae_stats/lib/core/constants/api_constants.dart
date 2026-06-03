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
      '?startPeriod=2015&$flatDimension';

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
  static const String dfGdpQCur         = 'DF_QGDP_CUR';
  static const String dfGdpQCurVersion  = '1.8.0';
  /// GDP Current Prices — UAE total (_T sector, annual).
  /// Filter: .A............. → all dimension slots, frequency=Annual
  static String get gdpCurrentDataUrl =>
      '$restBase/data/$_agencyId,$dfGdpCurr,$dfGdpCurrVersion/.A.............?startPeriod=2015&$flatDimension';

  /// GDP Constant Prices — UAE total, annual.
  static String get gdpConstantDataUrl =>
      '$restBase/data/$_agencyId,$dfGdpConst,$dfGdpConstVersion/.A.............?startPeriod=2015&$flatDimension';

  /// Quarterly GDP Constant Prices — UAE total.
  /// Filter: .Q...... → quarterly frequency, all dimensions
  static String get gdpQuarterlyConstantDataUrl =>
      '$restBase/data/$_agencyId,$dfGdpQ,$dfGdpQVersion/.Q......?startPeriod=2015-Q1&$flatDimension';

  /// Quarterly GDP Current Prices (DF_QGDP_CUR).
  static String get gdpQuarterlyCurrentDataUrl =>
      '$restBase/data/$_agencyId,$dfGdpQCur,$dfGdpQCurVersion/.Q......?startPeriod=2015-Q1&$flatDimension';

  static const String dfTradeHs         = 'DF_TRADE_TOT_YR';
  static const String dfTradeHsVersion  = '5.1.0';
  static const String dfTradeSect       = 'DF_TRADE_SECT_YR';
  static const String dfTradeSectVersion = '5.1.0';

  static const String dfTradeImpSect        = 'DF_TRADE_IMP_SECT_YR';
  static const String dfTradeImpSectVersion = '5.1.0';

  /// Total Trade by HS Section — UAE total, annual.
  static String get tradeTotalDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeSect,$dfTradeSectVersion/.A.......?startPeriod=2017&$flatDimension';

  /// Imports by HS Section — UAE total, annual.
  static String get tradeImportsHsDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeImpSect,$dfTradeImpSectVersion/.A.......?startPeriod=2017&$flatDimension';

  static const String dfTradeNonOil        = 'DF_TRADE_TEXP_SECT_YR';
  static const String dfTradeNonOilVersion = '5.1.0';

  /// Non-Oil Exports by HS Section — UAE total, annual.
  static String get tradeNonOilExportsDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeNonOil,$dfTradeNonOilVersion/.A.......?startPeriod=2017&$flatDimension';

  static const String dfTradeExpSect        = 'DF_TRADE_EXP_SECT_YR';
  static const String dfTradeExpSectVersion = '5.1.0';

  /// Non-Oil Exports (Domestic) by HS Section & Country — UAE total, annual.
  static String get tradeSectorCountryDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeExpSect,$dfTradeExpSectVersion/.A.......?startPeriod=2017&$flatDimension';

  static const String dfTradeReExp        = 'DF_TRADE_REXP_SECT_YR';
  static const String dfTradeReExpVersion = '5.1.0';

  /// Annual Re-Exports by HS Section & Country — UAE total, annual.
  static String get tradeReexportsAnnualDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeReExp,$dfTradeReExpVersion/.A.......?startPeriod=2017&$flatDimension';

  static const String dfTradeReExpMon        = 'DF_TRADE_REXP_COUNTRY_MTH';
  static const String dfTradeReExpMonVersion = '5.1.0';

  /// Monthly Re-Exports by Destination Country — UAE total.
  static String get tradeReexportsMonthlyDataUrl =>
      '$restBase/data/$_agencyId,$dfTradeReExpMon,$dfTradeReExpMonVersion/.M.......?startPeriod=2024-01&$flatDimension';
  static const String dfCpi             = 'DF_CPI_ANN';
  static const String dfCpiVersion      = '3.2.0';

  /// CPI Annual — UAE total, All Items.
  static String get cpiAnnualDataUrl =>
      '$restBase/data/$_agencyId,$dfCpi,$dfCpiVersion/...A..?startPeriod=2021&$flatDimension';
  static const String dfHotels          = 'DF_ALL_HOT';
  static const String dfHotelsVersion   = '4.3.0';
  static const String dfGuestRegion        = 'DF_GUEST_REGION';
  static const String dfGuestRegionVersion = '4.3.0';
  static const String dfHotType            = 'DF_HOT_TYPE';
  static const String dfHotTypeVersion     = '4.3.0';
  static const String dfHotIndicator       = 'DF_HOT_INDICATOR';
  static const String dfHotIndicatorVersion = '4.3.0';

  /// Hotel Main Indicators (guests, revenue, occupancy etc) — UAE total, annual.
  static String get tourismMainIndicatorsDataUrl =>
      '$restBase/data/$_agencyId,$dfHotIndicator,$dfHotIndicatorVersion/...A....?startPeriod=2016&$flatDimension';

  /// Hotel Guest Arrivals by Nationality Region — UAE total, annual.
  static String get tourismHotelArrivalsDataUrl =>
      '$restBase/data/$_agencyId,$dfGuestRegion,$dfGuestRegionVersion/...A....?startPeriod=2016&$flatDimension';

  /// Hotel Establishments by Type, Class & Rooms — UAE total, annual.
  static String get tourismHotelEstablishmentsDataUrl =>
      '$restBase/data/$_agencyId,$dfHotType,$dfHotTypeVersion/...A....?startPeriod=2016&$flatDimension';
  static const String dfAir             = 'DF_AIRCRAFT_MOV';
  static const String dfAirVersion      = '1.6.0';

  /// Aircraft Movement by Emirate — UAE total, annual.
  static String get aircraftMovementDataUrl =>
      '$restBase/data/$_agencyId,$dfAir,$dfAirVersion/.A....?startPeriod=2016&$flatDimension';

  // ─── Social dataflows ────────────────────────────────────────────────────
  // Population reuses DF_POP (already defined above)
  static const String dfEducation        = 'DF_EDU_STUD';
  static const String dfEducationVersion = '1.3.0';
  static const String dfEduTeach         = 'DF_EDU_TEACH';
  static const String dfEduTeachVersion  = '1.3.0';
  static const String dfEduHigh          = 'DF_HE_STUDENTS_ARG';
  static const String dfEduHighVersion   = '2.3.0';

  /// General Education Students — canonical endpoint.
  /// Filter: ...A..... → all dimension slots, frequency=Annual
  static String get educationDataUrl =>
      '$restBase/data/$_agencyId,$dfEducation,$dfEducationVersion/...A.....'
      '?startPeriod=2018&$flatDimension';

  /// General Education Teaching Staff (DF_EDU_TEACH).
  static String get educationTeachingStaffUrl =>
      '$restBase/data/$_agencyId,$dfEduTeach,$dfEduTeachVersion/...A.....'
      '?startPeriod=2018&$flatDimension';

  /// Higher Education Students (DF_HE_STUDENTS_ARG).
  static String get educationHigherUrl =>
      '$restBase/data/$_agencyId,$dfEduHigh,$dfEduHighVersion/all'
      '?startPeriod=2018&$flatDimension';

  static const String dfHealth               = 'DF_HEALTH_FACILITIES';
  static const String dfHealthVersion        = '3.1.0';
  static const String dfHealthWorkforce      = 'DF_HEALTH_WORKFORCE';
  static const String dfHealthWorkforceVersion = '3.1.0';

  /// Health Facilities — all types.
  static String get healthDataUrl =>
      '$restBase/data/$_agencyId,$dfHealth,$dfHealthVersion/all'
      '?startPeriod=2018&$flatDimension';

  /// Hospitals only (HSP filter).
  static String get hospitalServicesDataUrl =>
      '$restBase/data/$_agencyId,$dfHealth,$dfHealthVersion/HSP...A....'
      '?startPeriod=2018&$flatDimension';

  /// Clinics & Health Centres only (CAH filter).
  static String get clinicsDataUrl =>
      '$restBase/data/$_agencyId,$dfHealth,$dfHealthVersion/CAH...A....'
      '?startPeriod=2018&$flatDimension';

  /// Hospital Beds only (BED filter).
  static String get hospitalBedsDataUrl =>
      '$restBase/data/$_agencyId,$dfHealth,$dfHealthVersion/BED...A....'
      '?startPeriod=2018&$flatDimension';

  /// Health Workforce professionals.
  static String get healthWorkforceDataUrl =>
      '$restBase/data/$_agencyId,$dfHealthWorkforce,$dfHealthWorkforceVersion/...A.....'
      '?startPeriod=2018&$flatDimension';
  static const String dfLabour          = 'DF_LF_ALL';
  static const String dfLabourVersion   = '2.0.0';

  // ─── Environment dataflows ───────────────────────────────────────────────
  static const String dfCrops           = 'DF_CROP_ALL';
  static const String dfCropsVersion    = '3.0.0';
  static const String dfCropEm          = 'DF_CROP_EM';
  static const String dfCropEmVersion   = '3.0.0';
  static const String dfCropLand        = 'DF_CROP_LAND';
  static const String dfCropLandVersion = '3.0.0';

  /// Crop Statistics by Emirate — annual, all dimensions.
  static String get cropEmDataUrl =>
      '$restBase/data/$_agencyId,$dfCropEm,$dfCropEmVersion/.A......'
      '?startPeriod=2015&$flatDimension';

  /// Agricultural Land Use by Emirate — annual, all dimensions.
  static String get cropLandDataUrl =>
      '$restBase/data/$_agencyId,$dfCropLand,$dfCropLandVersion/.A......'
      '?startPeriod=2016&$flatDimension';
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

  /// Climate Mean Temperature — monthly, all stations, from 2016.
  static String get climateTempDataUrl =>
      '$restBase/data/$_agencyId,$dfClimateTemp,$dfClimateTempVersion/...M...'
      '?startPeriod=2016-01&$flatDimension';

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
