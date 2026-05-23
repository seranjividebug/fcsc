// lib/core/constants/app_constants.dart

abstract final class AppConstants {
  // ─── App identity ────────────────────────────────────────────────────────
  static const String appNameEn    = 'UAE Stats';
  static const String appNameAr    = 'إحصاءات الإمارات';
  static const String appVersion   = '1.0.0';
  static const String bundleId     = 'ae.gov.fcsc.uaestats';

  // ─── Organisation ────────────────────────────────────────────────────────
  static const String fcscNameEn = 'Federal Competitiveness and Statistics Centre';
  static const String fcscNameAr = 'الهيئة الاتحادية للتنافسية والإحصاء';
  static const String fcscWebsite = 'uaestat.fcsc.gov.ae';
  static const String fcscUrl     = 'https://uaestat.fcsc.gov.ae';

  // ─── Asset paths ─────────────────────────────────────────────────────────
  static const String logoFcscDark     = 'assets/images/uae_stats_logo_mark.svg';
  static const String logoFcscMocaDark = 'assets/images/fcsc_moca_logo_dark.svg';
  static const String codelists        = 'assets/data/translations/codelists.json';

  // ─── Shared preferences keys ─────────────────────────────────────────────
  static const String prefLocale       = 'pref_locale';
  static const String prefBookmarks    = 'pref_bookmarks';
  static const String prefFirstLaunch  = 'pref_first_launch';

  // ─── Splash timing (milliseconds) ────────────────────────────────────────
  static const int splashTotalMs       = 2700;
  static const int splashProgressMs    = 2300;

  // ─── Default locale ──────────────────────────────────────────────────────
  static const String defaultLocale = 'en';

  // ─── Supported locales ───────────────────────────────────────────────────
  static const List<String> supportedLocales = ['en', 'ar'];
}
