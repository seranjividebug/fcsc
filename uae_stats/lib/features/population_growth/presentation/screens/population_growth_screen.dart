// lib/features/population_growth/presentation/screens/population_growth_screen.dart
//
// Population Growth Details page.
// All data is derived dynamically from the population API (DF_POP / 'population').
// No hardcoded statistics — every value, chart, and table auto-updates when the
// API data changes.

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/hero_action_buttons.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class PopulationGrowthScreen extends ConsumerStatefulWidget {
  const PopulationGrowthScreen({super.key});

  @override
  ConsumerState<PopulationGrowthScreen> createState() =>
      _PopulationGrowthScreenState();
}

class _PopulationGrowthScreenState
    extends ConsumerState<PopulationGrowthScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(indicatorDataProvider('population'));
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(indicatorDataProvider('population'));

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ─── App bar ────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.demography);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.slate900,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Population Growth',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const LanguageToggleButton(),
                ],
              ),
            ),
          ),

          // ─── Flag stripe ─────────────────────────────────────────────────
          const FlagStripe(),

          // ─── Breadcrumb ──────────────────────────────────────────────────
          _BreadcrumbBar(),

          // ─── Action toolbar ──────────────────────────────────────────────
          _ActionToolbar(data: dataAsync.valueOrNull),

          // ─── Scrollable body ─────────────────────────────────────────────
          Expanded(
            child: dataAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorView(
                onRetry: () =>
                    ref.invalidate(indicatorDataProvider('population')),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.demBlue,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  child: _GrowthBody(data: data),
                ),
              ),
            ),
          ),

          // ─── Bottom nav ──────────────────────────────────────────────────
          const AppBottomNavBar(),
        ],
      ),
    );
  }
}

// ─── Breadcrumb ───────────────────────────────────────────────────────────────

