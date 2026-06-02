// lib/features/indicator_detail/presentation/screens/indicator_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breadcrumb_bar.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/breakdown_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/data_table_section.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/detail_hero_card.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/indicator_chart.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ─── Indicator nav items ──────────────────────────────────────────────────────
class _NavItem {
  const _NavItem({
    required this.id,
    required this.label,
    required this.group,
  });
  final String id;
  final String label;
  final String group;
}

const _navItems = [
  // Vitals
  _NavItem(id: 'population',         label: 'Population Estimates',    group: 'vitals'),
  _NavItem(id: 'births',             label: 'Births',                  group: 'vitals'),
  _NavItem(id: 'deaths',             label: 'Deaths',                  group: 'vitals'),
  _NavItem(id: 'marriages',          label: 'Marriages',               group: 'vitals'),
  _NavItem(id: 'divorces',           label: 'Divorces',                group: 'vitals'),
  // Education
  _NavItem(id: 'student_enrolment',  label: 'Student Enrolment',       group: 'education'),
  _NavItem(id: 'teaching_staff',     label: 'Teaching Staff',          group: 'education'),
  _NavItem(id: 'higher_education',   label: 'Higher Education Students', group: 'education'),
  // Health
  _NavItem(id: 'hospitals',          label: 'Hospitals',               group: 'health'),
  _NavItem(id: 'health_clinics_centers', label: 'Clinics and Centers', group: 'health'),
  _NavItem(id: 'health_hospital_beds', label: 'Hospital Beds',         group: 'health'),
  _NavItem(id: 'health_professionals', label: 'Health Workforce',         group: 'health'),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class IndicatorDetailScreen extends ConsumerStatefulWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  ConsumerState<IndicatorDetailScreen> createState() =>
      _IndicatorDetailScreenState();
}

class _IndicatorDetailScreenState
    extends ConsumerState<IndicatorDetailScreen> {
  late String _activeId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeId = widget.indicatorId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(indicatorDataProvider(_activeId));

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ─── App bar ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: AppColors.slate900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      dataAsync.maybeWhen(
                        data: (d) => d.meta.name.en,
                        orElse: () => _labelFor(_activeId),
                      ),
                      style: const TextStyle(
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

          // ─── Flag stripe ──────────────────────────────────────────────────
          const FlagStripe(),

          // ─── Breadcrumb ───────────────────────────────────────────────────
          dataAsync.maybeWhen(
            data: (d) => BreadcrumbBar(meta: d.meta),
            orElse: () => _BreadcrumbShimmer(),
          ),

          // ─── Indicator nav strip ──────────────────────────────────────────
          _IndicatorNavStrip(
            activeId: _activeId,
            onSelect: (id) {
              _scrollToTop();
              setState(() => _activeId = id);
            },
          ),

          // ─── Scrollable body ──────────────────────────────────────────────
          Expanded(
            child: dataAsync.when(
              loading: () => const _LoadingSkeleton(),
              error: (e, _) => _ErrorView(
                onRetry: () =>
                    ref.invalidate(indicatorDataProvider(_activeId)),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.demBlue,
                child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero card
                    DetailHeroCard(data: data),

                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: IndicatorChart(
                        allSeries: data.uaeTotalSeries,
                        indicatorName: data.meta.name.en,
                        indicatorId: data.meta.id,
                        femaleSeries: data.byGender['F'] ?? [],
                        maleSeries: data.byGender['M'] ?? [],
                      ),
                    ),

                    // Stats chips row
                    const SizedBox(height: 4),
                    DataTableSection(data: data),

                    // Breakdown
                    const SizedBox(height: 10),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: BreakdownSection(data: data),
                    ),

                    // Metadata card
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _MetadataCard(data: data),
                    ),

                    // Related indicators
                    const SizedBox(height: 10),
                    _RelatedIndicators(currentId: _activeId),

                    // CTA buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.demBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              icon: const SizedBox.shrink(),
                              label: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Compare with Another Indicator',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => context.go(AppRoutes.home),
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Citation footer
                    _CitationFooter(data: data),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
              ),
            ),
          ),

          // ─── Bottom nav ───────────────────────────────────────────────────
          const AppBottomNavBar(),
        ],
      ),
    );
  }

  String _labelFor(String id) {
    return _navItems
        .firstWhere((n) => n.id == id,
            orElse: () => _NavItem(
                id: id,
                label: id[0].toUpperCase() + id.substring(1).replaceAll('_', ' '),
                group: ''))
        .label;
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(indicatorDataProvider(_activeId));
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }
}

// ─── Indicator nav strip ──────────────────────────────────────────────────────
class _IndicatorNavStrip extends StatelessWidget {
  const _IndicatorNavStrip({
    required this.activeId,
    required this.onSelect,
  });

