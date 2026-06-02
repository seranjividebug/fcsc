// lib/features/search/presentation/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/providers/indicator_providers.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

// ─── All searchable indicators ────────────────────────────────────────────────

class _SearchEntry {
  const _SearchEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
  });
  final String id;
  final String name;
  final String category;
  final String subCategory;
}

const _allEntries = [
  // Demography
  _SearchEntry(id: 'population',           name: 'Population Estimates',         category: 'Demography', subCategory: 'Population'),
  _SearchEntry(id: 'births',               name: 'Births',                        category: 'Demography', subCategory: 'Vitals'),
  _SearchEntry(id: 'deaths',               name: 'Deaths',                        category: 'Demography', subCategory: 'Vitals'),
  _SearchEntry(id: 'marriages',            name: 'Marriages',                     category: 'Demography', subCategory: 'Vitals'),
  _SearchEntry(id: 'divorces',             name: 'Divorces',                      category: 'Demography', subCategory: 'Vitals'),
  _SearchEntry(id: 'student_enrolment',    name: 'Student Enrolment',             category: 'Demography', subCategory: 'Education'),
  _SearchEntry(id: 'teaching_staff',       name: 'Teaching Staff',                category: 'Demography', subCategory: 'Education'),
  _SearchEntry(id: 'higher_education',     name: 'Higher Education Students',     category: 'Demography', subCategory: 'Education'),
  _SearchEntry(id: 'hospitals',            name: 'Hospitals',                     category: 'Demography', subCategory: 'Health'),
  _SearchEntry(id: 'health_clinics_centers', name: 'Clinics and Centers',         category: 'Demography', subCategory: 'Health'),
  _SearchEntry(id: 'health_hospital_beds', name: 'Hospital Beds',                 category: 'Demography', subCategory: 'Health'),
  _SearchEntry(id: 'health_professionals', name: 'Health Workforce',              category: 'Demography', subCategory: 'Health'),
  _SearchEntry(id: 'labour_economic_activity',       name: 'Economic Activity',           category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_employed_age_gender',     name: 'Employed by Age & Gender',    category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_employed_education',      name: 'Employed by Education Status',category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_employment_sector',       name: 'Employment by Sector',        category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_unemployment_education',  name: 'Unemployment by Education',   category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_workforce_occupation',    name: 'Workforce by Occupation',     category: 'Demography', subCategory: 'Labour'),
  _SearchEntry(id: 'labour_unemployment_age_gender', name: 'Unemployment by Age & Gender',category: 'Demography', subCategory: 'Labour'),
  // Economy
  _SearchEntry(id: 'gdp_current',            name: 'GDP (Current Prices)',        category: 'Economy', subCategory: 'National Accounts'),
  _SearchEntry(id: 'gdp_constant',           name: 'GDP (Constant Prices)',       category: 'Economy', subCategory: 'National Accounts'),
  _SearchEntry(id: 'gdp_quarterly_current',  name: 'Quarterly GDP (Current)',     category: 'Economy', subCategory: 'National Accounts'),
  _SearchEntry(id: 'gdp_quarterly_constant', name: 'Quarterly GDP (Constant)',    category: 'Economy', subCategory: 'National Accounts'),
  _SearchEntry(id: 'trade_total',            name: 'Total Trade',                 category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'trade_imports_hs',       name: 'Imports by HS Section',       category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'trade_non_oil_exports',  name: 'Non-Oil Exports',             category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'trade_sector_country',   name: 'Sector & Country',            category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'trade_reexports_annual', name: 'Annual Re-Exports',           category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'trade_reexports_monthly',name: 'Monthly Re-Exports',          category: 'Economy', subCategory: 'International Trade'),
  _SearchEntry(id: 'prices_cpi_annual',      name: 'CPI Annual',                  category: 'Economy', subCategory: 'Prices'),
  _SearchEntry(id: 'tourism_hotel_arrivals',       name: 'Hotel Guest Arrivals by Nationality', category: 'Economy', subCategory: 'Tourism'),
  _SearchEntry(id: 'tourism_hotel_establishments', name: 'Hotel Establishments',  category: 'Economy', subCategory: 'Tourism'),
  _SearchEntry(id: 'tourism_main_indicators',      name: 'Main Indicators',       category: 'Economy', subCategory: 'Tourism'),
];

const _trendingIds = ['population', 'gdp_current', 'prices_cpi_annual', 'births'];

const _suggestions = [
  'Population Estimates', 'GDP', 'Inflation', 'Energy', 'Education',
  'Births', 'Deaths', 'Hospitals', 'Tourism', 'Trade',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  String _filterCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(() => setState(() => _query = _controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_SearchEntry> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _allEntries.where((e) {
      final matchesQuery = e.name.toLowerCase().contains(q) ||
          e.category.toLowerCase().contains(q) ||
          e.subCategory.toLowerCase().contains(q);
      final matchesFilter = _filterCategory == 'All' ||
          e.category == _filterCategory;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isArabic),
            Expanded(
              child: _query.isEmpty
                  ? _buildInitialState(isArabic)
                  : _buildResultsState(isArabic),
            ),
          ],
        ),
      ),
    );
  }

  // ─── App bar with search field ───────────────────────────────────────────

  Widget _buildAppBar(bool isArabic) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: const Color(0xFF0F172A),
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
                  const Icon(Icons.search_rounded, size: 18,
                      color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: isArabic
                            ? 'ابحث عن المؤشرات والموضوعات…'
                            : 'Search any indicator or topic…',
                        hintStyle: const TextStyle(
                            fontSize: 14, color: Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () => _controller.clear(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.close_rounded, size: 18,
                            color: Color(0xFF9CA3AF)),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.mic_none_rounded, size: 18,
                          color: Color(0xFF00594C)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.go(AppRoutes.home),
            child: const Text('Cancel',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00594C))),
          ),
        ],
      ),
    );
  }

  // ─── Initial state ───────────────────────────────────────────────────────

  Widget _buildInitialState(bool isArabic) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Recent searches
        _sectionHeader('Recent', 'Clear all'),
        ...[
          'GDP Current Prices',
          'Population Estimates 2024',
          'Renewable Energy',
          'CPI Inflation 2024',
        ].map((item) => _recentRow(item)),

        // Trending
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔥 Trending This Week',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              const Text('Most searched indicators',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _trendingIds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (_, i) {
                    final entry = _allEntries.firstWhere(
                        (e) => e.id == _trendingIds[i],
                        orElse: () => _allEntries.first);
                    return _trendingCard(entry, i + 1);
                  },
                ),
              ),
            ],
          ),
        ),

        // Browse by category
        const SizedBox(height: 20),
        _sectionHeader('Browse by Category', null),
        _categoryRow('Demography', '🧑‍🤝‍🧑', const Color(0xFFE8F1EE),
            const Color(0xFF00594C)),
        _categoryRow('Economy', '📈', const Color(0xFFF5E9D3),
            const Color(0xFF7A5A1A)),
        _categoryRow('Environment', '🌿', const Color(0xFFE0F4F1),
            const Color(0xFF0F6E56)),

        // Quick facts
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF00594C),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUICK FACT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        letterSpacing: 0.8, color: Color(0xAAFFFFFF))),
                const SizedBox(height: 7),
                const Text(
                    "The UAE's GDP grew 3.4% in 2024 — outpacing the GCC average for the fifth consecutive year.",
                    style: TextStyle(fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w500, height: 1.55)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Container(
                    width: i == 0 ? 12 : 4, height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Results state ───────────────────────────────────────────────────────

  Widget _buildResultsState(bool isArabic) {
    final results = _results;

    if (results.isEmpty) return _buildNoResults();

    return Column(
      children: [
        // Header + filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Text('${results.length} results for \'$_query\'',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A))),
              const Spacer(),
              const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF4B5563)),
              const SizedBox(width: 4),
              const Text('Filters',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            ],
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: ['All', 'Demography', 'Economy', 'Environment'].map((f) {
              final active = _filterCategory == f;
              return GestureDetector(
                onTap: () => setState(() => _filterCategory = f),
                child: Container(
                  margin: const EdgeInsets.only(right: 7),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF00594C)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF00594C)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    f + (f == 'All' ? ' ▾' : ''),
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Results
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            itemCount: results.length,
            itemBuilder: (_, i) => _resultCard(results[i]),
          ),
        ),
      ],
    );
  }

  // ─── No results ──────────────────────────────────────────────────────────

  Widget _buildNoResults() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1EE),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.search_off_rounded, size: 40,
                  color: Color(0xFF00594C)),
            ),
            const SizedBox(height: 20),
            Text("No results for '$_query'",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text(
                "We couldn't find any indicators matching your search. Check your spelling or try a related term.",
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
              children: _suggestions.take(6).map((s) => GestureDetector(
                onTap: () => _controller.text = s,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(s,
                      style: const TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF003D33))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00594C)),
                  foregroundColor: const Color(0xFF00594C),
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

  // ─── Helper widgets ──────────────────────────────────────────────────────

  Widget _sectionHeader(String title, String? action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
          const Spacer(),
          if (action != null)
            Text(action,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: Color(0xFF00594C))),
        ],
      ),
    );
  }

  Widget _recentRow(String text) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, size: 17,
              color: Color(0xFF9CA3AF)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 14,
                    color: Color(0xFF0F172A))),
          ),
          const Icon(Icons.close_rounded, size: 15,
              color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _trendingCard(_SearchEntry entry, int rank) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(entry.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 2),
              Text(entry.category,
                  style: const TextStyle(fontSize: 10,
                      color: Color(0xFF6B7280))),
            ],
          ),
          Positioned(
            top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E9D3),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('#$rank',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF7A5A1A))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(String name, String emoji, Color bg, Color color) {
    return Container(
      height: 60, margin: const EdgeInsets.fromLTRB(18, 0, 18, 7),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: bg,
                borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A))),
          ),
          const Icon(Icons.chevron_right_rounded, size: 17,
              color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _resultCard(_SearchEntry entry) {
    final dataAsync = ref.watch(indicatorSummaryProvider(entry.id));
    String value = '—';
    String trend = '';
    bool trendUp = true;

    dataAsync.whenData((summary) {
      if (summary.latestValue != 0) {
        value = NumberFormatter.compact(summary.latestValue);
        trendUp = summary.yoyChange >= 0;
        if (summary.yoyChange.abs() > 0.05) {
          trend = '${trendUp ? '↑' : '↓'} ${summary.yoyChange.abs().toStringAsFixed(1)}%';
        }
      }
    });

    final isEconomy = entry.category == 'Economy';
    final iconBg = isEconomy
        ? const Color(0xFFF5E9D3)
        : entry.category == 'Environment'
            ? const Color(0xFFE0F4F1)
            : const Color(0xFFE8F1EE);
    final iconColor = isEconomy
        ? const Color(0xFF7A5A1A)
        : entry.category == 'Environment'
            ? const Color(0xFF0F6E56)
            : const Color(0xFF00594C);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.indicatorPath(entry.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(9)),
                  child: Icon(Icons.bar_chart_rounded, size: 17,
                      color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.category} · ${entry.subCategory}',
                        style: const TextStyle(fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 2),
                      Text(entry.name,
                          style: const TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(value,
                        style: const TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    if (trend.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
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
                ),
              ],
            ),
            const SizedBox(height: 9),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 7),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Source: FCSA',
                    style: TextStyle(fontSize: 10,
                        color: Color(0xFF9CA3AF))),
                Icon(Icons.chevron_right_rounded, size: 14,
                    color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