class _BreadcrumbBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.pearlGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => context.go(AppRoutes.demography),
                  child: const Text(
                    'Demography',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.demBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.demography),
                  child: const Text(
                    'Population',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.demBlue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Text('›',
                      style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                ),
                const Flexible(
                  child: Text(
                    'Population Growth',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Source: FCSA',
            style: TextStyle(fontSize: 11, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}

// ─── Action toolbar ───────────────────────────────────────────────────────────

class _ActionToolbar extends StatelessWidget {
  const _ActionToolbar({required this.data});
  final IndicatorData? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _ToolbarButton(
            icon: Icons.bookmark_border_rounded,
            label: 'Bookmark',
            onTap: () {},
          ),
          const SizedBox(width: 20),
          _ToolbarButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: () {
              if (data != null) {
                final text =
                    'Population Growth in UAE — ${data!.latestPeriod}: '
                    '${_computeGrowthPercent(data!).toStringAsFixed(2)}%\n'
                    'Source: FCSA / uaestat.fcsa.gov.ae';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppColors.slate900,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 20),
          _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Download',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  double _computeGrowthPercent(IndicatorData data) {
    final series = data.uaeTotalSeries;
    if (series.length < 2) return 0;
    final prev = series[series.length - 2].value;
    if (prev == 0) return 0;
    return (series.last.value - prev) / prev * 100;
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.slate600),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Growth body ──────────────────────────────────────────────────────────────

class _GrowthBody extends StatelessWidget {
  const _GrowthBody({required this.data});
  final IndicatorData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero summary ──────────────────────────────────────────────────
        _GrowthHeroCard(data: data),

        const SizedBox(height: 16),

        // ── KPI cards: Total / Male / Female growth ───────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GrowthKpiCards(data: data),
        ),

        const SizedBox(height: 20),

        // ── Population Growth Over Time chart ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _PopulationGrowthChart(data: data),
        ),

        const SizedBox(height: 20),

        // ── Gender Distribution Trend chart ───────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GenderTrendChart(data: data),
        ),

        const SizedBox(height: 20),

        // ── YoY Growth Rate chart ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _YoyGrowthChart(data: data),
        ),

        const SizedBox(height: 20),

        // ── Historical growth table ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _GrowthHistoryTable(data: data),
        ),

        const SizedBox(height: 20),

        // ── Metadata card ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _MetadataCard(data: data),
        ),

        // ── CTA buttons ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      context.push(AppRoutes.indicatorPath('population')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.demBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Population Estimates',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.demography),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.demBlue,
                    side: const BorderSide(
                      color: AppColors.demBlue,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'View All Demography Indicators',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Citation footer ───────────────────────────────────────────────
        _CitationFooter(data: data),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _GrowthHeroCard extends StatefulWidget {
  const _GrowthHeroCard({required this.data});
  final IndicatorData data;

  @override
  State<_GrowthHeroCard> createState() => _GrowthHeroCardState();
}

class _GrowthHeroCardState extends State<_GrowthHeroCard> {
  double get _growthPct {
    final s = widget.data.uaeTotalSeries;
    if (s.length < 2) return 0;
    final prev = s[s.length - 2].value;
    if (prev == 0) return 0;
    return (s.last.value - prev) / prev * 100;
  }

  String get _periodLabel {
    final s = widget.data.uaeTotalSeries;
    if (s.length < 2) return widget.data.latestPeriod;
    return '${s[s.length - 2].timePeriod} – ${s.last.timePeriod}';
  }

  String get _prevGrowthPct {
    final s = widget.data.uaeTotalSeries;
    if (s.length < 3) return '';
    final prev2 = s[s.length - 3].value;
    final prev1 = s[s.length - 2].value;
    if (prev2 == 0) return '';
    final pct = (prev1 - prev2) / prev2 * 100;
    return '${pct.toStringAsFixed(2)}%';
  }

  String get _prevPeriodLabel {
    final s = widget.data.uaeTotalSeries;
    if (s.length < 3) return '';
    return '(${s[s.length - 3].timePeriod} – ${s[s.length - 2].timePeriod})';
  }

  /// Dataset updated label — latest data year (coverage end period).
  String _datasetUpdatedDisplay() => widget.data.dataEnd;

  @override
  Widget build(BuildContext context) {
    final growth = _growthPct;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.demBlue, AppColors.aeGoldDeep],
          ),
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        constraints: const BoxConstraints(minHeight: 200),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            const Positioned(
              top: -10,
              right: -10,
              child: Opacity(
                opacity: 0.06,
                child: CustomPaint(
                  size: Size(220, 220),
                  painter: _GeoPainter(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'DEMOGRAPHY · POPULATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Updated ${_datasetUpdatedDisplay()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Population Growth Rate',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Animated growth value
                  TweenAnimationBuilder<double>(
                    key: ValueKey(growth),
                    tween: Tween(begin: 0, end: growth),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${val.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 58,
                          color: AppColors.white,
                          letterSpacing: -1.45,
                          fontFeatures: [FontFeature.tabularFigures()],
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 14),
                    child: Text(
                      'annual growth rate · $_periodLabel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_prevGrowthPct.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _prevGrowthPct,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _prevPeriodLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      HeroActionButtons(
                        indicatorName: widget.data.meta.name.en,
                        data: widget.data,
                      ),
                    ],
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

// ─── KPI summary cards ────────────────────────────────────────────────────────

class _GrowthKpiCards extends StatelessWidget {
  const _GrowthKpiCards({required this.data});
  final IndicatorData data;

  // Returns growth % between last two data points for a given series.
  static double _growthOf(List<DataPoint> series) {
    if (series.length < 2) return 0;
    final prev = series[series.length - 2].value;
    if (prev == 0) return 0;
    return (series.last.value - prev) / prev * 100;
  }

  static String _periodOf(List<DataPoint> series) {
    if (series.length < 2) return '';
    return '${series[series.length - 2].timePeriod} – ${series.last.timePeriod}';
  }

  static String _prevGrowthOf(List<DataPoint> series) {
    if (series.length < 3) return '';
    final prev2 = series[series.length - 3].value;
    final prev1 = series[series.length - 2].value;
    if (prev2 == 0) return '';
    final pct = (prev1 - prev2) / prev2 * 100;
    return '${pct.toStringAsFixed(2)}%';
  }

  static String _prevPeriodOf(List<DataPoint> series) {
    if (series.length < 3) return '';
    return '${series[series.length - 3].timePeriod} – ${series[series.length - 2].timePeriod}';
  }

  @override
  Widget build(BuildContext context) {
    final total = data.uaeTotalSeries;
    final male = data.byGender['M'] ?? [];
    final female = data.byGender['F'] ?? [];

    final totalGrowth = _growthOf(total);
    final maleGrowth = _growthOf(male);
    final femaleGrowth = _growthOf(female);

    return Column(
      children: [
        // Total population growth — full width
        _GrowthKpiCard(
          icon: Icons.people_rounded,
          title: 'Total Population',
          period: _periodOf(total),
          growth: totalGrowth,
          prevGrowth: _prevGrowthOf(total),
          prevPeriod: _prevPeriodOf(total),
          wide: true,
        ),
        const SizedBox(height: 10),
        // Male + Female — 2-col
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GrowthKpiCard(
                icon: Icons.male_rounded,
                title: 'Male',
                period: _periodOf(male),
                growth: maleGrowth,
                prevGrowth: _prevGrowthOf(male),
                prevPeriod: _prevPeriodOf(male),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GrowthKpiCard(
                icon: Icons.female_rounded,
                title: 'Female',
                period: _periodOf(female),
                growth: femaleGrowth,
                prevGrowth: _prevGrowthOf(female),
                prevPeriod: _prevPeriodOf(female),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GrowthKpiCard extends StatelessWidget {
  const _GrowthKpiCard({
    required this.icon,
    required this.title,
    required this.period,
    required this.growth,
    required this.prevGrowth,
    required this.prevPeriod,
    this.wide = false,
  });

  final IconData icon;
  final String title;
  final String period;
  final double growth;
  final String prevGrowth;
  final String prevPeriod;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: wide
          ? _WideLayout(
              icon: icon,
              title: title,
              period: period,
              growth: growth,
              prevGrowth: prevGrowth,
              prevPeriod: prevPeriod,
            )
          : _NarrowLayout(
              icon: icon,
              title: title,
              period: period,
              growth: growth,
              prevGrowth: prevGrowth,
              prevPeriod: prevPeriod,
            ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.icon,
    required this.title,
    required this.period,
    required this.growth,
    required this.prevGrowth,
    required this.prevPeriod,
  });
  final IconData icon;
  final String title;
  final String period;
  final double growth;
  final String prevGrowth;
  final String prevPeriod;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.demBlueTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.demBlue),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900)),
              if (period.isNotEmpty)
                Text(period,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate400)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${growth.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.demBlue,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (prevGrowth.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                prevGrowth,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                prevPeriod,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.slate400),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.icon,
    required this.title,
    required this.period,
    required this.growth,
    required this.prevGrowth,
    required this.prevPeriod,
  });
  final IconData icon;
  final String title;
  final String period;
  final double growth;
  final String prevGrowth;
  final String prevPeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.demBlueTint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.demBlue),
        ),
        const SizedBox(height: 10),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900)),
        if (period.isNotEmpty)
          Text(period,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${growth.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.demBlue,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (prevGrowth.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            prevGrowth,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            prevPeriod,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.slate400),
          ),
        ],
      ],
    );
  }
}

