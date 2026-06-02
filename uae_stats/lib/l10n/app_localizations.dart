import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// App name in English
  ///
  /// In en, this message translates to:
  /// **'UAE Stats'**
  String get appNameEn;

  /// App name in Arabic
  ///
  /// In en, this message translates to:
  /// **'إحصاءات الإمارات'**
  String get appNameAr;

  /// No description provided for @fcscNameEn.
  ///
  /// In en, this message translates to:
  /// **'Federal Competitiveness and Statistics Authority'**
  String get fcscNameEn;

  /// No description provided for @fcscNameAr.
  ///
  /// In en, this message translates to:
  /// **'الهيئة الاتحادية للتنافسية والإحصاء'**
  String get fcscNameAr;

  /// No description provided for @splashTaglineEn.
  ///
  /// In en, this message translates to:
  /// **'Data for a Better Future'**
  String get splashTaglineEn;

  /// No description provided for @splashTaglineAr.
  ///
  /// In en, this message translates to:
  /// **'بيانات من أجل مستقبل أفضل'**
  String get splashTaglineAr;

  /// No description provided for @splashOfficialEn.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL GOVERNMENT APP'**
  String get splashOfficialEn;

  /// No description provided for @splashLoadingEn.
  ///
  /// In en, this message translates to:
  /// **'Loading official data…'**
  String get splashLoadingEn;

  /// No description provided for @splashReadyEn.
  ///
  /// In en, this message translates to:
  /// **'✓ Ready'**
  String get splashReadyEn;

  /// No description provided for @homeOfficialStats.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL STATISTICS'**
  String get homeOfficialStats;

  /// No description provided for @homeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated:'**
  String get homeUpdated;

  /// No description provided for @homeKeyFigures.
  ///
  /// In en, this message translates to:
  /// **'Key Figures at a Glance'**
  String get homeKeyFigures;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search indicators, topics, data…'**
  String get searchPlaceholder;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterDemography.
  ///
  /// In en, this message translates to:
  /// **'Demography'**
  String get filterDemography;

  /// No description provided for @filterEconomy.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get filterEconomy;

  /// No description provided for @filterEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get filterEnvironment;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @latestReleases.
  ///
  /// In en, this message translates to:
  /// **'Latest Releases'**
  String get latestReleases;

  /// No description provided for @categoryDemography.
  ///
  /// In en, this message translates to:
  /// **'Demography'**
  String get categoryDemography;

  /// No description provided for @categoryDemographySub.
  ///
  /// In en, this message translates to:
  /// **'Population · Vitals · Education · Health · Labor · Social'**
  String get categoryDemographySub;

  /// No description provided for @subPopulation.
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get subPopulation;

  /// No description provided for @subVitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get subVitals;

  /// No description provided for @popTileDesc.
  ///
  /// In en, this message translates to:
  /// **'Population Estimates'**
  String get popTileDesc;

  /// No description provided for @vitalsTileDesc.
  ///
  /// In en, this message translates to:
  /// **'Births, Deaths, Marriages, Divorces'**
  String get vitalsTileDesc;

  /// No description provided for @vitalsTileCount.
  ///
  /// In en, this message translates to:
  /// **'4 indicators'**
  String get vitalsTileCount;

  /// No description provided for @sheetSubtitleDemography.
  ///
  /// In en, this message translates to:
  /// **'Demography · 4 indicators'**
  String get sheetSubtitleDemography;

  /// No description provided for @indBirths.
  ///
  /// In en, this message translates to:
  /// **'Births'**
  String get indBirths;

  /// No description provided for @indDeaths.
  ///
  /// In en, this message translates to:
  /// **'Deaths'**
  String get indDeaths;

  /// No description provided for @indMarriages.
  ///
  /// In en, this message translates to:
  /// **'Marriages'**
  String get indMarriages;

  /// No description provided for @indDivorces.
  ///
  /// In en, this message translates to:
  /// **'Divorces'**
  String get indDivorces;

  /// No description provided for @indPopulation.
  ///
  /// In en, this message translates to:
  /// **'Population Estimates'**
  String get indPopulation;

  /// No description provided for @actionBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get actionBookmark;

  /// No description provided for @actionSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get actionSubscribe;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get actionDownload;

  /// No description provided for @trendSection.
  ///
  /// In en, this message translates to:
  /// **'5-Year Trend'**
  String get trendSection;

  /// No description provided for @chartTabLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get chartTabLine;

  /// No description provided for @chartTabBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get chartTabBar;

  /// No description provided for @chartTabTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get chartTabTable;

  /// No description provided for @range2y.
  ///
  /// In en, this message translates to:
  /// **'2Y'**
  String get range2y;

  /// No description provided for @range5y.
  ///
  /// In en, this message translates to:
  /// **'5Y'**
  String get range5y;

  /// No description provided for @range10y.
  ///
  /// In en, this message translates to:
  /// **'10Y'**
  String get range10y;

  /// No description provided for @rangeMax.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get rangeMax;

  /// No description provided for @statsMin.
  ///
  /// In en, this message translates to:
  /// **'5Y MIN'**
  String get statsMin;

  /// No description provided for @statsMax.
  ///
  /// In en, this message translates to:
  /// **'5Y MAX'**
  String get statsMax;

  /// No description provided for @statsAvg.
  ///
  /// In en, this message translates to:
  /// **'5Y AVG'**
  String get statsAvg;

  /// No description provided for @statsGrowth.
  ///
  /// In en, this message translates to:
  /// **'5Y GROWTH'**
  String get statsGrowth;

  /// No description provided for @tableYear.
  ///
  /// In en, this message translates to:
  /// **'YEAR'**
  String get tableYear;

  /// No description provided for @tableValue.
  ///
  /// In en, this message translates to:
  /// **'VALUE'**
  String get tableValue;

  /// No description provided for @tableYoy.
  ///
  /// In en, this message translates to:
  /// **'YOY'**
  String get tableYoy;

  /// No description provided for @breakdownOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get breakdownOverall;

  /// No description provided for @breakdownEmirate.
  ///
  /// In en, this message translates to:
  /// **'By Emirate'**
  String get breakdownEmirate;

  /// No description provided for @breakdownGender.
  ///
  /// In en, this message translates to:
  /// **'By Gender'**
  String get breakdownGender;

  /// No description provided for @breakdownNationality.
  ///
  /// In en, this message translates to:
  /// **'By Nationality'**
  String get breakdownNationality;

  /// No description provided for @aboutIndicator.
  ///
  /// In en, this message translates to:
  /// **'About This Indicator'**
  String get aboutIndicator;

  /// No description provided for @relatedIndicators.
  ///
  /// In en, this message translates to:
  /// **'Related Indicators'**
  String get relatedIndicators;

  /// No description provided for @compareIndicator.
  ///
  /// In en, this message translates to:
  /// **'Compare with Another Indicator'**
  String get compareIndicator;

  /// No description provided for @dataSource.
  ///
  /// In en, this message translates to:
  /// **'Data Source'**
  String get dataSource;

  /// No description provided for @updateFrequency.
  ///
  /// In en, this message translates to:
  /// **'Update Frequency'**
  String get updateFrequency;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last Update'**
  String get lastUpdate;

  /// No description provided for @dataCoverage.
  ///
  /// In en, this message translates to:
  /// **'Data Coverage'**
  String get dataCoverage;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navBookmarks;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNoConnection;

  /// No description provided for @errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorRetry;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing cached data'**
  String get offlineBanner;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This indicator will be available soon.'**
  String get comingSoonMessage;

  /// No description provided for @birthsLiveSub.
  ///
  /// In en, this message translates to:
  /// **'live births in 2024'**
  String get birthsLiveSub;

  /// No description provided for @popLiveSub.
  ///
  /// In en, this message translates to:
  /// **'estimated residents in UAE'**
  String get popLiveSub;

  /// No description provided for @birthsSource.
  ///
  /// In en, this message translates to:
  /// **'Ministry of Health and Prevention'**
  String get birthsSource;

  /// No description provided for @popSource.
  ///
  /// In en, this message translates to:
  /// **'Federal Competitiveness and Statistics Authority'**
  String get popSource;

  /// No description provided for @annualFrequency.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annualFrequency;

  /// No description provided for @unitPersons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get unitPersons;

  /// No description provided for @languageToggleEn.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageToggleEn;

  /// No description provided for @languageToggleAr.
  ///
  /// In en, this message translates to:
  /// **'عربي'**
  String get languageToggleAr;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
