// lib/features/indicator_detail/presentation/widgets/data_table_section.dart
//
// Stats summary chips row (5Y Min / Max / Avg / Growth) + full data table.
// Section: padding 20px sides, gap between chips 10px.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/features/indicator_detail/presentation/widgets/sector_distribution_table.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

/// Scroll behavior that suppresses the native scrollbar for custom carousels
/// (the KPI chip row uses its own arrow control). Prevents the faint grey
/// vertical scrollbar line on web/desktop.
class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

class DataTableSection extends ConsumerWidget {
  const DataTableSection({super.key, required this.data});
  final IndicatorData data;

  bool get _hasGender =>
      data.byGender.containsKey('M') && data.byGender.containsKey('F');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats chips (sector Total/Govt/Private + 5Y stats, one row) ──
        _StatsChipsRow(data: data, isAr: isAr),

        // ── Data table section ─────────────────────────────────────────
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              isAr ? 'البيانات التفصيلية' : 'Detailed Data',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.slate900,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: (data.isRainfall ||
                  data.isProducedWater ||
                  data.isDecimalCount)
              // Decimal-valued national trend (mm / MCM / MW / km²).
              ? _FullDataTable(
                  series: data.uaeTotalSeries,
                  isAr: isAr,
                  isDecimal: true,
                  unitLabel: isAr ? data.meta.unit.ar : data.meta.unit.en,
                )
              : data.isLivestock
              // Livestock head counts by gender (Female / Male / Total).
              ? _GenderDataTable(
                  total: data.uaeTotalSeries,
                  male: data.livestockGenderSeries('M'),
                  female: data.livestockGenderSeries('F'),
                  isAr: isAr,
                )
              : data.isEmploymentSector
                  // Per-sector distribution: each sector's latest vs prior
                  // year Total share with YoY change (matches the source table).
                  ? SectorDistributionTable(data: data, isAr: isAr)
              : data.meta.id == 'labour_unemployment_education'
                  // Per-education-level distribution with Total / Male / Female.
                  ? CategoryGenderTable(
                      data: data,
                      isAr: isAr,
                      headerLabel: isAr ? 'المستوى التعليمي' : 'EDUCATION LEVEL',
                    )
              : data.meta.id == 'labour_workforce_occupation'
                  // Per-occupation distribution: %2024 / Vs 2023 / ΔPP.
                  ? OccupationDistributionTable(data: data, isAr: isAr)
                  : (data.isEconomicActivity ||
                          data.isTopCategoryShare ||
                          data.meta.id == 'labour_unemployment_age_gender')
                      // % distribution — show the headline-category trend
                      // (top occupation / education, or Youth 15–34 share).
                      ? _FullDataTable(
                          series: data.uaeTotalSeries,
                          isAr: isAr,
                          isPercent: true)
                  : _hasGender
                      ? _GenderDataTable(
                          total: data.uaeTotalSeries,
                          male: data.byGender['M']!,
                          female: data.byGender['F']!,
                          isAr: isAr,
                        )
                      : _FullDataTable(
                          series: data.uaeTotalSeries,
                          isAr: isAr,
                          unitLabel: isAr ? data.meta.unit.ar : data.meta.unit.en,
                        ),
        ),
      ],
    );
  }
}

// ─── Stats chips row ──────────────────────────────────────────────────────────

class _StatsChipsRow extends StatefulWidget {
  const _StatsChipsRow({required this.data, required this.isAr});
  final IndicatorData data;
  final bool isAr;

  @override
  State<_StatsChipsRow> createState() => _StatsChipsRowState();
}

class _StatsChipsRowState extends State<_StatsChipsRow> {
  final ScrollController _controller = ScrollController();
  bool _canScrollRight = false;