// ─── Population Growth Over Time chart (absolute population) ─────────────────

class _PopulationGrowthChart extends StatefulWidget {
  const _PopulationGrowthChart({required this.data});
  final IndicatorData data;

  @override
  State<_PopulationGrowthChart> createState() =>
      _PopulationGrowthChartState();
}

class _PopulationGrowthChartState extends State<_PopulationGrowthChart> {
  _ChartRange _range = _ChartRange.y10;

  List<DataPoint> get _series {
    final all = widget.data.uaeTotalSeries;
    final n = _range.years;
    if (n == null || all.length <= n) return all;
    return all.sublist(all.length - n);
  }

  @override
  Widget build(BuildContext context) {
    final series = _series;

    return _ChartCard(
      title: 'Population Growth Over Time (Persons)',
      subLabel: series.isNotEmpty
          ? '${series.first.timePeriod} – ${series.last.timePeriod} · Source: FCSA'
          : '',
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      child: _buildChart(series),
    );
  }

  Widget _buildChart(List<DataPoint> series) {
    if (series.isEmpty) return const _EmptyChart();

    final spots = series
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final minY = series.map((p) => p.value).reduce(min);
    final maxY = series.map((p) => p.value).reduce(max);
    final pad = (maxY - minY) * 0.12;

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.demBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.demBlue.withValues(alpha: 0.20),
                    AppColors.demBlue.withValues(alpha: 0.0),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.demBlue,
                  strokeWidth: 2,
                  strokeColor: AppColors.white,
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.pearlGray, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: _buildTitles(series),
          lineTouchData: _buildLineTouchData(series),
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }

