// lib/features/more/presentation/screens/bookmarks_screen.dart
//
// "My Bookmarks" — lists the indicators the user has saved (persisted via
// [bookmarkProvider]). Each saved indicator is rendered as a statistics card
// in the same visual language as the home KPI cards: category-coloured stripe,
// localized name + category badge, latest value, and a YoY trend pill.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_summary.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/features/more/presentation/widgets/more_app_bar.dart';
import 'package:uae_stats/shared/providers/bookmark_provider.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/trend_pill.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final ids = ref.watch(bookmarkProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          MoreAppBar(title: isAr ? 'الإشارات المرجعية' : 'My Bookmarks'),
          Expanded(
            child: ids.isEmpty
                ? _EmptyState(isAr: isAr)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                        child: Row(
                          children: [
                            Text(
                              isAr ? 'المؤشرات المحفوظة' : 'Saved Indicators',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.pearlGray,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusPill),
                              ),
                              child: Text(
                                '${ids.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final id in ids)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _BookmarkCard(id: id, isAr: isAr),
                        ),
                    ],
                  ),
          ),
          const AppBottomNavBar(),
        ],
      ),
    );
  }
}

// ─── Category colour mapping ──────────────────────────────────────────────────

({Color color, Color tint, String labelEn, String labelAr}) _category(String id) {
  if (id.startsWith('gdp_') ||
      id.startsWith('trade_') ||
      id.startsWith('tourism_') ||
      id.startsWith('prices_') ||
      id == 'aircraft_movement') {
    return (
      color: AppColors.aeGold,
      tint: AppColors.aeGoldBg,
      labelEn: 'Economy',
      labelAr: 'الاقتصاد'
    );
  }
  if (id.startsWith('ecology_') ||
      id.startsWith('energy_') ||
      id.startsWith('crop_') ||
      id.startsWith('livestock_')) {
    return (
      color: AppColors.envGreen,
      tint: AppColors.envGreenTint,
      labelEn: 'Environment',
      labelAr: 'البيئة'
    );
  }
  return (
    color: AppColors.demBlue,
    tint: AppColors.demBlueTint,
    labelEn: 'Demography',
    labelAr: 'الديموغرافيا'
  );
}

class _BookmarkCard extends ConsumerWidget {
  const _BookmarkCard({required this.id, required this.isAr});

  final String id;
  final bool isAr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(indicatorSummaryProvider(id));
    final cat = _category(id);

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(AppRoutes.indicatorPath(id)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: AppColors.shadowCard,
          ),
          clipBehavior: Clip.hardEdge,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: cat.color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: async.when(
                      loading: () => _row(
                        name: _fallbackName(),
                        cat: cat,
                        valueText: '…',
                        period: '',
                        yoy: 0,
                        showTrend: false,
                      ),
                      error: (_, __) => _row(
                        name: _fallbackName(),
                        cat: cat,
                        valueText: '—',
                        period: isAr ? 'غير متوفر' : 'Unavailable',
                        yoy: 0,
                        showTrend: false,
                      ),
                      data: (s) => _row(
                        name: isAr ? s.name.ar : s.name.en,
                        cat: cat,
                        valueText: _fmt(s),
                        period: s.latestPeriod,
                        yoy: s.yoyChange,
                        showTrend: s.sparklineValues.isNotEmpty,
                      ),
                    ),
                  ),
                ),
                // Remove button
                _RemoveButton(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await ref.read(bookmarkProvider.notifier).remove(id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fallbackName() =>
      id.replaceAll('_', ' ').replaceFirstMapped(
          RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());

  static String _fmt(IndicatorSummary s) {
    final u = s.unitCode;
    if (u == 'PERCENT' || u == 'PCT') {
      return '${s.latestValue.toStringAsFixed(1)}%';
    }
    if (u == 'MM' || u == 'MCM' || u == 'MW' || u == 'KM2') {
      return s.latestValue.toStringAsFixed(1);
    }
    return NumberFormatter.compact(s.latestValue);
  }

  Widget _row({
    required String name,
    required ({Color color, Color tint, String labelEn, String labelAr}) cat,
    required String valueText,
    required String period,
    required double yoy,
    required bool showTrend,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: cat.tint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Text(
            isAr ? cat.labelAr : cat.labelEn,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cat.color,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              valueText,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cat.color,
                height: 1,
              ),
            ),
            const Spacer(),
            if (showTrend) ...[
              TrendPill(value: yoy, compact: true),
              const SizedBox(width: 8),
            ],
            if (period.isNotEmpty)
              Text(
                period,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        alignment: Alignment.center,
        child: const Icon(Icons.bookmark_remove_outlined,
            size: 20, color: AppColors.slate400),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.aeGoldBg,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.bookmark_border_rounded,
                  size: 48, color: AppColors.aeGold),
            ),
            const SizedBox(height: 20),
            Text(
              isAr ? 'لا توجد مؤشرات محفوظة بعد' : 'No saved indicators yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'احفظ أي مؤشر بالضغط على أيقونة الإشارة المرجعية في شاشة التفاصيل.'
                  : 'Bookmark any indicator by tapping the 🔖 icon on its detail screen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aeGold,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              onPressed: () => context.go(AppRoutes.home),
              icon: const Text('Start Exploring',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              label: const Icon(Icons.arrow_forward_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