  IndicatorData get data => widget.data;
  bool get isAr => widget.isAr;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final right = _controller.offset < _controller.position.maxScrollExtent - 1;
    if (right != _canScrollRight) setState(() => _canScrollRight = right);
  }

  void _scrollRight() {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + 220)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  // Use 3Y slice when ≤3 data points available, else 5Y
  static int _sliceN(List<DataPoint> series) =>
      series.length <= 3 ? 3 : 5;

  @override
  Widget build(BuildContext context) {
    final series = data.uaeTotalSeries;
    final n = _sliceN(series);
    final slice = series.length > n ? series.sublist(series.length - n) : series;
    final vals = slice.map((p) => p.value).toList();
    final label = '${n}Y';
    final pct = data.isEmployedEducation ||
        data.isEmploymentSector ||
        data.isTopCategoryShare ||
        data.meta.id == 'labour_unemployment_age_gender'; // share → format %
    final dec = data.isRainfall ||
        data.isProducedWater ||
        data.isDecimalCount; // mm / MCM / MW / km² → 1 decimal
    String fmtVal(double v) => pct
        ? '${v.toStringAsFixed(1)}%'
        : dec
            ? v.toStringAsFixed(1)
            : NumberFormatter.compact(v);

    double min = 0, max = 0, avg = 0, growth = 0;
    String minYear = '', maxYear = '';

    if (vals.isNotEmpty) {
      min = vals.reduce((a, b) => a < b ? a : b);
      max = vals.reduce((a, b) => a > b ? a : b);
      avg = vals.reduce((a, b) => a + b) / vals.length;
      if (vals.first != 0) {
        growth = ((vals.last - vals.first) / vals.first) * 100;
      }
      minYear = slice[vals.indexOf(min)].timePeriod;
      maxYear = slice[vals.indexOf(max)].timePeriod;
    }

    // Leading sector chips (Total / Government / Private) for health-facility
    // indicators — shown on the SAME single horizontal line as the 5Y stats.
    final chips = <Widget>[
      // Domain-specific summary cards (GDP / Trade / Aircraft) lead the row,
      // ahead of the generic 5Y Min/Max/Avg/Growth stats.
      ..._gdpSummaryChips(),
      ..._aircraftChips(),
      ..._sectorChips(),
      ..._ageSummaryChips(),
      ..._unemploymentAgeChips(),
      ..._educationSummaryChips(),
      ..._employmentSectorChips(),
      ..._unemploymentEduChips(),
      ..._occupationChips(),
      _StatChip(
        overline: isAr ? 'أدنى $label' : '$label MIN',
        value: fmtVal(min),
        caption: minYear,
      ),
      _StatChip(
        overline: isAr ? 'أعلى $label' : '$label MAX',
        value: fmtVal(max),
        caption: maxYear,
      ),
      _StatChip(
        overline: isAr ? 'متوسط $label' : '$label AVG',
        value: fmtVal(avg),
        caption: isAr ? 'سنوي' : 'annual',
      ),
      _StatChip(
        overline: isAr ? 'نمو $label' : '$label GROWTH',
        value: NumberFormatter.percent(growth),
        caption: isAr ? 'إجمالي' : 'total',
        valueColor: growth < 0 ? AppColors.error : AppColors.success,
      ),
    ];

    return SizedBox(
      height: 110,
      child: Stack(
        children: [
          // Hide the native scrollbar — this carousel has its own arrow control.
          // The default web/desktop scrollbar shows as a faint grey vertical
          // line on the right edge while scrolling.
          ScrollConfiguration(
            behavior: const _NoScrollbarBehavior(),
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              itemCount: chips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => chips[i],
            ),
          ),
          // Right-edge carousel arrow (floats over the cards; no grey fade
          // band). Shown only while there is more content to scroll to.
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_canScrollRight,
              child: AnimatedOpacity(
                opacity: _canScrollRight ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _scrollRight,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppColors.shadowCard,
                        ),
                        child: const Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Health-facility Total / Government / Private chips (empty for others).
  static const _healthFacilityIds = {
    'hospitals', 'health_clinics_centers', 'health_hospital_beds',
  };

  // Employed-by-Age summary chips (Dominant Age / Female Peak / Youth / Senior)
  // — shown on the stats row, above Detailed Data, for that indicator only.
  String _ageLbl(String code) {
    final c = code.toUpperCase();
    final ge = RegExp(r'GE_?(\d+)').firstMatch(c);
    if (ge != null) return '${ge.group(1)}+';
    final r = RegExp(r'(\d+)[T\-_](\d+)').firstMatch(c);
    if (r != null) return '${r.group(1)}–${r.group(2)}';
    return code;
  }

  List<Widget> _ageSummaryChips() {
    if (data.meta.id != 'labour_employed_age_gender') return const [];
    final byAge = data.byAge;
    if (byAge.isEmpty) return const [];

    String domLabel = '';
    double domVal = 0;
    byAge.forEach((code, series) {
      if (series.isEmpty) return;
      final v = series.last.value;
      if (v > domVal) { domVal = v; domLabel = _ageLbl(code); }
    });

    // Female peak from byAgeGender ("F|AGECODE").
    String femLabel = '';
    double femVal = 0;
    data.byAgeGender.forEach((key, series) {
      if (series.isEmpty) return;
      final parts = key.split('|');
      if (parts.length < 2 || parts[0].toUpperCase() != 'F') return;
      final v = series.last.value;
      if (v > femVal) { femVal = v; femLabel = _ageLbl(parts[1]); }
    });

    double bandSum(List<String> codes) {
      var t = 0.0;
      for (final c in codes) {
        final s = byAge[c];
        if (s != null && s.isNotEmpty) t += s.last.value;
      }
      return t;
    }
    final youth = bandSum(['Y15T19', 'Y20T24']);
    final senior = bandSum(['Y60T64', 'Y_GE65']);
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'الفئة الأكبر' : 'DOMINANT AGE',
        value: pct(domVal),
        caption: domLabel,
      ),
      _StatChip(
        overline: isAr ? 'ذروة الإناث' : 'FEMALE PEAK',
        value: pct(femVal),
        caption: femLabel,
      ),
      _StatChip(
        overline: isAr ? 'حصة الشباب' : 'YOUTH SHARE',
        value: pct(youth),
        caption: isAr ? '15–24 سنة' : '15–24 yrs',
      ),
      _StatChip(
        overline: isAr ? 'حصة كبار السن' : 'SENIOR SHARE',
        value: pct(senior),
        caption: isAr ? '60+ سنة' : '60+ yrs',
      ),
    ];
  }

  // Insight cards for Unemployment by Age & Gender — computed from the latest
  // year: Peak Group (highest Total band), Female Peak, Male Peak, and the
  // combined 55+ share (55–59 + 60–64 + 65+, raw sum).
  List<Widget> _unemploymentAgeChips() {
    if (data.meta.id != 'labour_unemployment_age_gender') return const [];
    final byAge = data.byAge;
    if (byAge.isEmpty) return const [];

    String peakLabel = '';
    double peakVal = -1;
    byAge.forEach((code, series) {
      if (series.isEmpty) return;
      final v = series.last.value;
      if (v > peakVal) { peakVal = v; peakLabel = _ageLbl(code); }
    });

    String genderPeak(String g) {
      String lbl = '';
      double best = -1;
      data.byAgeGender.forEach((key, series) {
        if (series.isEmpty) return;
        final parts = key.split('|');
        if (parts.length < 2 || parts[0].toUpperCase() != g) return;
        final v = series.last.value;
        if (v > best) { best = v; lbl = _ageLbl(parts[1]); }
      });
      return '$best|$lbl';
    }
    final mParts = genderPeak('M').split('|');
    final fParts = genderPeak('F').split('|');
    final mVal = double.tryParse(mParts.first) ?? 0;
    final fVal = double.tryParse(fParts.first) ?? 0;

    double bandSum(List<String> codes) {
      var t = 0.0;
      for (final c in codes) {
        final s = byAge[c];
        if (s != null && s.isNotEmpty) t += s.last.value;
      }
      return t;
    }
    final over55 = bandSum(['Y55T59', 'Y60T64', 'Y_GE65']);
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'الفئة الأكبر' : 'PEAK GROUP',
        value: peakLabel,
        caption: isAr ? 'حصة ${pct(peakVal)}' : '${pct(peakVal)} share',
      ),
      _StatChip(
        overline: isAr ? 'ذروة الإناث' : 'FEMALE PEAK',
        value: pct(fVal),
        caption: isAr ? 'الفئة ${fParts.last}' : 'Age ${fParts.last}',
      ),
      _StatChip(
        overline: isAr ? 'ذروة الذكور' : 'MALE PEAK',
        value: pct(mVal),
        caption: isAr ? 'الفئة ${mParts.last}' : 'Age ${mParts.last}',
      ),
      _StatChip(
        overline: isAr ? 'حصة +55' : '55+ SHARE',
        value: pct(over55),
        caption: isAr ? 'خطر منخفض' : 'low risk',
        valueColor: AppColors.success,
      ),
    ];
  }

  // Education-level short labels for the insight chips (Labour Force by
  // Educational Status). Mirrors the breakdown section's level names.
  static const _eduLevelLabels = <String, String>{
    'ILLIT': 'Illiterate', 'RANDW': 'Reads & Writes', 'PRI': 'Primary',
    'LSEC': 'Lower Secondary', 'SEC': 'Secondary',
    'PSNT': 'Post-Secondary', 'SCTE': 'Short-Cycle Tertiary',
    'BACH': 'Bachelor', 'HDIP': 'Higher Diploma',
    'MAST': 'Master', 'DOCT': 'Doctoral', 'NO_STA': 'Not Stated',
  };

  // Insight cards for the education distribution: highest / lowest level,
  // higher-education share (Bachelor+Master+Doctoral) and basic-education
  // share (Primary + Lower Secondary), plus vocational (Short-Cycle Tertiary)
  // when present. Values come from the latest year's gender-Total breakdown
  // and update automatically with the dataset.
  List<Widget> _educationSummaryChips() {
    if (data.meta.id != 'labour_employed_education') return const [];
    final byLevel = data.byLevel;
    if (byLevel.isEmpty) return const [];

    // Latest value per level code (gender-Total series), skipping any _T row.
    final latest = <String, double>{};
    byLevel.forEach((code, series) {
      if (series.isEmpty) return;
      final c = code.toUpperCase();
      if (c == '_T' || c == 'T' || c == 'TOTAL') return;
      latest[c] = series.last.value;
    });
    if (latest.isEmpty) return const [];

    String hiCode = '', loCode = '';
    double hiVal = -1, loVal = double.infinity;
    latest.forEach((code, v) {
      if (v > hiVal) { hiVal = v; hiCode = code; }
      if (v < loVal) { loVal = v; loCode = code; }
    });

    double sumOf(List<String> codes) {
      var t = 0.0;
      for (final c in codes) {
        final v = latest[c];
        if (v != null) t += v;
      }
      return t;
    }
    final higherEd = sumOf(['BACH', 'HDIP', 'MAST', 'DOCT']);
    final basicEd = sumOf(['PRI', 'LSEC']);
    final vocational = latest['SCTE'];

    String lbl(String code) => _eduLevelLabels[code] ?? code;
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'الأعلى تعليماً' : 'HIGHEST LEVEL',
        value: pct(hiVal),
        caption: lbl(hiCode),
      ),
      _StatChip(
        overline: isAr ? 'الأدنى تعليماً' : 'LOWEST LEVEL',
        value: pct(loVal),
        caption: lbl(loCode),
      ),
      _StatChip(
        overline: isAr ? 'التعليم العالي' : 'HIGHER EDUCATION',
        value: pct(higherEd),
        caption: isAr ? 'بكالوريوس+' : 'Bachelor +',
      ),
      _StatChip(
        overline: isAr ? 'التعليم الأساسي' : 'BASIC EDUCATION',
        value: pct(basicEd),
        caption: isAr ? 'ابتدائي وإعدادي' : 'Primary & Lower Sec.',
      ),
      if (vocational != null)
        _StatChip(
          overline: isAr ? 'تعليم تقني' : 'VOCATIONAL',
          value: pct(vocational),
          caption: isAr ? 'تعليم تقني/مهني' : 'Short-Cycle Tertiary',
        ),
    ];
  }

  // Sector code → short name for the Employment-by-Sector insight chips.
  static const _empSectorNames = <String, String>{
    'PRI': 'Private Sector', 'PRH': 'Private Household', 'SHA': 'Shared',
    'LOC': 'Local Government', 'FED': 'Federal Government', 'FOR': 'Foreign',
    'NON': 'Non-profit Orgs', 'WIT': 'Without Establishment',
    'DIP': 'Diplomatic Authority',
  };

  // Insight cards for Employment by Sector — all computed from the latest
  // year's data: dominant sector, private-sector share, combined government
  // share (Federal + Local), and the sector where women are most concentrated.
  List<Widget> _employmentSectorChips() {
    if (data.meta.id != 'labour_employment_sector') return const [];
    final byLevel = data.byLevel;
    if (byLevel.isEmpty) return const [];

    // Latest Total value per sector.
    final latest = <String, double>{};
    byLevel.forEach((code, series) {
      if (series.isNotEmpty) latest[code.toUpperCase()] = series.last.value;
    });
    if (latest.isEmpty) return const [];

    String domCode = '';
    double domVal = -1;
    latest.forEach((c, v) {
      if (v > domVal) { domVal = v; domCode = c; }
    });

    final govShare = (latest['FED'] ?? 0) + (latest['LOC'] ?? 0);

    // Female concentration: sector with the highest Female share.
    final female = data.latestCategoryByGender('F');
    String femCode = '';
    double femVal = -1;
    female.forEach((c, v) {
      if (v > femVal) { femVal = v; femCode = c.toUpperCase(); }
    });

    String name(String c) => _empSectorNames[c] ?? c;
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'القطاع المهيمن' : 'DOMINANT SECTOR',
        value: pct(domVal),
        caption: name(domCode),
      ),
      _StatChip(
        overline: isAr ? 'القطاع الحكومي' : 'GOV. SECTOR',
        value: pct(govShare),
        caption: isAr ? 'اتحادي + محلي' : 'Federal + Local',
      ),
      if (femVal >= 0)
        _StatChip(
          overline: isAr ? 'تركّز الإناث' : 'FEMALE PEAK',
          value: pct(femVal),
          caption: name(femCode),
        ),
    ];
  }

  // Education-level short labels for the unemployment-by-education chips.
  static const _unempEduNames = <String, String>{
    'ILLIT': 'Illiterate', 'RANDW': 'Read & Write', 'PRI': 'Primary',
    'LSEC': 'Lower Sec.', 'SEC': 'Upper Sec.', 'PSNT': 'Post-Sec.',
    'SCTE': 'Short-Cycle Tert.', 'BACH': 'Bachelor', 'HDIP': 'Higher Diploma',
    'MAST': 'Master', 'DOCT': 'Doctoral',
  };

  // Insight cards for Unemployment by Education — computed from the latest
  // year's distribution: top category, 2nd category, top-2 combined share,
  // and post-graduate (Master's + Doctoral) share.
  List<Widget> _unemploymentEduChips() {
    if (data.meta.id != 'labour_unemployment_education') return const [];
    final byLevel = data.byLevel;
    if (byLevel.isEmpty) return const [];

    final latest = <String, double>{};
    byLevel.forEach((code, series) {
      if (series.isNotEmpty) latest[code.toUpperCase()] = series.last.value;
    });
    if (latest.isEmpty) return const [];

    final ranked = latest.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;
    final top2 = top.value + (second?.value ?? 0);
    final postGrad = (latest['MAST'] ?? 0) + (latest['DOCT'] ?? 0);

    String name(String c) => _unempEduNames[c] ?? c;
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'الفئة الأولى' : 'TOP CATEGORY',
        value: pct(top.value),
        caption: name(top.key),
      ),
      if (second != null)
        _StatChip(
          overline: isAr ? 'الفئة الثانية' : '2ND CATEGORY',
          value: pct(second.value),
          caption: name(second.key),
        ),
      _StatChip(
        overline: isAr ? 'حصة الأعلى 2' : 'TOP 2 SHARE',
        value: pct(top2),
        caption: isAr ? 'مجتمعة' : 'combined',
        valueColor: AppColors.warning,
      ),
      _StatChip(
        overline: isAr ? 'الدراسات العليا' : 'POST-GRAD',
        value: pct(postGrad),
        caption: isAr ? 'ماجستير + دكتوراه' : 'Master + PhD',
        valueColor: AppColors.success,
      ),
    ];
  }

  // Occupation code → short name for the Labor Force by Occupation chips.
  static const _occNames = <String, String>{
    'MAN': 'Managers', 'PROF': 'Professionals', 'TECH': 'Technicians',
    'CLER': 'Clerical', 'SERV': 'Service & Sales',
    'SKIL': 'Skilled Agri.', 'CRAF': 'Craft & Trade',
    'PLAN': 'Plant Operators', 'ELEM': 'Elementary',
  };

  // Insight cards for Labor Force by Occupation — computed from the latest
  // year: top group (highest Total), Female #1 (highest Female), and the
  // high-skill share (Managers + Professionals + Technicians, raw sum).
  List<Widget> _occupationChips() {
    if (data.meta.id != 'labour_workforce_occupation') return const [];
    final byLevel = data.byLevel;
    if (byLevel.isEmpty) return const [];

    final latest = <String, double>{};
    byLevel.forEach((code, series) {
      if (series.isNotEmpty) latest[code.toUpperCase()] = series.last.value;
    });
    if (latest.isEmpty) return const [];

    String topCode = '';
    double topVal = -1;
    latest.forEach((c, v) {
      if (v > topVal) { topVal = v; topCode = c; }
    });

    final female = data.latestCategoryByGender('F');
    String femCode = '';
    double femVal = -1;
    female.forEach((c, v) {
      if (v > femVal) { femVal = v; femCode = c.toUpperCase(); }
    });

    // High-skill = Managers + Professionals + Technicians (raw values).
    final highSkill =
        (latest['MAN'] ?? 0) + (latest['PROF'] ?? 0) + (latest['TECH'] ?? 0);

    String name(String c) => _occNames[c] ?? c;
    String pct(double v) => '${v.toStringAsFixed(1)}%';

    return [
      _StatChip(
        overline: isAr ? 'المجموعة الأولى' : 'TOP GROUP',
        value: name(topCode),
        caption: isAr ? 'حصة ${pct(topVal)}' : '${pct(topVal)} share',
      ),
      if (femVal >= 0)
        _StatChip(
          overline: isAr ? 'الإناث #1' : 'FEMALE #1',
          value: name(femCode),
          caption: isAr ? 'حصة ${pct(femVal)}' : '${pct(femVal)} share',
        ),
      _StatChip(
        overline: isAr ? 'مهارة عالية' : 'HIGH-SKILL',
        value: pct(highSkill),
        caption: isAr ? 'مدراء+مهنيون+فنيون' : 'PROF+TECH+MAN',
        valueColor: AppColors.success,
      ),
    ];
  }


  // GDP (Current Prices) insight chips appended to the 5Y stats row:
  // 2024 Total · Non-Oil GDP · 10Y Growth · Top Sector. Each card is omitted
  // when its source value is unavailable rather than fabricated.
  List<Widget> _gdpSummaryChips() {
    const gdpIds = {
      'gdp_current', 'gdp_constant',
      'gdp_quarterly_current', 'gdp_quarterly_constant',
    };
    if (gdpIds.contains(data.meta.id)) return _gdpFourCards();
    if (data.meta.id == 'trade_total') return _tradeChips();
    if (data.meta.id == 'trade_imports_hs') return _importChips();
    if (data.meta.id == 'trade_non_oil_exports') return _exportChips();
    if (data.meta.id == 'trade_sector_country') return _sectorCountryChips();
    if (data.meta.id == 'trade_reexports_annual') return _reExportChips();
    if (data.meta.id == 'trade_reexports_monthly') {
      return _monthlyReExportChips();
    }
    if (data.meta.id == 'prices_cpi_annual') return _cpiChips();
    if (data.meta.id == 'tourism_hotel_arrivals') return _hotelArrivalsChips();
    if (data.meta.id == 'tourism_hotel_establishments') {
      return _hotelEstablishmentsChips();
    }
    if (data.meta.id == 'tourism_main_indicators') {
      return _tourismMainChips();
    }
    if (data.meta.id == 'ecology_mean_temp') return _meanTempChips();
    if (data.meta.id == 'ecology_rainfall') return _rainfallChips();
    if (data.meta.id == 'ecology_produced_water') {
      return _producedWaterChips();
    }
    if (data.meta.id == 'ecology_natural_reserves') {
      return _naturalReservesChips();
    }
    if (data.meta.id == 'ecology_ramsar_wetlands') return _ramsarChips();
    if (data.meta.id == 'energy_generation_capacity' ||
        data.meta.id == 'energy_renewable') {
      return _generationChips();
    }
    if (data.meta.id == 'energy_crude_oil') return _crudeOilChips();
    if (data.meta.id == 'electricity') return _electricityChips();
    if (data.meta.id == 'crop_production') return _cropChips();
    if (data.meta.id == 'crop_land_total') return _landUseChips();
    if (data.meta.id.startsWith('livestock_')) return _livestockChips();
    if (data.meta.id == 'crop_area') return _cropAreaChips();
    return const [];
  }

  // Cultivated Area: CULTIVATED AREA · AVG · YOY GROWTH · 5Y GROWTH.
  List<Widget> _cropAreaChips() {
    final chips = <Widget>[];
    final series = data.uaeTotalSeries;
    if (series.isEmpty) return chips;
    final period = series.last.timePeriod;

    chips.add(_StatChip(
      overline: isAr ? 'المساحة المزروعة' : 'CULTIVATED AREA',
      value: NumberFormatter.compact(series.last.value),
      caption: isAr ? 'دونم · $period' : 'Donum · $period',
    ));

    final avg = data.averageValue;
    if (avg != null) {
      chips.add(_StatChip(
        overline: isAr ? 'متوسط المساحة' : 'AVG CULTIVATED AREA',
        value: NumberFormatter.compact(avg),
        caption: isAr ? 'المتوسط السنوي' : 'Annual average',
      ));
    }

    final yoy = data.yoyGrowth;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'النمو السنوي' : 'YOY GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'مقابل العام السابق' : 'vs Previous Year',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }

    // 5-year cumulative growth (last vs the value 5 years earlier).
    if (series.length >= 2) {
      final n = series.length >= 6 ? 6 : series.length;
      final base = series[series.length - n].value;
      if (base != 0) {
        final g5 = (series.last.value - base) / base * 100;
        chips.add(_StatChip(
          overline: isAr ? 'نمو 5 سنوات' : '5Y GROWTH',
          value: NumberFormatter.percent(g5),
          caption: isAr ? 'اتجاه 5 سنوات' : '5-Year Trend',
          valueColor: g5 < 0 ? AppColors.error : AppColors.success,
        ));
      }
    }
    return chips;
  }

  // Livestock census: FEMALE · MILCH FEMALES · ABU DHABI SHARE · GROWTH SINCE.
  List<Widget> _livestockChips() {
    final chips = <Widget>[];

    final female = data.livestockFemaleLatest;
    if (female != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الإناث' : 'FEMALES',
        value: NumberFormatter.compact(female.value),
        caption: isAr ? 'رأس · ${female.period}' : 'Head · ${female.period}',
      ));
    }
    final milch = data.livestockMilchLatest;
    if (milch != null && milch.value > 0) {
      chips.add(_StatChip(
        overline: isAr ? 'الإناث الحلوب' : 'MILCH FEMALES',
        value: NumberFormatter.compact(milch.value),
        caption: isAr ? 'حلوب · ${milch.period}' : 'Dairy · ${milch.period}',
      ));
    }
    final adShare = data.livestockAbuDhabiShare;
    if (adShare != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة أبوظبي' : 'ABU DHABI SHARE',
        value: '${adShare.toStringAsFixed(1)}%',
        caption: isAr ? 'الإجمالي الوطني' : 'National total',
      ));
    }
    final growth = data.livestockGrowthSince;
    final fromYear = data.uaeTotalSeries.isEmpty
        ? null
        : data.uaeTotalSeries.first.timePeriod;
    if (growth != null && fromYear != null) {
      final years = data.uaeTotalSeries.length - 1;
      chips.add(_StatChip(
        overline: isAr ? 'النمو منذ $fromYear' : 'GROWTH SINCE $fromYear',
        value: NumberFormatter.percent(growth),
        caption: isAr ? 'اتجاه $years سنوات' : '$years-year trend',
        valueColor: growth < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Total Agricultural Land Use: ABU DHABI SHARE · FRUIT TREES ·
  // GROWTH <from>–<to> · PRODUCTIVE SHARE.
  List<Widget> _landUseChips() {
    final chips = <Widget>[];

    final adShare = data.landAbuDhabiShare;
    if (adShare != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة أبوظبي' : 'ABU DHABI SHARE',
        value: '${adShare.toStringAsFixed(1)}%',
        caption: isAr ? 'من إجمالي الإمارات 2024' : 'of UAE total 2024',
      ));
    }
    final fruit = data.landFruitTrees;
    if (fruit != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الأشجار المثمرة' : 'FRUIT TREES',
        value: NumberFormatter.compact(fruit),
        caption: isAr ? 'دونم · 2024' : 'Donum · 2024',
      ));
    }
    final growth = data.landGrowthSince;
    final fromY = data.landGrowthFromYear;
    final toY = data.landGrowthToYear;
    if (growth != null && fromY != null && toY != null) {
      final shortFrom = fromY.length >= 4 ? fromY : fromY;
      final shortTo = toY.length >= 4 ? toY.substring(2) : toY;
      chips.add(_StatChip(
        overline: isAr
            ? 'النمو $fromY–$toY'
            : 'GROWTH $shortFrom–$shortTo',
        value: NumberFormatter.percent(growth),
        caption: isAr ? 'زيادة المساحة الكلية' : 'total area increase',
        valueColor: growth < 0 ? AppColors.error : AppColors.success,
      ));
    }
    final prodShare = data.landProductiveShare;
    if (prodShare != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة المنتجة' : 'PRODUCTIVE SHARE',
        value: '${prodShare.toStringAsFixed(1)}%',
        caption: isAr ? 'من إجمالي الأرض 2024' : 'of total land 2024',
      ));
    }
    return chips;
  }

  // Crop Statistics: PRODUCTION · FARM AREA · FARM VALUE · EMIRATES.
  List<Widget> _cropChips() {
    final chips = <Widget>[];
    final period = data.latestPeriod;

    final prod = data.latestValue;
    if (prod > 0) {
      chips.add(_StatChip(
        overline: isAr ? 'الإنتاج' : 'PRODUCTION',
        value: NumberFormatter.compact(prod),
        caption: isAr ? 'طن متري · $period' : 'MT · $period',
      ));
    }
    final area = data.cropFarmArea;
    if (area != null) {
      chips.add(_StatChip(
        overline: isAr ? 'مساحة المزارع' : 'FARM AREA',
        value: NumberFormatter.compact(area),
        caption: isAr ? 'دونم · 2024' : 'Donum · 2024',
      ));
    }
    final value = data.cropFarmValue;
    if (value != null) {
      chips.add(_StatChip(
        overline: isAr ? 'قيمة المزارع' : 'FARM VALUE',
        value: NumberFormatter.compact(value),
        caption: isAr ? 'درهم · 2020' : 'AED · 2020',
      ));
    }
    final emirates = data.cropProducingEmirates;
    if (emirates != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الإمارات' : 'EMIRATES',
        value: emirates.toStringAsFixed(0),
        caption: isAr ? 'منتجة' : 'producing',
      ));
    }
    return chips;
  }

  // Electricity: COMMERCIAL · RESIDENTIAL · ABU DHABI SHARE · GROWTH SINCE.
  List<Widget> _electricityChips() {
    final chips = <Widget>[];

    final com = data.elecCommercial;
    if (com != null) {
      chips.add(_StatChip(
        overline: isAr ? 'تجاري' : 'COMMERCIAL',
        value: NumberFormatter.compact(com),
        caption: isAr ? 'ج.و.س · 2024' : 'GWh · 2024',
      ));
    }
    final res = data.elecResidential;
    if (res != null) {
      chips.add(_StatChip(
        overline: isAr ? 'سكني' : 'RESIDENTIAL',
        value: NumberFormatter.compact(res),
        caption: isAr ? 'ج.و.س · 2024' : 'GWh · 2024',
      ));
    }
    final share = data.elecAbuDhabiShare;
    if (share != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة أبوظبي' : 'ABU DHABI SHARE',
        value: '${share.toStringAsFixed(1)}%',
        caption: isAr ? 'من الإجمالي الوطني' : 'National total',
      ));
    }
    final growth = data.elecGrowthSince;
    final fromYear = data.elecGrowthFromYear;
    if (growth != null && fromYear != null) {
      chips.add(_StatChip(
        overline: isAr ? 'النمو منذ $fromYear' : 'GROWTH SINCE $fromYear',
        value: NumberFormatter.percent(growth),
        caption: isAr ? 'اتجاه 10 سنوات' : '10-year trend',
        valueColor: growth < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Crude Oil: PRODUCTION · EXPORTS · IMPORTS · RESERVE LIFE.
  List<Widget> _crudeOilChips() {
    final chips = <Widget>[];
    final flow = data.crudeOilTradeFlow; // 000 bbl/day, latest year
    final period = data.latestPeriod;
    String n(double v) => NumberFormatter.full(v);

    final prod = flow['PR'];
    if (prod != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الإنتاج' : 'PRODUCTION',
        value: n(prod),
        caption: isAr ? 'ألف ب/ي · $period' : '000 bbl/day · $period',
      ));
    }
    final exp = flow['EX'];
    if (exp != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الصادرات' : 'EXPORTS',
        value: n(exp),
        caption: isAr ? 'ألف ب/ي · $period' : '000 bbl/day · $period',
      ));
    }
    final imp = flow['IM'];
    if (imp != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الواردات' : 'IMPORTS',
        value: n(imp),
        caption: isAr ? 'ألف ب/ي · $period' : '000 bbl/day · $period',
      ));
    }
    // Reserve life = proven reserves (Mn bbl) / annual production (Mn bbl/yr).
    final reserves = data.crudeOilSeries('RE');
    if (reserves.isNotEmpty && prod != null && prod > 0) {
      final res = reserves.last.value; // Mn bbl
      final annualProd = prod * 365 / 1000.0; // 000 bbl/day → Mn bbl/yr
      if (annualProd > 0) {
        final life = res / annualProd;
        chips.add(_StatChip(
          overline: isAr ? 'عمر الاحتياطي' : 'RESERVE LIFE',
          value: '~${life.toStringAsFixed(0)}',
          caption: isAr ? 'سنوات بإنتاج $period' : 'years at $period output',
        ));
      }
    }
    return chips;
  }

  // Generation Capacity: SOLAR PV (MW) · RE OUTPUT (GWh) · SOLAR SHARE (%).
  List<Widget> _generationChips() {
    final chips = <Widget>[];
    String n(double v) => NumberFormatter.full(v);

    final pv = data.gcSolarPv;
    if (pv != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الطاقة الشمسية (2024)' : 'SOLAR PV (2024)',
        value: n(pv),
        caption: isAr ? 'ميجاوات · كهروضوئية' : 'MW · photovoltaic',
      ));
    }
    final output = data.gcReOutput;
    if (output != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إنتاج المتجددة (2024)' : 'RE OUTPUT (2024)',
        value: n(output),
        caption: isAr ? 'ج.و.س · إجمالي الإنتاج' : 'GWh · total production',
      ));
    }
    final share = data.gcSolarShare;
    if (share != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة الطاقة الشمسية' : 'SOLAR SHARE',
        value: '${share.toStringAsFixed(1)}%',
        caption: isAr ? 'من إجمالي القدرة' : 'of total capacity',
      ));
    }
    return chips;
  }

  // RAMSAR Wetlands: TOTAL SITES · MARINE AREA · TERRESTRIAL.
  List<Widget> _ramsarChips() {
    final chips = <Widget>[];

    final total = data.rwTotalSites;
    if (total != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إجمالي المواقع' : 'TOTAL SITES',
        value: total.toStringAsFixed(0),
        caption: isAr ? 'مواقع رامسار · الإمارات' : 'RAMSAR sites · UAE',
      ));
    }
    final marine = data.rwMarineArea;
    if (marine != null) {
      chips.add(_StatChip(
        overline: isAr ? 'المساحة البحرية' : 'MARINE AREA',
        value: marine.toStringAsFixed(1),
        caption: isAr ? 'كم² · 6 مواقع بحرية' : 'km² · 6 marine sites',
      ));
    }
    final ter = data.rwTerrestrialArea;
    if (ter != null) {
      chips.add(_StatChip(
        overline: isAr ? 'بري' : 'TERRESTRIAL',
        value: ter.toStringAsFixed(1),
        caption: isAr ? 'كم² · 4 مواقع برية' : 'km² · 4 land sites',
      ));
    }
    return chips;
  }

  // Protected Natural Areas: TERRESTRIAL · MARINE · RAMSAR WETLANDS ·
  // OLDEST RESERVE.
  List<Widget> _naturalReservesChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String km2(double v) => NumberFormatter.full(v);

    final ter = data.nrTerrestrial;
    if (ter != null) {
      chips.add(_StatChip(
        overline: isAr ? 'بري' : 'TERRESTRIAL',
        value: km2(ter.value),
        caption: isAr ? 'كم² بري · $period' : 'km² land-based · $period',
      ));
    }
    final mar = data.nrMarine;
    if (mar != null) {
      chips.add(_StatChip(
        overline: isAr ? 'بحري' : 'MARINE',
        value: km2(mar.value),
        caption: isAr ? 'كم² ساحلي وبحري · $period' : 'km² coastal & sea · $period',
      ));
    }
    final ram = data.nrRamsar;
    if (ram != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أراضي رامسار' : 'RAMSAR WETLANDS',
        value: ram.value.toStringAsFixed(1),
        caption: isAr ? 'كم² معلنة · $period' : 'km² designated · $period',
      ));
    }
    final old = data.nrOldest;
    if (old != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أقدم محمية' : 'OLDEST RESERVE',
        value: old.value.toStringAsFixed(0),
        caption: old.note == null
            ? (data.allPoints
                    .firstWhere((p) => p.measure == 'NR_OLDEST',
                        orElse: () => data.allPoints.first)
                    .categoryLabel ??
                '')
            : '${data.allPoints.firstWhere((p) => p.measure == "NR_OLDEST", orElse: () => data.allPoints.first).categoryLabel ?? ""} · ${old.note}',
      ));
    }
    return chips;
  }

  // Produced Water: PEAK YEAR · DESALINATION · TOP PRODUCER.
  static const _pwEntityEmirate = <String, String>{
    'EAD': 'Abu Dhabi', 'DEWA': 'Dubai', 'SEWA': 'Sharjah',
    'EWE': 'Northern Emirates',
  };

  List<Widget> _producedWaterChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    final peak = data.pwPeakYear;
    if (peak != null) {
      chips.add(_StatChip(
        overline: isAr ? 'سنة الذروة' : 'PEAK YEAR',
        value: peak.year,
        caption: isAr
            ? '${peak.value.toStringAsFixed(1)} م.م³ إجمالي'
            : '${peak.value.toStringAsFixed(1)} MCM total',
      ));
    }
    final desal = data.pwDesalinationShare;
    if (desal != null) {
      chips.add(_StatChip(
        overline: isAr ? 'التحلية' : 'DESALINATION',
        value: '~${desal.toStringAsFixed(0)}%',
        caption: isAr ? 'حصة مياه البحر $period' : 'Seawater share $period',
      ));
    }
    final top = data.pwTopProducer;
    if (top != null) {
      final emirate = _pwEntityEmirate[top.code.toUpperCase()] ?? '';
      chips.add(_StatChip(
        overline: isAr ? 'أكبر منتج' : 'TOP PRODUCER',
        value: top.code,
        caption: emirate.isEmpty
            ? '${top.share.toStringAsFixed(1)}%'
            : '$emirate · ${top.share.toStringAsFixed(1)}%',
      ));
    }
    return chips;
  }

  // Annual Rainfall: WETTEST YEAR · RAINY DAYS · WETTEST STATION ·
  // DRIEST STATION.
  List<Widget> _rainfallChips() {
    final chips = <Widget>[];

    final wy = data.rfWettestYear;
    if (wy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أمطر سنة' : 'WETTEST YEAR',
        value: wy.note ?? '—',
        caption: isAr
            ? '${wy.value.toStringAsFixed(1)} مم متوسط وطني'
            : '${wy.value.toStringAsFixed(1)} mm national avg',
      ));
    }
    final rd = data.rfRainyDays;
    if (rd != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أيام المطر' : 'RAINY DAYS',
        value: '~${rd.value.toStringAsFixed(0)}',
        caption: isAr ? 'متوسط أيام سنوياً' : 'Avg days per year',
      ));
    }
    final ws = data.rfWettestStation;
    if (ws != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أمطر محطة' : 'WETTEST STATION',
        value: ws.note ?? (ws.value.toStringAsFixed(1)),
        caption: '${ws.note == null ? "" : ""}${_rfStationCaption(ws)}',
      ));
    }
    final ds = data.rfDriestStation;
    if (ds != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أجف محطة' : 'DRIEST STATION',
        value: ds.note ?? (ds.value.toStringAsFixed(1)),
        caption: _rfStationCaption(ds),
      ));
    }
    return chips;
  }

  String _rfStationCaption(({double value, String? note}) s) {
    // categoryLabel is the full station name; show "<name> · <mm> mm".
    final label = data.allPoints
        .firstWhere(
          (p) =>
              p.obsStatus == s.note &&
              (p.measure == 'RF_WETSTATION' || p.measure == 'RF_DRYSTATION'),
          orElse: () => data.allPoints.first,
        )
        .categoryLabel;
    final name = label ?? '';
    return '$name · ${s.value.toStringAsFixed(1)} mm';
  }

  // Mean Temperature: PEAK MONTH · COOLEST MONTH · ANNUAL RANGE · MEAN MAX AVG.
  List<Widget> _meanTempChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String deg(double v) => '${v.toStringAsFixed(1)}°';

    final peak = data.mtPeakMonth;
    if (peak != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أحر شهر' : 'PEAK MONTH',
        value: deg(peak.value),
        caption: peak.month == null ? period : '${peak.month} · $period',
      ));
    }
    final cool = data.mtCoolestMonth;
    if (cool != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أبرد شهر' : 'COOLEST MONTH',
        value: deg(cool.value),
        caption: cool.month == null ? period : '${cool.month} · $period',
      ));
    }
    final range = data.mtAnnualRange;
    if (range != null) {
      chips.add(_StatChip(
        overline: isAr ? 'المدى السنوي' : 'ANNUAL RANGE',
        value: deg(range.value),
        caption: isAr ? 'تغير °م' : '°C variation',
      ));
    }
    final maxAvg = data.mtMeanMaxAvg;
    if (maxAvg != null) {
      chips.add(_StatChip(
        overline: isAr ? 'متوسط العظمى' : 'MEAN MAX AVG',
        value: deg(maxAvg.value),
        caption: isAr ? '°م · $period' : '°C · $period',
      ));
    }
    return chips;
  }

  // Tourism Main Indicators: GUESTS · REVENUE · ROOM NIGHTS · OCCUPANCY ·
  // AVG. STAY · HOTELS · TOTAL ROOMS.
  List<Widget> _tourismMainChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String yoyCap(double? pct, {bool pp = false}) => pct == null
        ? (isAr ? period : period)
        : (isAr
            ? '${NumberFormatter.percent(pct)}${pp ? "ن.م" : ""} سنوياً'
            : '${NumberFormatter.percent(pct)}${pp ? "pp" : ""} YoY');

    // GUESTS (from the TOUR_GUESTS series — the headline is now revenue).
    final guests = data.tmGuests;
    if (guests != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الضيوف $period' : 'GUESTS $period',
        value: NumberFormatter.compact(guests.value),
        caption: guests.yoy == null ? period : yoyCap(guests.yoy),
        valueColor: AppColors.slate900,
      ));
    }
    final rn = data.tmRoomNights;
    if (rn != null) {
      chips.add(_StatChip(
        overline: isAr ? 'ليالي الغرف' : 'ROOM NIGHTS',
        value: NumberFormatter.compact(rn.value),
        caption: isAr ? 'محجوزة $period' : 'Booked $period',
      ));
    }
    final occ = data.tmOccupancy;
    if (occ != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الإشغال' : 'OCCUPANCY',
        value: '${occ.value.toStringAsFixed(1)}%',
        caption: yoyCap(occ.pct, pp: true),
      ));
    }
    final stay = data.tmAvgStay;
    if (stay != null) {
      chips.add(_StatChip(
        overline: isAr ? 'متوسط الإقامة' : 'AVG. STAY',
        value: isAr ? '${stay.value.toStringAsFixed(1)} يوم'
                    : '${stay.value.toStringAsFixed(1)} days',
        caption: isAr ? 'لكل ضيف $period' : 'Per guest $period',
      ));
    }
    final arr = data.tmAvgRoomRate;
    if (arr != null) {
      chips.add(_StatChip(
        overline: isAr ? 'متوسط سعر الغرفة' : 'AVG ROOM RATE',
        value: 'AED ${NumberFormatter.full(arr.value)}',
        caption: isAr ? 'لكل ليلة · $period' : 'Per night · $period',
      ));
    }
    final rooms = data.tmRooms;
    if (rooms != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إجمالي الغرف' : 'TOTAL ROOMS',
        value: NumberFormatter.full(rooms.value),
        caption: yoyCap(rooms.pct),
      ));
    }
    return chips;
  }

  // Hotel Establishments: TOTAL <yr> · HOTELS · HOTEL APTS · TOTAL ROOMS ·
  // GROWTH.
  List<Widget> _hotelEstablishmentsChips() {
    final period = data.latestPeriod;
    final total = data.latestValue;
    final chips = <Widget>[];
    String n(double v) => NumberFormatter.full(v);

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي $period' : '$period TOTAL',
      value: n(total),
      caption: isAr ? 'منشأة' : 'Establishments',
    ));

    final hotels = data.heHotels;
    if (hotels != null) {
      final pct = total > 0 ? hotels / total * 100 : 0;
      chips.add(_StatChip(
        overline: isAr ? 'فنادق' : 'HOTELS',
        value: n(hotels),
        caption: isAr
            ? '${pct.toStringAsFixed(1)}% من الإجمالي'
            : '${pct.toStringAsFixed(1)}% of total',
      ));
    }
    final apts = data.heApts;
    if (apts != null) {
      final pct = total > 0 ? apts / total * 100 : 0;
      chips.add(_StatChip(
        overline: isAr ? 'شقق فندقية' : 'HOTEL APTS',
        value: n(apts),
        caption: isAr
            ? '${pct.toStringAsFixed(1)}% من الإجمالي'
            : '${pct.toStringAsFixed(1)}% of total',
      ));
    }
    final rooms = data.heTotalRooms;
    if (rooms != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إجمالي الغرف' : 'TOTAL ROOMS',
        value: n(rooms),
        caption: isAr ? 'على مستوى الدولة $period' : 'Nationwide $period',
      ));
    }

    // GROWTH — first→last over the series (e.g. 2016–2022).
    final s = data.uaeTotalSeries;
    if (s.length >= 2 && s.first.value != 0) {
      final g = (s.last.value - s.first.value) / s.first.value * 100;
      chips.add(_StatChip(
        overline: isAr ? 'النمو' : 'GROWTH',
        value: NumberFormatter.percent(g),
        caption: '${s.first.timePeriod}–${s.last.timePeriod}',
        valueColor: g < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Hotel Guest Arrivals: TOTAL GUESTS · TOP ORIGIN · NAT. REGIONS ·
  // PEAK YEAR · GUEST GROWTH.
  List<Widget> _hotelArrivalsChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي الضيوف' : 'TOTAL GUESTS',
      value: NumberFormatter.compact(data.latestValue),
      caption: isAr ? 'وصول · $period' : 'Arrivals · $period',
    ));

    final top = data.hotelArrivalsTopOrigin;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر مصدر' : 'TOP ORIGIN',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة · $period'
            : '${top.share.toStringAsFixed(1)}% share · $period',
      ));
    }

    final regions = data.hotelArrivalsRegionCount;
    if (regions > 0) {
      chips.add(_StatChip(
        overline: isAr ? 'المناطق' : 'NAT. REGIONS',
        value: '$regions',
        caption: isAr ? 'مجموعات تغطية' : 'Coverage groups',
      ));
    }

    final peak = data.hotelArrivalsPeakYear;
    if (peak != null) {
      chips.add(_StatChip(
        overline: isAr ? 'سنة الذروة' : 'PEAK YEAR',
        value: peak.year,
        caption: isAr
            ? '${NumberFormatter.compact(peak.value)} ضيف'
            : '${NumberFormatter.compact(peak.value)} guests',
      ));
    }

    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو الضيوف' : 'GUEST GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // CPI Annual: <yr> CPI · INFLATION · PEAK DIV. · BASE YEAR.
  List<Widget> _cpiChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    chips.add(_StatChip(
      overline: isAr ? 'مؤشر $period' : '$period CPI',
      value: data.cpiLatest.toStringAsFixed(2),
      caption: isAr ? 'مؤشر كل البنود' : 'All Items Index',
    ));

    final infl = data.cpiInflation;
    if (infl != null) {
      chips.add(_StatChip(
        overline: isAr ? 'التضخم' : 'INFLATION',
        value: NumberFormatter.percent(infl),
        caption: isAr ? 'المعدل السنوي $period' : 'Annual rate $period',
        valueColor: infl < 0 ? AppColors.error : AppColors.success,
      ));
    }

    final peak = data.cpiPeakDivision;
    if (peak != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أعلى قسم' : 'PEAK DIV.',
        value: peak.name,
        caption: isAr
            ? '${peak.points.toStringAsFixed(2)} نقطة · $period'
            : '${peak.points.toStringAsFixed(2)} pts · $period',
      ));
    }

    // BASE YEAR (2021 = 100 reference) — the first year where the index is 100.
    final base = data.uaeTotalSeries.where((p) => p.value == 100.0).toList();
    if (base.isNotEmpty) {
      chips.add(_StatChip(
        overline: isAr ? 'سنة الأساس' : 'BASE YEAR',
        value: base.first.timePeriod,
        caption: isAr ? '= 100 مرجع' : '= 100 reference',
      ));
    }
    return chips;
  }

  // Monthly Re-Exports: COUNTRIES · TOP DEST. · YTD GROWTH · FULL YR <prev>.
  List<Widget> _monthlyReExportChips() {
    final chips = <Widget>[];

    final dest = data.monthlyReExportDestinationCount;
    if (dest != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الدول' : 'COUNTRIES',
        value: '$dest',
        caption: isAr ? 'وجهات ${data.latestPeriod.split('-').first}'
                      : 'Destinations ${data.latestPeriod.split('-').first}',
      ));
    }

    final top = data.monthlyReExportTopDest;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر وجهة' : 'TOP DEST.',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة'
            : '${top.share.toStringAsFixed(1)}% share',
      ));
    }

    final ytd = data.monthlyReExportYtdGrowth;
    if (ytd != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو حتى تاريخه' : 'YTD GROWTH',
        value: NumberFormatter.percent(ytd.growth),
        caption: isAr ? 'مقابل ${ytd.fromLabel}' : 'vs ${ytd.fromLabel}',
        valueColor: ytd.growth < 0 ? AppColors.error : AppColors.success,
      ));
    }

    final fy = data.monthlyReExportFullYear;
    if (fy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'سنة ${fy.year} كاملة' : 'FULL YR ${fy.year}',
        value: NumberFormatter.full(fy.value),
        caption: isAr ? 'مليون درهم · سنوي' : 'AED Mn · Annual',
      ));
    }
    return chips;
  }

  // Annual Re-Exports: TOTAL RE-EXPORTS · PARTNER NATIONS · HS SECTIONS ·
  // TOP DESTINATION · RE-EXPORT GROWTH.
  List<Widget> _reExportChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي إعادة التصدير' : 'TOTAL RE-EXPORTS',
      value: NumberFormatter.full(data.latestValue),
      caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
    ));

    final dest = data.exportDestinationCount;
    if (dest != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الدول الشريكة' : 'PARTNER NATIONS',
        value: '$dest',
        caption: isAr ? 'دولة · $period' : 'Countries · $period',
      ));
    }

    if (data.exportSections.isNotEmpty) {
      chips.add(_StatChip(
        overline: isAr ? 'أقسام النظام المنسق' : 'HS SECTIONS',
        value: '21',
        caption: isAr ? 'مجموعات سلعية' : 'Commodity groups',
      ));
    }

    final top = data.exportTopMarket;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر وجهة' : 'TOP DESTINATION',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة · $period'
            : '${top.share.toStringAsFixed(1)}% share · $period',
      ));
    }

    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو إعادة التصدير' : 'RE-EXPORT GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Sector & Country: TOTAL EXPORTS · DESTINATIONS · HS SECTIONS · TOP MARKET
  // · EXPORT GROWTH.
  List<Widget> _sectorCountryChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي الصادرات' : 'TOTAL EXPORTS',
      value: NumberFormatter.full(data.latestValue),
      caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
    ));

    final dest = data.exportDestinationCount;
    if (dest != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الوجهات' : 'DESTINATIONS',
        value: '$dest',
        caption: isAr ? 'دولة · $period' : 'Countries · $period',
      ));
    }

    if (data.exportSections.isNotEmpty) {
      chips.add(_StatChip(
        overline: isAr ? 'أقسام النظام المنسق' : 'HS SECTIONS',
        value: '21',
        caption: isAr ? 'مجموعات سلعية' : 'Commodity groups',
      ));
    }

    final top = data.exportTopMarket;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر سوق' : 'TOP MARKET',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة · $period'
            : '${top.share.toStringAsFixed(1)}% share · $period',
      ));
    }

    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو الصادرات' : 'EXPORT GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Shared 4-card set for ALL GDP pages (current/constant, annual/quarterly):
  //   TOTAL GDP · GDP GROWTH · NON-OIL GDP · NON-OIL GDP GROWTH.
  // Headline uses the page's own series (quarterly on quarterly pages, annual
  // otherwise); GDP GROWTH is YoY (4 quarters back on quarterly pages, prior
  // year on annual). NON-OIL figures use the merged annual _TNO aggregate.
  List<Widget> _gdpFourCards() {
    final series = data.uaeTotalSeries; // page headline (quarterly or annual)
    if (series.isEmpty) return const [];
    final chips = <Widget>[];
    final isQuarterly = series.last.timePeriod.contains('-Q');
    final unit = data.meta.id.contains('constant')
        ? (isAr ? 'مليون درهم ثابت' : 'AED Mn constant')
        : (isAr ? 'مليون درهم جاري' : 'AED Mn');

    // TOTAL GDP
    final latest = series.last;
    chips.add(_StatChip(
      overline: isAr ? 'إجمالي الناتج' : 'TOTAL GDP',
      value: NumberFormatter.aedMillionsCompact(latest.value),
      caption: '$unit · ${latest.timePeriod}',
    ));

    // GDP GROWTH (YoY): 4 quarters back for quarterly, prior point for annual.
    final step = isQuarterly ? 5 : 2; // index distance for "one year earlier"
    if (series.length >= step) {
      final prior = series[series.length - step];
      if (prior.value != 0) {
        final yoy = (latest.value - prior.value) / prior.value * 100;
        chips.add(_StatChip(
          overline: isAr ? 'نمو الناتج' : 'GDP GROWTH',
          value: NumberFormatter.percent(yoy),
          caption: isAr ? 'مقابل ${prior.timePeriod}' : 'vs ${prior.timePeriod}',
          valueColor: yoy < 0 ? AppColors.error : AppColors.success,
        ));
      }
    }

    // NON-OIL GDP (annual _TNO)
    final nonOil = data.gdpNonOilLatest;
    final nonOilPeriod = data.gdpNonOilSeries.isNotEmpty
        ? data.gdpNonOilSeries.last.timePeriod
        : '';
    if (nonOil != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الناتج غير النفطي' : 'NON-OIL GDP',
        value: NumberFormatter.aedMillionsCompact(nonOil),
        caption: '$unit · $nonOilPeriod',
      ));
    }

    // NON-OIL GDP GROWTH (annual non-oil YoY)
    final nonOilYoY = data.gdpNonOilYoY;
    final nonOilPrev = data.gdpNonOilPrevPeriod;
    if (nonOilYoY != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو غير النفطي' : 'NON-OIL GDP GROWTH',
        value: NumberFormatter.percent(nonOilYoY),
        caption: nonOilPrev == null
            ? ''
            : (isAr ? 'مقابل $nonOilPrev' : 'vs $nonOilPrev'),
        valueColor: nonOilYoY < 0 ? AppColors.error : AppColors.success,
      ));
    }

    return chips;
  }

  // Aircraft Movement insight cards (shown after the 5Y stats):
  // TOTAL <yr> · ARRIVALS · DEPARTURES · DUBAI SHARE · ABU DHABI · VS PRE-COVID
  // · COVID RECOVERY. Each card is omitted when its source data is absent.
  List<Widget> _aircraftChips() {
    if (data.meta.id != 'aircraft_movement') return const [];
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String n(double v) => NumberFormatter.full(v);

    // TOTAL <year>
    final yoy = data.tradeTotalYoY; // generic latest-vs-prior YoY of the series
    chips.add(_StatChip(
      overline: isAr ? 'إجمالي $period' : '$period TOTAL',
      value: n(data.latestValue),
      caption: yoy == null
          ? (isAr ? 'رحلة' : 'flights')
          : (isAr
              ? '${NumberFormatter.percent(yoy)} سنوياً'
              : '${NumberFormatter.percent(yoy)} YoY'),
    ));

    // ARRIVALS / DEPARTURES (national sums)
    final arr = data.aircraftFlowTotal('ARR');
    if (arr > 0) {
      chips.add(_StatChip(
        overline: isAr ? 'الوصول' : 'ARRIVALS',
        value: n(arr),
        caption: isAr ? 'إجمالي $period' : '$period total',
      ));
    }
    final dep = data.aircraftFlowTotal('DEP');
    if (dep > 0) {
      chips.add(_StatChip(
        overline: isAr ? 'المغادرة' : 'DEPARTURES',
        value: n(dep),
        caption: isAr ? 'إجمالي $period' : '$period total',
      ));
    }

    // DUBAI SHARE / ABU DHABI share of national total
    final du = data.aircraftEmirateShare('AE-DU');
    if (du != null) {
      chips.add(_StatChip(
        overline: isAr ? 'حصة دبي' : 'DUBAI SHARE',
        value: '${du.toStringAsFixed(1)}%',
        caption: isAr ? 'من إجمالي الدولة' : 'of UAE total',
      ));
    }
    final az = data.aircraftEmirateShare('AE-AZ');
    if (az != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أبوظبي' : 'ABU DHABI',
        value: '${az.toStringAsFixed(1)}%',
        caption: isAr ? 'من إجمالي الدولة' : 'of UAE total',
      ));
    }

    // VS PRE-COVID (2019) / COVID RECOVERY (2020 low)
    final vs2019 = data.aircraftGrowthVsYear('2019');
    if (vs2019 != null) {
      chips.add(_StatChip(
        overline: isAr ? 'مقابل ما قبل كوفيد' : 'VS PRE-COVID',
        value: NumberFormatter.percent(vs2019),
        caption: isAr ? 'فوق 2019' : 'above 2019',
        valueColor: vs2019 < 0 ? AppColors.error : AppColors.success,
      ));
    }
    final vs2020 = data.aircraftGrowthVsYear('2020');
    if (vs2020 != null) {
      chips.add(_StatChip(
        overline: isAr ? 'التعافي من كوفيد' : 'COVID RECOVERY',
        value: NumberFormatter.percent(vs2020),
        caption: isAr ? 'فوق أدنى 2020' : 'above 2020 low',
        valueColor: vs2020 < 0 ? AppColors.error : AppColors.success,
      ));
    }

    return chips;
  }

  // Non-Oil Exports: NON-OIL EXPORTS · RE-EXPORTS · DOMESTIC · TOP MARKET ·
  // EXPORT GROWTH.
  List<Widget> _exportChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String mn(double v) => NumberFormatter.full(v);

    chips.add(_StatChip(
      overline: isAr ? 'الصادرات غير النفطية' : 'NON-OIL EXPORTS',
      value: mn(data.latestValue),
      caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
    ));

    final re = data.exportFlow('re-export');
    if (re != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إعادة التصدير' : 'RE-EXPORTS',
        value: mn(re),
        caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
      ));
    }
    final dom = data.exportFlow('domestic');
    if (dom != null) {
      chips.add(_StatChip(
        overline: isAr ? 'محلي' : 'DOMESTIC',
        value: mn(dom),
        caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
      ));
    }

    final top = data.exportTopMarket;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر سوق' : 'TOP MARKET',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة · $period'
            : '${top.share.toStringAsFixed(1)}% share · $period',
      ));
    }

    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو الصادرات' : 'EXPORT GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Imports by HS Section: TOTAL IMPORTS · HS SECTIONS · IMPORT GROWTH.
  // (Partner-nations / top-supplier cards are added once that data is wired.)
  List<Widget> _importChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي الواردات' : 'TOTAL IMPORTS',
      value: NumberFormatter.full(data.latestValue),
      caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
    ));

    // PARTNER NATIONS
    final partners = data.tradeImportPartnerCount;
    if (partners != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الدول الشريكة' : 'PARTNER NATIONS',
        value: '$partners+',
        caption: isAr ? 'دولة · $period' : 'Countries · $period',
      ));
    }

    if (data.tradeImportSections.isNotEmpty) {
      // The HS classification has 21 commodity sections (the breakdown lists
      // the leading ones); show the full section count, not just those charted.
      chips.add(_StatChip(
        overline: isAr ? 'أقسام النظام المنسق' : 'HS SECTIONS',
        value: '21',
        caption: isAr ? 'مجموعات سلعية' : 'Commodity groups',
      ));
    }

    // TOP SUPPLIER
    final top = data.tradeTopSupplier;
    if (top != null) {
      chips.add(_StatChip(
        overline: isAr ? 'أكبر مورّد' : 'TOP SUPPLIER',
        value: top.name,
        caption: isAr
            ? '${top.share.toStringAsFixed(1)}% حصة · $period'
            : '${top.share.toStringAsFixed(1)}% share · $period',
      ));
    }

    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو الواردات' : 'IMPORT GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }

  // Total Trade: TOTAL TRADE · IMPORTS · NON-OIL EXP · RE-EXPORTS · TRADE
  // GROWTH. Flow cards appear only when their merged source is present.
  List<Widget> _tradeChips() {
    final period = data.latestPeriod;
    final chips = <Widget>[];
    String mn(double v) => NumberFormatter.full(v);

    chips.add(_StatChip(
      overline: isAr ? 'إجمالي التجارة' : 'TOTAL TRADE',
      value: mn(data.tradeTotalLatest),
      caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
    ));

    final imp = data.tradeFlow('IMP');
    if (imp != null) {
      chips.add(_StatChip(
        overline: isAr ? 'الواردات' : 'IMPORTS',
        value: mn(imp),
        caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
      ));
    }
    final nonOil = data.tradeFlow('NONOIL_EXP');
    if (nonOil != null) {
      chips.add(_StatChip(
        overline: isAr ? 'صادرات غير نفطية' : 'NON-OIL EXP',
        value: mn(nonOil),
        caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
      ));
    }
    final reExp = data.tradeFlow('REEXP');
    if (reExp != null) {
      chips.add(_StatChip(
        overline: isAr ? 'إعادة التصدير' : 'RE-EXPORTS',
        value: mn(reExp),
        caption: isAr ? 'مليون درهم · $period' : 'AED Mn · $period',
      ));
    }
    final yoy = data.tradeTotalYoY;
    if (yoy != null) {
      chips.add(_StatChip(
        overline: isAr ? 'نمو التجارة' : 'TRADE GROWTH',
        value: NumberFormatter.percent(yoy),
        caption: isAr ? 'سنوي $period' : 'YoY $period',
        valueColor: yoy < 0 ? AppColors.error : AppColors.success,
      ));
    }
    return chips;
  }


  List<Widget> _sectorChips() {
    if (!_healthFacilityIds.contains(data.meta.id)) return const [];
    final byLevel = data.byLevel;
    final gov = byLevel['GOV']?.isNotEmpty == true ? byLevel['GOV']!.last.value : null;
    final prv = byLevel['PRV']?.isNotEmpty == true ? byLevel['PRV']!.last.value : null;
    if (gov == null && prv == null) return const [];
    final total = data.latestValue;
    final period = data.latestPeriod;
    final unitLabel = data.meta.id == 'health_hospital_beds'
        ? (isAr ? 'سرير' : 'beds')
        : (isAr ? 'منشأة' : 'facilities');
    String pctOf(double? v) =>
        (v == null || total == 0) ? '' : '${(v / total * 100).toStringAsFixed(1)}%';
    return [
      _StatChip(
        overline: isAr ? 'إجمالي $period' : '$period TOTAL',
        value: NumberFormatter.full(total),
        caption: unitLabel,
      ),
      if (gov != null)
        _StatChip(
          overline: isAr ? 'حكومي' : 'GOVERNMENT',
          value: NumberFormatter.full(gov),
          caption: pctOf(gov),
        ),
      if (prv != null)
        _StatChip(
          overline: isAr ? 'خاص' : 'PRIVATE',
          value: NumberFormatter.full(prv),
          caption: pctOf(prv),
        ),
    ];
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.63,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.slate900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.slate400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Full data table (all available data) ─────────────────────────────────────

class _FullDataTable extends StatefulWidget {
  const _FullDataTable(
      {required this.series,
      required this.isAr,
      this.isPercent = false,
      this.isDecimal = false,
      this.unitLabel = ''});
  final List<DataPoint> series;
  final bool isAr;
  final bool isPercent;
  final bool isDecimal;
  final String unitLabel;

  @override
  State<_FullDataTable> createState() => _FullDataTableState();
}

class _FullDataTableState extends State<_FullDataTable> {
  // Rows shown before the "See More" toggle expands the table.
  static const _collapsedRows = 10;
  bool _expanded = false;

  bool get _isAr => widget.isAr;

  /// "VALUE" column header with the unit appended, e.g. "VALUE (Persons)".
  String _valueHeader() {
    final base = _isAr ? 'القيمة' : 'VALUE';
    final u = widget.unitLabel.trim();
    if (widget.isPercent || u.isEmpty) return base;
    return '$base ($u)';
  }

  String _fmtV(double v) => widget.isPercent
      ? '${v.toStringAsFixed(1)}%'
      : widget.isDecimal
          ? v.toStringAsFixed(1)
          : NumberFormatter.full(v);

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr;
    // Deduplicate by timePeriod — keep last entry per period (most specific)
    final seen = <String>{};
    final unique = widget.series.reversed
        .where((p) => seen.add(p.timePeriod))
        .toList();

    // Collapsed view shows only the first [_collapsedRows]; YoY is still
    // computed against the FULL list so the last visible row stays correct.
    final hasMore = unique.length > _collapsedRows;
    final visibleCount =
        (_expanded || !hasMore) ? unique.length : _collapsedRows;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(isAr ? 'السنة' : 'YEAR',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                Expanded(
                  child: Text(_valueHeader(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
                SizedBox(
                  width: 60,
                  child: Text(isAr ? 'س/س' : 'YoY',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: AppColors.slate600)),
                ),
              ],
            ),
          ),

          // ── Data rows (sliced to visibleCount when collapsed) ────────────
          ...unique.take(visibleCount).toList().asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            // YoY: compare to next item (which is the previous year, since reversed)
            double? yoy;
            if (idx < unique.length - 1) {
              final prev = unique[idx + 1].value;
              if (prev != 0) yoy = ((pt.value - prev) / prev) * 100;
            }

            final isOdd = idx.isOdd;

            return Container(
              color: isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Year — fixed width, left aligned
                  SizedBox(
                    width: 48,
                    child: Text(
                      pt.timePeriod,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // Value — flex, center aligned
                  Expanded(
                    child: Text(
                      _fmtV(pt.value),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  // YoY badge — fixed width, center aligned
                  SizedBox(
                    width: 60,
                    child: Align(
                      alignment: Alignment.center,
                      child: yoy == null
                          ? const Text('—',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400))
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: yoy >= 0
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${yoy >= 0 ? '↑' : '↓'} ${yoy.abs().round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: yoy >= 0
                                      ? const Color(0xFF065F46)
                                      : const Color(0xFF991B1B),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── See More / See Less toggle (only when there are extra rows) ──
          if (hasMore)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.pearlGray),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? (isAr ? 'عرض أقل' : 'See Less')
                          : (isAr
                              ? 'عرض المزيد (${unique.length - _collapsedRows})'
                              : 'See More (${unique.length - _collapsedRows})'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.demBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.demBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

// ─── Gender data table (Year | Male | Female | Total) ─────────────────────────

class _GenderDataTable extends StatefulWidget {
  const _GenderDataTable({
    required this.total,
    required this.male,
    required this.female,
    required this.isAr,
  });

  final List<DataPoint> total;
  final List<DataPoint> male;
  final List<DataPoint> female;
  final bool isAr;

  @override
  State<_GenderDataTable> createState() => _GenderDataTableState();
}

class _GenderDataTableState extends State<_GenderDataTable> {
  static const _collapsedRows = 10;
  bool _expanded = false;

  String _fmt(double v) => NumberFormatter.full(v);

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isAr;
    final maleMap = {for (final p in widget.male) p.timePeriod: p.value};
    final femaleMap = {for (final p in widget.female) p.timePeriod: p.value};

    final seen = <String>{};
    final rows =
        widget.total.reversed.where((p) => seen.add(p.timePeriod)).toList();

    final hasMore = rows.length > _collapsedRows;
    final visibleCount =
        (_expanded || !hasMore) ? rows.length : _collapsedRows;

    const headerStyle = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600,
      letterSpacing: 0.4, color: AppColors.slate600,
    );

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Container(
            color: AppColors.pearlGray,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 44, child: Text(isAr ? 'السنة' : 'YEAR', style: headerStyle)),
                Expanded(child: Text(isAr ? 'ذكور' : 'MALE', textAlign: TextAlign.right, style: headerStyle)),
                Expanded(child: Text(isAr ? 'إناث' : 'FEMALE', textAlign: TextAlign.right, style: headerStyle)),
                Expanded(child: Text(isAr ? 'الإجمالي' : 'TOTAL', textAlign: TextAlign.right, style: headerStyle)),
              ],
            ),
          ),
          ...rows.take(visibleCount).toList().asMap().entries.map((e) {
            final idx = e.key;
            final pt = e.value;
            final m = maleMap[pt.timePeriod];
            final f = femaleMap[pt.timePeriod];
            return Container(
              color: idx.isOdd ? AppColors.offWhite : AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(pt.timePeriod,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ),
                  Expanded(
                    child: Text(
                      m != null ? _fmt(m) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f != null ? _fmt(f) : '—',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: AppColors.slate600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _fmt(pt.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.demBlue,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── See More / See Less toggle ──────────────────────────────────
          if (hasMore)
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.pearlGray)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? (isAr ? 'عرض أقل' : 'See Less')
                          : (isAr
                              ? 'عرض المزيد (${rows.length - _collapsedRows})'
                              : 'See More (${rows.length - _collapsedRows})'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.demBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.demBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