  FlTitlesData _buildTitles(List<DataPoint> series) => FlTitlesData(
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 56,
            getTitlesWidget: (val, meta) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                NumberFormatter.compact(val),
                style:
                    const TextStyle(fontSize: 10, color: AppColors.slate400),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (val, meta) {
              final idx = val.round();
              if (idx < 0 || idx >= series.length) {
                return const SizedBox.shrink();
              }
              // Show every other label if crowded
              if (series.length > 8 && idx % 2 != 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  series[idx].timePeriod,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.slate400),
                ),
              );
            },
          ),
        ),
      );

  LineTouchData _buildLineTouchData(List<DataPoint> series) =>
      LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.white,
          tooltipRoundedRadius: 12,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          tooltipBorder:
              const BorderSide(color: AppColors.silver, width: 1),
          getTooltipItems: (spots) => spots.map((spot) {
            final idx = spot.x.round();
            if (idx < 0 || idx >= series.length) return null;
            final pt = series[idx];
            String deltaLine = '';
            if (idx > 0) {
              final prev = series[idx - 1];
              if (prev.value != 0) {
                final delta =
                    ((pt.value - prev.value) / prev.value) * 100;
                deltaLine =
                    '\n${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}% vs ${prev.timePeriod}';
              }
            }
            return LineTooltipItem(
              pt.timePeriod,
              const TextStyle(
                color: AppColors.slate400,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: '\n${NumberFormatter.full(pt.value)}',
                  style: const TextStyle(
                    color: AppColors.slate900,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (deltaLine.isNotEmpty)
                  TextSpan(
                    text: deltaLine,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      );
}

// ─── Gender distribution trend chart ─────────────────────────────────────────

class _GenderTrendChart extends StatefulWidget {
  const _GenderTrendChart({required this.data});
  final IndicatorData data;

  @override
  State<_GenderTrendChart> createState() => _GenderTrendChartState();
}

class _GenderTrendChartState extends State<_GenderTrendChart> {
  _ChartRange _range = _ChartRange.y10;

  List<DataPoint> _rangeSeries(List<DataPoint> all) {
    final n = _range.years;
    if (n == null || all.length <= n) return all;
    return all.sublist(all.length - n);
  }

  @override
  Widget build(BuildContext context) {
    final maleAll = widget.data.byGender['M'] ?? [];
    final femaleAll = widget.data.byGender['F'] ?? [];

    final male = _rangeSeries(maleAll);
    final female = _rangeSeries(femaleAll);

    // Compute gender ratio (males per 100 females) for the ranged series
    // Align by timePeriod
    final ratioSeries = <_RatioPoint>[];
    for (final m in male) {
      final f = female.where((p) => p.timePeriod == m.timePeriod).toList();
      if (f.isNotEmpty && f.first.value > 0) {
        ratioSeries.add(_RatioPoint(
          period: m.timePeriod,
          ratio: m.value / f.first.value * 100,
        ));
      }
    }

    final subLabel = male.isNotEmpty && female.isNotEmpty
        ? '${male.first.timePeriod} – ${male.last.timePeriod} · Males per 100 Females'
        : '';

    return _ChartCard(
      title: 'Gender Distribution Over the Years',
      subLabel: subLabel,
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      child: _buildRatioChart(ratioSeries),
    );
  }

  Widget _buildRatioChart(List<_RatioPoint> pts) {
    if (pts.isEmpty) return const _EmptyChart();

    final spots = pts
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.ratio))
        .toList();

    final minY = pts.map((p) => p.ratio).reduce(min);
    final maxY = pts.map((p) => p.ratio).reduce(max);
    final pad = (maxY - minY) * 0.15;

    return SizedBox(
      height: 210,
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.teal,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.teal.withValues(alpha: 0.18),
                    AppColors.teal.withValues(alpha: 0.0),
                  ],
                ),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.teal,
                  strokeWidth: 2,
                  strokeColor: AppColors.white,
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.pearlGray, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (val, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    val.toStringAsFixed(0),
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.slate400),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.round();
                  if (idx < 0 || idx >= pts.length) {
                    return const SizedBox.shrink();
                  }
                  if (pts.length > 8 && idx % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      pts[idx].period,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.slate400),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.white,
              tooltipRoundedRadius: 12,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              tooltipBorder:
                  const BorderSide(color: AppColors.silver, width: 1),
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.x.round();
                if (idx < 0 || idx >= pts.length) return null;
                final pt = pts[idx];
                return LineTooltipItem(
                  pt.period,
                  const TextStyle(
                    color: AppColors.slate400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: '\n${pt.ratio.toStringAsFixed(2)} males/100 females',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }
}

class _RatioPoint {
  const _RatioPoint({required this.period, required this.ratio});
  final String period;
  final double ratio;
}

// ─── YoY growth rate bar chart ────────────────────────────────────────────────

class _YoyGrowthChart extends StatefulWidget {
  const _YoyGrowthChart({required this.data});
  final IndicatorData data;

  @override
  State<_YoyGrowthChart> createState() => _YoyGrowthChartState();
}

class _YoyGrowthChartState extends State<_YoyGrowthChart> {
  _ChartRange _range = _ChartRange.y10;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.uaeTotalSeries;
    final male = widget.data.byGender['M'] ?? [];
    final female = widget.data.byGender['F'] ?? [];

    List<DataPoint> sliceRange(List<DataPoint> all) {
      final n = _range.years;
      if (n == null || all.length <= n) return all;
      return all.sublist(all.length - n);
    }

    final ts = sliceRange(total);
    final ms = sliceRange(male);
    final fs = sliceRange(female);

    // Build YoY rate points
    final pts = <_GrowthRatePoint>[];
    for (int i = 1; i < ts.length; i++) {
      final prev = ts[i - 1].value;
      if (prev == 0) continue;
      final totalRate = (ts[i].value - prev) / prev * 100;

      double? maleRate;
      double? femaleRate;

      final mPt =
          ms.where((p) => p.timePeriod == ts[i].timePeriod).toList();
      final mPrev =
          ms.where((p) => p.timePeriod == ts[i - 1].timePeriod).toList();
      if (mPt.isNotEmpty && mPrev.isNotEmpty && mPrev.first.value != 0) {
        maleRate = (mPt.first.value - mPrev.first.value) /
            mPrev.first.value *
            100;
      }

      final fPt =
          fs.where((p) => p.timePeriod == ts[i].timePeriod).toList();
      final fPrev =
          fs.where((p) => p.timePeriod == ts[i - 1].timePeriod).toList();
      if (fPt.isNotEmpty && fPrev.isNotEmpty && fPrev.first.value != 0) {
        femaleRate = (fPt.first.value - fPrev.first.value) /
            fPrev.first.value *
            100;
      }

      pts.add(_GrowthRatePoint(
        period: ts[i].timePeriod,
        total: totalRate,
        male: maleRate,
        female: femaleRate,
      ));
    }

    final subLabel = pts.isNotEmpty
        ? '${pts.first.period} – ${pts.last.period} · Annual Growth Rate (%)'
        : '';

    return _ChartCard(
      title: 'Year-over-Year Growth Comparison',
      subLabel: subLabel,
      range: _range,
      onRangeChanged: (r) => setState(() => _range = r),
      child: _buildGroupedBar(pts),
    );
  }

  Widget _buildGroupedBar(List<_GrowthRatePoint> pts) {
    if (pts.isEmpty) return const _EmptyChart();

    final allRates = [
      ...pts.map((p) => p.total),
      ...pts.where((p) => p.male != null).map((p) => p.male!),
      ...pts.where((p) => p.female != null).map((p) => p.female!),
    ];
    final maxY = allRates.reduce(max);
    final minY = allRates.reduce(min);
    final absMax = max(maxY.abs(), minY.abs());
    final barW = _barWidth(pts.length);

    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          maxY: absMax * 1.25,
          minY: minY < 0 ? -(absMax * 0.1) : 0,
          barGroups: pts.asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            final rods = <BarChartRodData>[
              BarChartRodData(
                toY: pt.total,
                color: AppColors.demBlue.withValues(alpha: 0.85),
                width: barW,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ];
            if (pt.male != null) {
              rods.add(BarChartRodData(
                toY: pt.male!,
                color: AppColors.teal.withValues(alpha: 0.8),
                width: barW,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ));
            }
            if (pt.female != null) {
              rods.add(BarChartRodData(
                toY: pt.female!,
                color: AppColors.champagneGold.withValues(alpha: 0.85),
                width: barW,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ));
            }
            return BarChartGroupData(x: idx, barRods: rods, barsSpace: 2);
          }).toList(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.pearlGray, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (val, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${val.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 9, color: AppColors.slate400),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (val, meta) {
                  final idx = val.round();
                  if (idx < 0 || idx >= pts.length) {
                    return const SizedBox.shrink();
                  }
                  if (pts.length > 8 && idx % 2 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      pts[idx].period,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.slate400),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.white,
              tooltipRoundedRadius: 12,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              tooltipBorder:
                  const BorderSide(color: AppColors.silver, width: 1),
              getTooltipItem: (group, groupIdx, rod, rodIdx) {
                final pt = pts[group.x];
                final labels = ['Total', 'Male', 'Female'];
                final label =
                    rodIdx < labels.length ? labels[rodIdx] : '';
                return BarTooltipItem(
                  '${pt.period} · $label\n',
                  const TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(2)}%',
                      style: const TextStyle(
                        color: AppColors.slate900,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }

  double _barWidth(int count) {
    if (count <= 4) return 18;
    if (count <= 6) return 12;
    if (count <= 8) return 9;
    return 7;
  }
}

class _GrowthRatePoint {
  const _GrowthRatePoint({
    required this.period,
    required this.total,
    this.male,
    this.female,
  });
  final String period;
  final double total;
  final double? male;
  final double? female;
}

// ─── Historical growth table ──────────────────────────────────────────────────

class _GrowthHistoryTable extends StatelessWidget {
  const _GrowthHistoryTable({required this.data});
  final IndicatorData data;

  @override
  Widget build(BuildContext context) {
    final total = data.uaeTotalSeries;
    final male = data.byGender['M'] ?? [];
    final female = data.byGender['F'] ?? [];

    // Build rows newest-first
    final rows = <_GrowthRow>[];
    for (int i = total.length - 1; i >= 1; i--) {
      final curr = total[i];
      final prev = total[i - 1];
      final totalGrowth = prev.value != 0
          ? (curr.value - prev.value) / prev.value * 100
          : null;

      final mCurr =
          male.where((p) => p.timePeriod == curr.timePeriod).toList();
      final mPrev =
          male.where((p) => p.timePeriod == prev.timePeriod).toList();
      final maleGrowth = (mCurr.isNotEmpty &&
              mPrev.isNotEmpty &&
              mPrev.first.value != 0)
          ? (mCurr.first.value - mPrev.first.value) /
              mPrev.first.value *
              100
          : null;

      final fCurr =
          female.where((p) => p.timePeriod == curr.timePeriod).toList();
      final fPrev =
          female.where((p) => p.timePeriod == prev.timePeriod).toList();
      final femaleGrowth = (fCurr.isNotEmpty &&
              fPrev.isNotEmpty &&
              fPrev.first.value != 0)
          ? (fCurr.first.value - fPrev.first.value) /
              fPrev.first.value *
              100
          : null;

      rows.add(_GrowthRow(
        period: '${prev.timePeriod}–${curr.timePeriod}',
        population: curr.value,
        totalGrowth: totalGrowth,
        maleGrowth: maleGrowth,
        femaleGrowth: femaleGrowth,
      ));

      if (rows.length >= 15) break; // cap table to 15 rows
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historical Growth Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width - 40,
            ),
            child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: AppColors.shadowCard,
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.pearlGray,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('PERIOD',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: AppColors.slate600)),
                    ),
                    SizedBox(
                      width: 110,
                      child: Text('POPULATION',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: AppColors.slate600)),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: Text('TOTAL',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: AppColors.slate600)),
                    ),
                    SizedBox(width: 4),
                    SizedBox(
                      width: 48,
                      child: Text('MALE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: AppColors.slate600)),
                    ),
                    SizedBox(width: 4),
                    SizedBox(
                      width: 48,
                      child: Text('FEMALE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.44,
                              color: AppColors.slate600)),
                    ),
                  ],
                ),
              ),
              // Data rows
              ...rows.asMap().entries.map((e) {
                final idx = e.key;
                final row = e.value;
                return Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: idx.isOdd ? AppColors.offWhite : AppColors.white,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          row.period,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: Text(
                          NumberFormatter.full(row.population),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 56,
                        child: Center(
                            child: _GrowthBadge(value: row.totalGrowth)),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 48,
                        child: Center(
                            child: _GrowthBadge(value: row.maleGrowth)),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 48,
                        child: Center(
                            child: _GrowthBadge(value: row.femaleGrowth)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
          ),
        ),
      ],
    );
  }
}

