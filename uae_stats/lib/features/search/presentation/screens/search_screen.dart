// lib/features/search/presentation/screens/search_screen.dart
//
// Fully dynamic search screen.
// - Recent searches: persisted in SharedPreferences, per-item dismissal + clear all
// - Real-time filtering: debounced 200 ms, searches across all IndicatorMeta from
//   indicators_index.json (English + Arabic names, category, subCategory)
// - Trending: derived from per-indicator view counts stored in SharedPreferences;
//   falls back to a curated default list on first launch
// - Browse by Category: derived from allMetaProvider — no hardcoded categories
// - Result navigation records a view count increment for trending

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_meta.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/data/providers/search_providers.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/shimmer_box.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────

const _kBg        = Color(0xFFFAFBFC);
const _kWhite     = AppColors.white;
const _kBorder    = Color(0xFFE5E7EB);
const _kSlate900  = Color(0xFF0F172A);
const _kSlate600  = Color(0xFF4B5563);
const _kSlate400  = Color(0xFF9CA3AF);
const _kGold      = Color(0xFF7A5A1A);
const _kGoldBg    = Color(0xFFF5E9D3);
// Page UI-chrome accent (search header, filter chips, empty-state, buttons).
// Gold theme to match the rest of the app's primary accent.
const _kAccent    = _kGold;
const _kAccentBg  = _kGoldBg;
const _kEnvBg     = Color(0xFFE0F4F1);
const _kEnvColor  = Color(0xFF0F6E56);
// Demography — blue theme (matches AppColors.demBlue / demBlueTint).
const _kDemBlue   = Color(0xFF0073AB);
const _kDemBlueBg = Color(0xFFEFFAFF);

// Category config
class _CatConfig {
  const _CatConfig(this.emoji, this.bg, this.color);
  final String emoji;
  final Color bg, color;
}

const _catConfigs = <String, _CatConfig>{
  'demography':   _CatConfig('👥', _kDemBlueBg, _kDemBlue),
  'economy':      _CatConfig('📈', _kGoldBg,  _kGold),
  'environment':  _CatConfig('🌿', _kEnvBg,   _kEnvColor),
};

_CatConfig _catConfig(String cat) =>
    _catConfigs[cat.toLowerCase()] ??
    const _CatConfig('📊', Color(0xFFF3F5F7), _kSlate600);

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ─── Screen ───────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Start every search session fresh: reset the category filter to 'All' and
    // clear any leftover query so a previous selection never persists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      ref.read(searchCategoryProvider.notifier).state = 'All';
      ref.read(searchQueryProvider.notifier).state = '';
    });
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state = _controller.text;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateTo(IndicatorMeta meta) {
    // Record view for trending
    ref.read(searchHistoryServiceProvider).incrementView(meta.id);
    // Persist search term
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(q);
    }
    context.push(AppRoutes.indicatorPath(meta.id));
  }

  void _applyRecent(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: term.length));
    ref.read(searchQueryProvider.notifier).state = term;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final query    = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(
              controller: _controller,
              focusNode:  _focusNode,
              isArabic:   isArabic,
              onClear:    () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).state = '';
                ref.read(searchCategoryProvider.notifier).state = 'All';
              },
              onCancel:   () => context.go(AppRoutes.home),
            ),
            Expanded(
              child: query.isEmpty
                  ? _InitialState(onRecentTap: _applyRecent)
                  : _ResultsState(onTap: _navigateTo),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.controller,
    required this.focusNode,
    required this.isArabic,
    required this.onClear,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isArabic;
  final VoidCallback onClear, onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _kSlate900,
          ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 11),
                  const Icon(Icons.search_rounded, size: 18, color: _kSlate400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller,
                      builder: (_, v, __) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        style: const TextStyle(fontSize: 14, color: _kSlate900),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: isArabic
                              ? 'ابحث عن المؤشرات والموضوعات…'
                              : 'Search any indicator or topic…',
                          hintStyle: const TextStyle(
                              fontSize: 14, color: _kSlate400),
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, v, __) => v.text.isNotEmpty
                        ? GestureDetector(
                            onTap: onClear,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.close_rounded,
                                  size: 18, color: _kSlate400),
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(Icons.mic_none_rounded,
                                size: 18, color: _kAccent),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onCancel,
            child: const Text('Cancel',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: _kAccent)),
          ),
        ],
      ),
    );
  }
}

// ─── Initial state (no query) ─────────────────────────────────────────────────

class _InitialState extends ConsumerWidget {
  const _InitialState({required this.onRecentTap});
  final ValueChanged<String> onRecentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history  = ref.watch(searchHistoryProvider);
    final trending = ref.watch(trendingIdsProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Recent searches ──────────────────────────────────────────────
        if (history.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent',
            action: 'Clear all',
            onAction: () => ref.read(searchHistoryProvider.notifier).clearAll(),
          ),
          ...history.map((term) => _RecentRow(
                term: term,
                onTap: () => onRecentTap(term),
                onRemove: () =>
                    ref.read(searchHistoryProvider.notifier).remove(term),
              )),
        ],

