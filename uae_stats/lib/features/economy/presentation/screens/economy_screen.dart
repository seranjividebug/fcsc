// lib/features/economy/presentation/screens/economy_screen.dart
//
// Economy section screen — light theme, champagneGold accent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/data/models/kpi_card_data.dart';
import 'package:uae_stats/data/providers/section_kpi_providers.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/app_logo.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/kpi_stat_card.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';

const _kAccent   = AppColors.champagneGold;
const _kAccentBg = AppColors.royalSand;
const _kIcon     = Icons.business_rounded;

class EconomyScreen extends ConsumerStatefulWidget {
  const EconomyScreen({super.key});

  @override
  ConsumerState<EconomyScreen> createState() => _EconomyScreenState();
}

class _EconomyScreenState extends ConsumerState<EconomyScreen> {
  @override
  Widget build(BuildContext context) {
    final locale    = ref.watch(localeProvider);
    final isArabic  = locale.languageCode == 'ar';
    final kpisAsync = ref.watch(economyKpisProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _AppBar(isArabic: isArabic),
          ),
          const FlagStripe(),
          Expanded(
            child: RefreshIndicator(
              color: _kAccent,
              backgroundColor: AppColors.white,
              onRefresh: () => ref.refresh(economyKpisProvider.future),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _SectionHeader(isArabic: isArabic),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                      child: kpisAsync.when(
                        loading: () => const _SectionsSkeleton(),
                        error: (_, __) => _ErrorRetry(
                          onRetry: () =>
                              ref.invalidate(economyKpisProvider),
                        ),
                        data: (groups) => _SectionsContent(
                          groups: groups,
                          isArabic: isArabic,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              ),
            ),
          ),
          const AppBottomNavBar(),
        ],
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _AppBar extends ConsumerWidget {
  const _AppBar({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppSpacing.appBarHeight,
      color: AppColors.white,
      // 4px right padding aligns the language toggle with every other screen.
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, 4, 0),
      child: Row(
        children: [
          const Icon(Icons.menu, size: 24, color: AppColors.slate600),
          const SizedBox(width: 12),
          const AppLogo(),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'الاقتصاد' : 'Economy',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              letterSpacing: -0.34,
            ),
          ),
          const Spacer(),
          const LanguageToggleButton(foregroundColor: AppColors.slate600),
        ],
      ),
    );
  }
}

// ─── Section header card ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    // Static, non-collapsible category header — purely a contextual label.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kAccentBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(_kIcon, size: 20, color: _kAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'الفئة' : 'Category',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isArabic ? 'الاقتصاد' : 'Economy',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArabic
                        ? 'الناتج المحلي · التجارة · الأسعار · السياحة · النقل الجوي'
                        : 'GDP · Trade · Prices · Tourism · Air Transport',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sections content ─────────────────────────────────────────────────────────

class _SectionsContent extends StatelessWidget {
  const _SectionsContent({
    required this.groups,
    required this.isArabic,
  });

  final List<KpiSectionGroup> groups;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < groups.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          KpiSectionTitle(
            titleEn: groups[i].titleEn,
            titleAr: groups[i].titleAr,
            isArabic: isArabic,
          ),
          KpiCardGrid(
            cards: groups[i].cards,
            accentColor: _kAccent,
            accentBg: _kAccentBg,
            isArabic: isArabic,
          ),
        ],
      ],
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _SectionsSkeleton extends StatelessWidget {
  const _SectionsSkeleton();

  static const _placeholder = [
    (title: 'National Accounts',   titleAr: 'الحسابات القومية',   count: 2),
    (title: 'International Trade', titleAr: 'التجارة الدولية',     count: 4),
    (title: 'Prices',              titleAr: 'الأسعار',             count: 1),
    (title: 'Tourism',             titleAr: 'السياحة',             count: 2),
    (title: 'Air Transport',       titleAr: 'النقل الجوي',         count: 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int s = 0; s < _placeholder.length; s++) ...[
          if (s > 0) const SizedBox(height: 24),
          KpiSectionTitle(
            titleEn: _placeholder[s].title,
            titleAr: _placeholder[s].titleAr,
          ),
          KpiCardGrid(
            accentColor: _kAccent,
            accentBg: _kAccentBg,
            cards: List.generate(
              _placeholder[s].count,
              (_) => const KpiCardData(
                id: 'loading',
                nameEn: '',
                nameAr: '',
                displayValue: '—',
                unitEn: '',
                unitAr: '',
                year: '',
                isLoading: true,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: AppColors.slate300),
          const SizedBox(height: 12),
          const Text(
            'Unable to load data',
            style: TextStyle(color: AppColors.slate600, fontSize: 15),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style:
                  TextStyle(color: _kAccent, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