class _GrowthRow {
  const _GrowthRow({
    required this.period,
    required this.population,
    required this.totalGrowth,
    required this.maleGrowth,
    required this.femaleGrowth,
  });
  final String period;
  final double population;
  final double? totalGrowth;
  final double? maleGrowth;
  final double? femaleGrowth;
}

class _GrowthBadge extends StatelessWidget {
  const _GrowthBadge({required this.value});
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const Text('—',
          style: TextStyle(fontSize: 11, color: AppColors.slate400));
    }
    final up = value! >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: up ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${up ? '↑' : '↓'} ${value!.abs().toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: up ? const Color(0xFF065F46) : const Color(0xFF991B1B),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ─── Shared chart card container ──────────────────────────────────────────────

enum _ChartRange { y2, y5, y10, max }

extension _ChartRangeExt on _ChartRange {
  String get label => switch (this) {
        _ChartRange.y2 => '2Y',
        _ChartRange.y5 => '5Y',
        _ChartRange.y10 => '10Y',
        _ChartRange.max => 'MAX',
      };

  int? get years => switch (this) {
        _ChartRange.y2 => 2,
        _ChartRange.y5 => 5,
        _ChartRange.y10 => 10,
        _ChartRange.max => null,
      };
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subLabel,
    required this.range,
    required this.onRangeChanged,
    required this.child,
  });

  final String title;
  final String subLabel;
  final _ChartRange range;
  final ValueChanged<_ChartRange> onRangeChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          if (subLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subLabel,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.slate400)),
          ],
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 12),
          _RangeChips(selected: range, onChanged: onRangeChanged),
        ],
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips(
      {required this.selected, required this.onChanged});
  final _ChartRange selected;
  final ValueChanged<_ChartRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _ChartRange.values.map((r) {
        final active = r == selected;
        return GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.demBlue
                  : AppColors.pearlGray,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              r.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.white : AppColors.slate600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Metadata card ────────────────────────────────────────────────────────────

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.data});
  final IndicatorData data;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = data.meta.sourceName.en.isNotEmpty
        ? data.meta.sourceName.en
        : 'Federal Competitiveness and Statistics Authority (FCSA)';
    final freqLabel = data.meta.frequencyLabel;
    final rows = [
      ('Data Source', sourceLabel),
      ('Update Frequency', freqLabel),
      (
        'Last Update',
        data.preparedAtForDisplay ?? data.latestPeriod
      ),
      ('Data Coverage', data.dataRange),
      ('Unit', data.meta.unit.en),
      ('Source Code', data.meta.sourceCode),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.demBlueTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Indicator',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.map((r) => _MetaRow(label: r.$1, value: r.$2)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x1A0073AB), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.slate600, height: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.slate900,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Citation footer ──────────────────────────────────────────────────────────

class _CitationFooter extends StatelessWidget {
  const _CitationFooter({required this.data});
  final IndicatorData data;

  static String _monthName(int m) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][m];

  @override
  Widget build(BuildContext context) {
    final dataYear = data.latestPeriod;
    final fetched = data.fetchedAt;
    final retrievedStr = '${_monthName(fetched.month)} ${fetched.year}';
    final citation =
        "Federal Competitiveness and Statistics Authority (FCSA), "
        "'Population Growth Rate in the UAE — $dataYear', "
        "Retrieved $retrievedStr from uaestat.fcsa.gov.ae";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            citation,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate400,
              fontStyle: FontStyle.italic,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: citation));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Citation copied to clipboard'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.slate900,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded,
                    size: 13, color: AppColors.demBlue),
                SizedBox(width: 4),
                Text(
                  'Copy Citation',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.demBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading skeleton ─────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.demBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 80),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: ShimmerBox(width: double.infinity, height: 80)),
              SizedBox(width: 10),
              Expanded(child: ShimmerBox(width: double.infinity, height: 80)),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.demBlue,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 280),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.slate400),
            const SizedBox(height: 16),
            const Text(
              'Could not load data',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check your connection and try again.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.demBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty chart ──────────────────────────────────────────────────────────────

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppColors.slate400, fontSize: 14),
        ),
      ),
    );
  }
}

