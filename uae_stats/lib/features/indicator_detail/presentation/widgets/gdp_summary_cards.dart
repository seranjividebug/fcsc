// lib/features/indicator_detail/presentation/widgets/gdp_summary_cards.dart
//
// GDP (Current Prices) headline summary strip — four compact stat cards shown
// at the very top of the GDP detail page:
//   • 2024 TOTAL    — latest headline value (AED-mn → "T")
//   • NON-OIL GDP   — ISIC `_TNO` aggregate (AED-mn → "T")
//   • 10Y GROWTH    — first→last growth over the last ≤10 years
//   • TOP SECTOR    — leading ISIC sector + its share of the total
//
// All values are computed from [IndicatorData]; cards with no available source
// (non-oil / top-sector when the breakdown is absent) are omitted rather than
// fabricated.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

/// Human-readable short names for the GDP ISIC sector codes.
const _gdpSectorNames = <String, ({String en, String ar})>{
  'A':  (en: 'Agriculture',          ar: 'الزراعة'),
  'B':  (en: 'Oil & Gas',            ar: 'النفط والغاز'),
  'C':  (en: 'Manufacturing',        ar: 'الصناعة التحويلية'),
  'DE': (en: 'Electricity & Water',  ar: 'الكهرباء والمياه'),
  'F':  (en: 'Construction',         ar: 'الإنشاءات'),
  'G':  (en: 'Trade',                ar: 'التجارة'),
  'H':  (en: 'Transport',            ar: 'النقل والتخزين'),
  'I':  (en: 'Hospitality',          ar: 'الإقامة والطعام'),
  'J':  (en: 'Info & Comm.',         ar: 'المعلومات والاتصالات'),
  'K':  (en: 'Finance',              ar: 'المال والتأمين'),
  'L':  (en: 'Real Estate',          ar: 'العقارات'),
  'MN': (en: 'Professional',         ar: 'الأنشطة المهنية'),
  'O':  (en: 'Public Admin.',        ar: 'الإدارة العامة'),
  'P':  (en: 'Education',            ar: 'التعليم'),
  'Q':  (en: 'Health',               ar: 'الصحة'),
  'RS': (en: 'Arts & Other',         ar: 'الفنون وأخرى'),
  'T':  (en: 'Households',           ar: 'الأسر المعيشية'),
};

class GdpSummaryCards extends ConsumerWidget {
  const GdpSummaryCards({super.key, required this.data});

  final IndicatorData data;

  /// Growth (%) across the last [n] points of the headline series.
  double? _growthOverLast(int n) {
    final series = data.uaeTotalSeries;
    if (series.length < 2) return null;
    final slice =
        series.length > n ? series.sublist(series.length - n) : series;
    final first = slice.first.value;
    if (first == 0) return null;
    return (slice.last.value - first) / first * 100;
  }

  /// The span label for the growth card, e.g. "2015 →2024".
  String _growthSpan(int n) {
    final series = data.uaeTotalSeries;
    final slice =
        series.length > n ? series.sublist(series.length - n) : series;
    if (slice.length < 2) return '';
    return '${slice.first.timePeriod} →${slice.last.timePeriod}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final period = data.latestPeriod;

    final cards = <Widget>[
      // ── 2024 TOTAL ──────────────────────────────────────────────────────
      _SummaryCard(
        overline: isAr ? 'إجمالي $period' : '$period TOTAL',
        value: NumberFormatter.aedMillionsCompact(data.latestValue),
        caption: isAr ? 'بالأسعار الجارية' : 'AED current',
      ),
    ];

    // ── NON-OIL GDP (ISIC _TNO) ───────────────────────────────────────────
    final nonOil = data.gdpNonOilLatest;
    if (nonOil != null) {
      final share = data.latestValue > 0 ? nonOil / data.latestValue * 100 : 0;
      cards.add(_SummaryCard(
        overline: isAr ? 'الناتج غير النفطي' : 'NON-OIL GDP',
        value: NumberFormatter.aedMillionsCompact(nonOil),
        caption: isAr
            ? '${share.toStringAsFixed(1)}% حصة'
            : '${share.toStringAsFixed(1)}% share',
      ));
    }

    // ── 10Y GROWTH ────────────────────────────────────────────────────────
    final g10 = _growthOverLast(10);
    if (g10 != null) {
      cards.add(_SummaryCard(
        overline: isAr ? 'نمو ١٠ سنوات' : '10Y GROWTH',
        value: NumberFormatter.percent(g10),
        caption: _growthSpan(10),
        valueColor: g10 < 0 ? AppColors.error : AppColors.success,
      ));
    }

    // ── TOP SECTOR (leading ISIC sector) ──────────────────────────────────
    final top = data.gdpTopSector;
    if (top != null) {
      final name = _gdpSectorNames[top.code.toUpperCase()];
      final label = name == null
          ? top.code
          : (isAr ? name.ar : name.en);
      cards.add(_SummaryCard(
        overline: isAr ? 'القطاع الأكبر' : 'TOP SECTOR',
        value: label,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة'
            : '${top.share.toStringAsFixed(1)}% share',
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.overline,
    required this.value,
    required this.caption,
    this.valueColor,
  });

  final String overline;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            overline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.slate900,
                height: 1.05,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}
