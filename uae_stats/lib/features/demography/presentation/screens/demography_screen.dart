// lib/features/demography/presentation/screens/demography_screen.dart
//
// Demography section screen — Blue theme (#0073AB).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _kAccent    = AppColors.demBlue;
const _kAccentBg  = AppColors.demBlueTint;
const _kIcon      = Icons.people_rounded;

class DemographyScreen extends ConsumerStatefulWidget {
  const DemographyScreen({super.key});

  @override
  ConsumerState<DemographyScreen> createState() => _DemographyScreenState();
}

class _DemographyScreenState extends ConsumerState<DemographyScreen> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final locale    = ref.watch(localeProvider);
    final isArabic  = locale.languageCode == 'ar';
    final kpisAsync = ref.watch(demographyKpisProvider);

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
              onRefresh: () => ref.refresh(demographyKpisProvider.future),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _SectionHeader(
                        expanded: _expanded,
                        isArabic: isArabic,
                        onToggle: () =>
                            setState(() => _expanded = !_expanded),
                      ),
                    ),
                  ),
                  if (_expanded)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                        child: kpisAsync.when(
                          loading: () => const _SectionsSkeleton(),
                          error: (_, __) => _ErrorRetry(
                            onRetry: () =>
                                ref.invalidate(demographyKpisProvider),
                          ),
                          data: (groups) => _SectionsContent(
                            groups: groups,
                            isArabic: isArabic,
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.menu, size: 24, color: AppColors.slate600),
          const SizedBox(width: 12),
          const AppLogo(),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'الديموغرافيا' : 'Demography',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              letterSpacing: -0.34,
            ),
          ),
          const Spacer(),
          _LangToggle(isArabic: isArabic),
        ],
      ),
    );
  }
}

// ─── Language toggle ──────────────────────────────────────────────────────────

class _LangToggle extends ConsumerWidget {
  const _LangToggle({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(localeProvider.notifier).toggle();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(color: AppColors.silver),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ع',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isArabic ? _kAccent : AppColors.slate400,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 28,
              height: 16,
              decoration: BoxDecoration(
                color: _kAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    isArabic ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header card ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.expanded,
    required this.isArabic,
    required this.onToggle,
  });

  final bool expanded;
  final bool isArabic;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate400,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isArabic ? 'الديموغرافيا' : 'Demography',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Population · Vitals · Education · Health · Labour',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 22,
                color: AppColors.slate400,
              ),
            ],
          ),
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
          if (i > 0) const SizedBox(height: 14),
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
    (title: 'Population',       titleAr: 'السكان',             count: 2),
    (title: 'Vital Statistics', titleAr: 'الإحصاءات الحيوية',  count: 2),
    (title: 'Education',        titleAr: 'التعليم',            count: 2),
    (title: 'Health',           titleAr: 'الصحة',              count: 2),
    (title: 'Labour Force',     titleAr: 'القوى العاملة',      count: 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int s = 0; s < _placeholder.length; s++) ...[
          if (s > 0) const SizedBox(height: 14),
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