// ─── Islamic geo pattern painter (reused from detail_hero_card.dart) ──────────

class _GeoPainter extends CustomPainter {
  const _GeoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final thick = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..strokeCap = StrokeCap.round;
    final veryThin = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    const cell = 44.0;
    for (double ox = 0; ox < size.width + cell; ox += cell) {
      for (double oy = 0; oy < size.height + cell; oy += cell) {
        _drawCell(canvas, thick, thin, veryThin, ox, oy, cell);
      }
    }
  }

  void _drawCell(Canvas c, Paint thick, Paint thin, Paint veryThin,
      double ox, double oy, double sz) {
    final cx = ox + sz / 2;
    final cy = oy + sz / 2;
    final r = sz / 2;
    _hex(c, thick, cx, cy, r * 0.91, r * 0.91);
    _hex(c, veryThin, cx, cy, r * 0.59, r * 0.59);
    c.drawLine(Offset(cx, oy), Offset(cx, oy + sz), thin);
    c.drawLine(Offset(ox + r * 0.18, oy + r * 0.5),
        Offset(ox + sz - r * 0.18, oy + r * 1.5), thin);
    c.drawLine(Offset(ox + sz - r * 0.18, oy + r * 0.5),
        Offset(ox + r * 0.18, oy + r * 1.5), thin);
    c.drawCircle(Offset(cx, cy), r * 0.11, veryThin);
  }

  void _hex(Canvas c, Paint p, double cx, double cy, double rx, double ry) {
    const sides = 6;
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final a = (i * 2 * pi / sides) - pi / 2;
      final x = cx + rx * cos(a);
      final y = cy + ry * sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