        // ── Trending This Week ───────────────────────────────────────────
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔥 Trending This Week',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _kSlate900)),
              const SizedBox(height: 2),
              const Text('Most viewed indicators',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: trending.when(
                  loading: () => _TrendingSkeletonRow(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (ids) => _TrendingRow(ids: ids),
                ),
              ),
            ],
          ),
        ),

        // ── Browse by Category ───────────────────────────────────────────
        const SizedBox(height: 20),
        const _SectionHeader(title: 'Browse by Category'),
        const SizedBox(height: 4),
        _BrowseCategoryGrid(),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Trending row ─────────────────────────────────────────────────────────────

class _TrendingRow extends ConsumerWidget {
  const _TrendingRow({required this.ids});
  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMeta = ref.watch(allMetaProvider);

    return allMeta.when(
      loading: () => _TrendingSkeletonRow(),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final metaMap = {for (final m in all) m.id: m};
        final cards = ids
            .where((id) => metaMap.containsKey(id))
            .take(6)
            .toList();

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (ctx, i) {
            final meta = metaMap[cards[i]]!;
            final cfg  = _catConfig(meta.category);
            return GestureDetector(
              onTap: () {
                ref.read(searchHistoryServiceProvider).incrementView(meta.id);
                ctx.push(AppRoutes.indicatorPath(meta.id));
              },
              child: _TrendingCard(meta: meta, rank: i + 1, cfg: cfg),
            );
          },
        );
      },
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.meta,
    required this.rank,
    required this.cfg,
  });
  final IndicatorMeta meta;
  final int rank;
  final _CatConfig cfg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Right padding reserves space for the rank badge so the title
              // never renders underneath it (overlap fix).
              Padding(
                padding: const EdgeInsets.only(right: 26),
                child: Text(
                  meta.name.en,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: _kSlate900),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _capitalize(meta.category),
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cfg.bg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('#$rank',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: cfg.color)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingSkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (_, __) => Container(
        width: 148,
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        padding: const EdgeInsets.all(11),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            ShimmerBox(width: 110, height: 12),
            SizedBox(height: 6),
            ShimmerBox(width: 70, height: 10),
          ],
        ),
      ),
    );
  }
}

// ─── Results state ────────────────────────────────────────────────────────────

class _ResultsState extends ConsumerWidget {
  const _ResultsState({required this.onTap});
  final ValueChanged<IndicatorMeta> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query        = ref.watch(searchQueryProvider);
    final category     = ref.watch(searchCategoryProvider);
    final categories   = ref.watch(categoriesProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: _kSlate400)),
      ),
      data: (results) {
        if (results.isEmpty) return _NoResults(query: query);

        final cats = categories.valueOrNull ?? [];
        final allFilters = ['All', ...cats];

        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${results.length} result${results.length == 1 ? '' : 's'} for '$query'",
                      style: const TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600, color: _kSlate900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.tune_rounded, size: 16, color: _kSlate600),
                  const SizedBox(width: 4),
                  const Text('Filter',
                      style: TextStyle(fontSize: 13, color: _kSlate600)),
                ],
              ),
            ),
            // Category filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: allFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final f      = allFilters[i];
                  final active = category == f;
                  return GestureDetector(
                    onTap: () => ref
                        .read(searchCategoryProvider.notifier)
                        .state = f,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? _kAccent : _kWhite,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: active ? _kAccent : _kBorder),
                      ),
                      child: Text(
                        f == 'All' ? 'All ▾' : _capitalize(f),
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : _kSlate600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Result list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: results.length,
                itemBuilder: (_, i) => _ResultCard(
                  meta: results[i],
                  onTap: () => onTap(results[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Result card ──────────────────────────────────────────────────────────────

class _ResultCard extends ConsumerWidget {
  const _ResultCard({required this.meta, required this.onTap});
  final IndicatorMeta meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic   = ref.watch(localeProvider).languageCode == 'ar';
    final dataAsync  = ref.watch(indicatorSummaryProvider(meta.id));
    final cfg        = _catConfig(meta.category);

    String value = '—';
    String trend  = '';
    bool   trendUp = true;
    String year   = meta.coverageEnd;

    dataAsync.whenData((summary) {
      if (summary.latestValue != 0) {
        value  = NumberFormatter.compact(summary.latestValue);
        year   = summary.latestPeriod;
        trendUp = summary.yoyChange >= 0;
        if (summary.yoyChange.abs() > 0.05) {
          trend = '${trendUp ? '↑' : '↓'} ${summary.yoyChange.abs().toStringAsFixed(1)}%';
        }
      }
    });

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: cfg.bg,
                      borderRadius: BorderRadius.circular(9)),
                  child: Center(
                    child: Text(cfg.emoji,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + breadcrumb
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_capitalize(meta.category)} · ${_capitalize(meta.subCategory)}',
                        style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6, color: _kSlate400),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic ? meta.name.ar : meta.name.en,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w600, color: _kSlate900),
                      ),
                    ],
                  ),
                ),
                // Value + trend
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: _kSlate900)),
                    if (trend.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: trendUp
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(trend,
                            style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: trendUp
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            )),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${meta.frequencyLabel} · ${meta.sourceCode} · $year',
                    style: const TextStyle(fontSize: 10, color: _kSlate400),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 14, color: _kSlate400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No results ───────────────────────────────────────────────────────────────