  final String activeId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.silver, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: _navItems.map((item) {
            final active = item.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onSelect(item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.demBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? AppColors.demBlue
                          : AppColors.silver,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active) ...[
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: active
                              ? Colors.white
                              : AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Breadcrumb shimmer ───────────────────────────────────────────────────────
class _BreadcrumbShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
          ShimmerBox(width: 200, height: 12),
          Spacer(),
          ShimmerBox(width: 80, height: 12),
        ],
      ),
    );
  }
}

// ─── Metadata card ────────────────────────────────────────────────────────────
class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.data});

  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final meta = data.meta;
    final rows = <_MetaRow>[
      _MetaRow(
        key: 'Data Source',
        value: meta.sourceName.en.isNotEmpty ? meta.sourceName.en : meta.sourceCode,
      ),
      _MetaRow(
        key: 'Update Frequency',
        value: meta.frequencyLabel,
      ),
      _MetaRow(
        key: 'Source Code',
        value: meta.sourceCode,
      ),
      _MetaRow(
        key: 'Last Update',
        value: data.preparedAtForDisplay ?? data.latestPeriod,
      ),
      _MetaRow(
        key: 'Data Coverage',
        value: data.dataRange,
      ),
      _MetaRow(
        key: 'Unit',
        value: meta.unit.en,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pearlGray,
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
          ...rows.map((r) => _MetaRowWidget(row: r)),
        ],
      ),
    );
  }
}

class _MetaRow {
  const _MetaRow({required this.key, required this.value});
  final String key;
  final String value;
}

class _MetaRowWidget extends StatelessWidget {
  const _MetaRowWidget({required this.row});
  final _MetaRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x1A0073AB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.key,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate600,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.value,
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

// ─── Related indicators ───────────────────────────────────────────────────────

// Visual config only — no hardcoded statistical values.
class _RelatedConfig {
  const _RelatedConfig({
    required this.label,
    required this.iconColor,
    required this.bgColor,
  });
  final String label;
  final Color iconColor;
  final Color bgColor;
}

class _RelatedIndicators extends ConsumerWidget {
  const _RelatedIndicators({required this.currentId});

  final String currentId;

  static const _ids = ['student_enrolment', 'higher_education', 'population'];

  static const _configs = {
    'student_enrolment': _RelatedConfig(
      label: 'Student Enrolment',
      iconColor: AppColors.demBlue,
      bgColor: AppColors.demBlueTint,
    ),
    'higher_education': _RelatedConfig(
      label: 'Higher Education',
      iconColor: AppColors.champagneGold,
      bgColor: AppColors.royalSand,
    ),
    'population': _RelatedConfig(
      label: 'Total Population',
      iconColor: AppColors.teal,
      bgColor: AppColors.tealTint,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleIds = _ids.where((id) => id != currentId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Related Indicators',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: const Text(
                  'View all →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.demBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: visibleIds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final id = visibleIds[i];
              final cfg = _configs[id]!;
              final dataAsync = ref.watch(indicatorDataProvider(id));

              String value = '—';
              String trend = '—';
              bool trendUp = true;

              dataAsync.whenData((data) {
                final series = data.uaeTotalSeries;
                if (series.isNotEmpty) {
                  value = NumberFormatter.compact(data.latestValue);
                  if (series.length >= 2) {
                    final prev = series[series.length - 2].value;
                    if (prev != 0) {
                      final yoy =
                          (data.latestValue - prev) / prev * 100;
                      trendUp = yoy >= 0;
                      final arrow = trendUp ? '↑ +' : '↓ ';
                      trend =
                          '$arrow${yoy.abs().toStringAsFixed(1)}% vs '
                          '${series[series.length - 2].timePeriod}';
                    }
                  }
                }
              });

              return GestureDetector(
                onTap: () =>
                    context.push(AppRoutes.indicatorPath(id)),
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: AppColors.shadowCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cfg.bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.people_rounded,
                          size: 20,
                          color: cfg.iconColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cfg.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trendUp
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Citation footer ──────────────────────────────────────────────────────────
class _CitationFooter extends StatelessWidget {
  const _CitationFooter({required this.data});

  final dynamic data;

  static String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m];

  @override
  Widget build(BuildContext context) {
    final dataYear = data.latestPeriod as String;
    final fetched = data.fetchedAt as DateTime;
    final retrievedStr = '${_monthName(fetched.month)} ${fetched.year}';
    final citation =
        "Federal Competitiveness and Statistics Authority (FCSA), "
        "'${data.meta.name.en} in the UAE — $dataYear', "
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
          // Hero shimmer
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.aeGoldDeep.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          // Chart shimmer
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
          const SizedBox(height: 20),
          const ShimmerBox(width: double.infinity, height: 80),
          const SizedBox(height: 16),
          const ShimmerBox(width: double.infinity, height: 200),
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.slate400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
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