class _NoResults extends ConsumerWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMeta = ref.watch(allMetaProvider);
    // Pick 6 random suggestions from available indicators
    final suggestions = allMeta.valueOrNull
            ?.take(6)
            .map((m) => m.name.en)
            .toList() ??
        ['Population', 'GDP', 'Inflation', 'Energy', 'Education', 'Births'];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                  color: _kAccentBg,
                  borderRadius: BorderRadius.circular(40)),
              child: const Icon(Icons.search_off_rounded,
                  size: 40, color: _kAccent),
            ),
            const SizedBox(height: 20),
            Text("No results for '$query'",
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: _kSlate900)),
            const SizedBox(height: 8),
            const Text(
                "We couldn't find any indicators matching your search. "
                "Check your spelling or try a related term.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280),
                    height: 1.55)),
            const SizedBox(height: 22),
            const Text('Try one of these:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7, runSpacing: 7,
              alignment: WrapAlignment.center,
              children: suggestions.map((s) => GestureDetector(
                onTap: () =>
                    ref.read(searchQueryProvider.notifier).state = s,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kAccentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(s,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kGold)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kAccent),
                  foregroundColor: _kAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Browse by Category',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
    this.onAction,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w600, color: _kSlate900)),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w500, color: _kAccent)),
            ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });
  final String term;
  final VoidCallback onTap, onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 17, color: _kSlate400),
            const SizedBox(width: 11),
            Expanded(
              child: Text(term,
                  style: const TextStyle(
                      fontSize: 14, color: _kSlate900),
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Icon(Icons.close_rounded,
                    size: 15, color: _kSlate400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Browse by category — always shows all 3 sections ────────────────────────

class _BrowseCategoryGrid extends StatelessWidget {
  static const _items = [
    _CatItem(
      label: 'Demography',
      labelAr: 'الديموغرافيا',
      subtitle: 'Population · Vitals · Education · Health · Labour',
      subtitleAr: 'السكان · الأحوال الحيوية · التعليم · الصحة · العمل',
      icon: Icons.people_rounded,
      bg: _kDemBlueBg,
      color: _kDemBlue,
      route: AppRoutes.demography,
    ),
    _CatItem(
      label: 'Economy',
      labelAr: 'الاقتصاد',
      subtitle: 'GDP · Trade · Prices · Tourism · Transport',
      subtitleAr: 'الناتج المحلي · التجارة · الأسعار · السياحة',
      icon: Icons.trending_up_rounded,
      bg: _kGoldBg,
      color: _kGold,
      route: AppRoutes.economy,
    ),
    _CatItem(
      label: 'Environment',
      labelAr: 'البيئة',
      subtitle: 'Agriculture · Energy · Climate · Resources',
      subtitleAr: 'الزراعة · الطاقة · المناخ · الموارد',
      icon: Icons.eco_rounded,
      bg: _kEnvBg,
      color: _kEnvColor,
      route: AppRoutes.environment,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _items.map((item) => _CatCard(item: item)).toList(),
      ),
    );
  }
}

class _CatItem {
  const _CatItem({
    required this.label,
    required this.labelAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.icon,
    required this.bg,
    required this.color,
    required this.route,
  });
  final String label, labelAr, subtitle, subtitleAr, route;
  final IconData icon;
  final Color bg, color;
}

class _CatCard extends ConsumerStatefulWidget {
  const _CatCard({required this.item});
  final _CatItem item;

  @override
  ConsumerState<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends ConsumerState<_CatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final item = widget.item;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => context.push(item.route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pressed ? item.bg : _kWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed ? item.color.withValues(alpha: 0.4) : _kBorder,
            width: _pressed ? 1.5 : 0.8,
          ),
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, size: 24, color: item.color),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? item.labelAr : item.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kSlate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isArabic ? item.subtitleAr : item.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kSlate400,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 16, color: item.color),
            ),
          ],
        ),
      ),
    );
  }
}
