// lib/features/indicator_detail/presentation/widgets/breakdown_section.dart
//
// Breakdown section with tab bar: Overall | By Emirate | By Gender | By Nationality.
// Each tab shows a list of horizontal progress bars with label + value + %.
// Tabs are only shown if the underlying data is available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/data_point.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

// ─── Breakdown item model ─────────────────────────────────────────────────────

class BreakdownItem {
  const BreakdownItem({
    required this.label,
    required this.value,
    required this.percentage,
    this.isPercent = false,
    this.valueText,
  });
  final String label;
  final double value;
  final double percentage;

  /// When true, [value] is itself a percentage share — the trailing number
  /// renders as "X.X%" and the bar length uses [value] directly.
  final bool isPercent;

  /// Optional preformatted trailing label (e.g. "119.7 mm", "622.0 MCM").
  /// Overrides the default numeric formatting when set.
  final String? valueText;
}

// ─── Emirate name mapping ─────────────────────────────────────────────────────

const _emirateNames = {
  'AE-AZ': 'Abu Dhabi',
  'AE-DU': 'Dubai',
  'AE-SH': 'Sharjah',
  'AE-AJ': 'Ajman',
  'AE-RK': 'Ras Al Khaimah',
  'AE-FJ': 'Fujairah',
  'AE-UQ': 'Umm Al Quwain',
};

// Gender code variants across FCSC dataflows → display label.
const _genderNames = {
  'M': 'Male',
  'F': 'Female',
  'MALE': 'Male',
  'FEMALE': 'Female',
  '1': 'Male',
  '2': 'Female',
};

// Citizenship / nationality code variants across FCSC dataflows → display label.
const _citizenshipNames = {
  'EMIRATI': 'Emirati',
  'NON-EMIRATI': 'Non-Emirati',
  'NON_EMIRATI': 'Non-Emirati',
  'CIT': 'Emirati',
  'NCIT': 'Non-Emirati',
  'NON_CIT': 'Non-Emirati',
  'NAT': 'Emirati',
  'NON_NAT': 'Non-Emirati',
  'CITIZEN': 'Emirati',
  'NON_CITIZEN': 'Non-Emirati',
  'LOCAL': 'Emirati',
  'EXPAT': 'Non-Emirati',
  'NATIONAL': 'Emirati',
};

// Education level code variants → display label.
const _levelNames = {
  'NURSERY': 'Nursery',
  'NUR': 'Nursery',
  'NURS': 'Nursery',          // DF_EDU_STUD
  'KG': 'Kindergarten',
  'CYC1': 'Cycle 1',          // DF_EDU_STUD
  'CYC2': 'Cycle 2',          // DF_EDU_STUD
  'VOC': 'Post-Secondary',    // DF_EDU_STUD (Post-Secondary Non-Tertiary)
  // DF_HE_STUDENTS_ARG higher-education levels
  'BCH': 'Bachelor',
  'MS': "Master's",
  'SCT': 'Short Cycle',
  'DC': 'PhD / Equiv.',
  // DF_HEALTH_FACILITIES sector
  'GOV': 'Government',
  'PRV': 'Private',
  'KINDERGARTEN': 'Kindergarten',
  'PRE_PRIMARY': 'Kindergarten',
  'CYCLE1': 'Cycle 1',
  'CYCLE_1': 'Cycle 1',
  'C1': 'Cycle 1',
  'PRIMARY': 'Cycle 1',
  'CYCLE2': 'Cycle 2',
  'CYCLE_2': 'Cycle 2',
  'C2': 'Cycle 2',
  'PREPARATORY': 'Cycle 2',
  'SECONDARY': 'Secondary',
  'POST_SECONDARY': 'Post-Sec.',
  'POSTSECONDARY': 'Post-Sec.',
  'POST_SEC': 'Post-Sec.',
  // ── DF_LFEP_ED (Employed by Education) codes ──
  'ILLIT': 'Illiterate',
  'RANDW': 'Reads & Writes',
  'PRI': 'Primary',
  'LSEC': 'Lower Secondary',
  'SEC': 'Upper Secondary',
  'PSNT': 'Post-Secondary Non-Tertiary',
  'SCTE': 'Short-Cycle Tertiary',
  'BACH': 'Bachelor',
  'HDIP': 'Higher Diploma',
  'MAST': 'Master',
  'DOCT': 'Doctoral',
  'NO_STA': 'Not Stated',
  // ── DF_MR_NA / DF_DV_NA marriage & divorce couple-type codes ──
  'M_TOT': 'Total', 'D_TOT': 'Total',
  'M_EM_EF': 'Emirati H · Emirati W', 'D_EM_EF': 'Emirati H · Emirati W',
  'M_EM_NEF': 'Emirati H · Non-Emirati W', 'D_EM_NEF': 'Emirati H · Non-Emirati W',
  'M_NEM_EF': 'Non-Emirati H · Emirati W', 'D_NEM_EF': 'Non-Emirati H · Emirati W',
  'M_NEM_NEF': 'Non-Emirati H · Non-Emirati W',
  'D_NEW_NEF': 'Non-Emirati H · Non-Emirati W',
  'D_NEM_NEF': 'Non-Emirati H · Non-Emirati W',
  // ── DF_LFEP_ECON (Employed by Economic Activity) ISIC sector codes ──
  'A': 'Agriculture & Fishing',
  'B': 'Mining & Quarrying',
  'C': 'Manufacturing',
  'D': 'Electricity & Gas',
  'E': 'Water & Waste',
  'F': 'Construction',
  'G': 'Wholesale & Retail Trade',
  'H': 'Transportation & Storage',
  'I': 'Accommodation & Food',
  'J': 'Information & Communication',
  'K': 'Financial & Insurance',
  'L': 'Real Estate',
  'M': 'Professional & Technical',
  'N': 'Administrative & Support',
  'O': 'Public Administration',
  'P': 'Education',
  'Q': 'Health & Social Work',
  'R': 'Arts & Recreation',
  'S': 'Other Services',
  'X1': 'Households as Employers',
  'X2': 'Extraterritorial Orgs',
  'X3': 'Unspecified',
};

// DF_LFEP_SECT (Employment by Sector) codes — kept separate because some codes
// (e.g. 'PRI') collide with education codes ('PRI' = Primary).
const _sectorNames = {
  'PRI': 'Private Sector',
  'PRH': 'Private Household',
  'SHA': 'Shared',
  'LOC': 'Local Government',
  'FED': 'Federal Government',
  'FOR': 'Foreign',
  'NON': 'Non-profit Orgs',
  'WIT': 'Without Establishment',
  'DIP': 'Diplomatic Authority',
  'OTH': 'Other',
  'NO_STA': 'Not Stated',
};

// DF_LFEP_OCC (Workforce by Occupation) ISCO major-group codes — kept separate
// because single-letter / short codes (e.g. 'MAN', 'SERV') would otherwise be
// ambiguous against the education/econ maps.
const _occupationNames = {
  'MAN': 'Managers',
  'PROF': 'Professionals',
  'TECH': 'Technicians & Assoc. Professionals',
  'CLER': 'Clerical Support',
  'SERV': 'Service & Sales',
  'SKIL': 'Skilled Agricultural & Fishery',
  'CRAF': 'Craft & Related Trades',
  'PLAN': 'Plant & Machine Operators',
  'ELEM': 'Elementary Occupations',
  'NO_STA': 'Not Stated',
};

String _levelLabel(String code) =>
    _levelNames[code.toUpperCase()] ?? _prettifyCode(code);

/// Turns SDMX age-band codes into readable labels:
/// "Y15T19" → "15–19", "Y_GE65" → "65+", "25-29" → "25–29".
// Livestock LS_AGE class codes → readable labels (shared across camel/cattle/
// goat; the threshold differs per species but the codes are consistent).
const _livestockAgeNames = {
  'L4YR': 'Less than 4 years',
  '4YR': '4 years and above',
  '4YR_MIL': 'Milch (≥4 yrs)',
  '4YR_NMIL': 'Non-milch (≥4 yrs)',
  'L3YR': 'Less than 3 years',
  '3YR': '3 years and above',
  '3YR_MIL': 'Milch (≥3 yrs)',
  '3YR_NMIL': 'Non-milch (≥3 yrs)',
  'L1YR': 'Less than 1 year',
  '1YR': '1 year and above',
  '1YR_MIL': 'Milch (≥1 yr)',
  '1YR_NMIL': 'Non-milch (≥1 yr)',
};

String _livestockAgeLabel(String code) =>
    _livestockAgeNames[code.toUpperCase()] ?? _ageLabel(code);

// DF_CLIMATE_RAIN weather-station codes → readable names.
const _stationNames = {
  'ADWS': 'Abu Dhabi Airport',
  'AAWS': 'Al Ain Airport',
  'DUWS': 'Dubai Airport',
  'SHWS': 'Sharjah Airport',
  'RKWS': 'Ras Al Khaimah',
  'FJWS': 'Fujairah Airport',
  'AJWS': 'Ajman',
  'UQWS': 'Umm Al Quwain',
};

// DF_PW produced-water entity codes → readable names.
const _waterEntityNames = {
  'EAD':  'Dept of Energy — Abu Dhabi',
  'DEWA': 'Dubai (DEWA)',
  'SEWA': 'Sharjah (SEWA)',
  'EWE':  'Etihad Water & Electricity',
};

// DF_PW water-source codes → readable names.
const _waterSourceNames = {
  'SW':   'Sea Water',
  'DSW':  'Desalinated Sea Water',
  'GW':   'Ground Water',
  'GWWD': 'Ground Water (no desal.)',
};

// DF_GEN_TYPE generator-type codes → readable names.
// DF_RE renewable plant-type codes → readable names.
const _plantTypeNames = {
  'SP':  'Solar Photovoltaic',
  'CP':  'Concentrated Solar (CSP)',
  'WT':  'Wind Turbine',
  'WTE': 'Waste to Energy',
  'LG':  'Biogas',
};

// DF_CO crude-oil sector codes → readable names.
const _oilSectorNames = {
  'RE': 'Reserves',
  'PR': 'Production',
  'EX': 'Exports',
  'IM': 'Imports',
};

// DF_NR reserve-type codes → readable names.
const _reserveTypeNames = {
  'MRN': 'Marine',
  'TRS': 'Terrestrial',
  'RAM': 'Ramsar Wetlands',
};

String _ageLabel(String code) {
  final c = code.toUpperCase();
  if (c == 'NO_STA' || c == 'NOSTA' || c == 'NS') return 'Not Stated';
  final ge = RegExp(r'Y?_?GE_?(\d+)').firstMatch(c);
  if (ge != null) return '${ge.group(1)}+';
  final lt = RegExp(r'Y?_?LT_?(\d+)').firstMatch(c);
  if (lt != null) return '<${lt.group(1)}';
  final range = RegExp(r'Y?(\d+)[T\-_](\d+)').firstMatch(c);
  if (range != null) return '${range.group(1)}–${range.group(2)}';
  return _prettifyCode(code);
}

String _genderLabel(String code) =>
    _genderNames[code.toUpperCase()] ?? _prettifyCode(code);

/// Prettifies an unknown dimension code into a human label
/// (e.g. "NON_EMIRATI" → "Non Emirati").
String _prettifyCode(String code) {
  // Common "not stated / not specified" sentinels across dataflows.
  final upper = code.trim().toUpperCase();
  const notStated = {
    'NO_STA', 'NOSTA', 'NS', 'NOT_STATED', 'NOTSTATED',
    'NOT_SPECIFIED', 'UNSPECIFIED', 'UNKNOWN', '_O',
  };
  if (notStated.contains(upper)) return 'Not Stated';
  final cleaned = code.replaceAll(RegExp(r'[_\-]+'), ' ').trim().toLowerCase();
  if (cleaned.isEmpty) return code;
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class BreakdownSection extends ConsumerStatefulWidget {
  const BreakdownSection({
    super.key,
    required this.data,
    this.accentColor = AppColors.demBlue,
  });
  final IndicatorData data;

  /// Accent used for the breakdown bars and the active tab indicator.
  /// Defaults to the standard Demography blue.
  final Color accentColor;

  @override
  ConsumerState<BreakdownSection> createState() => _BreakdownSectionState();
}

class _BreakdownSectionState extends ConsumerState<BreakdownSection> {
  int _activeTab = 0;

  /// Indicators whose values are % shares (distribution dataflows) rather than
  /// absolute counts. For these, breakdown bars show the raw share directly.
  static const _shareIds = {
    'labour_employed_age_gender',
    'labour_employed_education',
    'labour_economic_activity',
    'labour_employment_sector',
    'labour_unemployment_education',
    'labour_workforce_occupation',
    'labour_unemployment_age_gender',
  };

  bool get _isShareData => _shareIds.contains(widget.data.meta.id);

  // ─── Compute breakdowns from IndicatorData ────────────────────────────────

  List<BreakdownItem> _emirateBreakdown() {
    final total = widget.data.latestValue;
    if (total == 0) return [];
    final result = <BreakdownItem>[];
    widget.data.byEmirate.forEach((code, series) {
      if (series.isNotEmpty && _emirateNames.containsKey(code)) {
        final val = series.last.value;
        result.add(BreakdownItem(
          label: _emirateNames[code]!,
          value: val,
          percentage: val / total * 100,
        ));
      }
    });
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  List<BreakdownItem> _genderBreakdown() {
    final total = widget.data.latestValue;
    if (total == 0) return [];
    final result = <BreakdownItem>[];
    widget.data.byGender.forEach((code, series) {
      if (series.isEmpty) return;
      final val = series.last.value;
      result.add(BreakdownItem(
        label: _genderNames[code.toUpperCase()] ?? _prettifyCode(code),
        value: val,
        percentage: total == 0 ? 0 : val / total * 100,
      ));
    });
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  List<BreakdownItem> _citizenshipBreakdown() {
    final total = widget.data.latestValue;
    if (total == 0) return [];
    final result = <BreakdownItem>[];
    widget.data.byCitizenship.forEach((code, series) {
      if (series.isEmpty) return;
      final val = series.last.value;
      if (val == 0) return; // skip empty categories
      result.add(BreakdownItem(
        label: _citizenshipNames[code.toUpperCase()] ?? _prettifyCode(code),
        value: val,
        percentage: total == 0 ? 0 : val / total * 100,
      ));
    });
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  bool get _isOccupation =>
      widget.data.meta.id == 'labour_workforce_occupation';

  List<BreakdownItem> _levelBreakdown() {
    final share = _isShareData;
    final isSector = widget.data.isEmploymentSector;
    final isOccupation = _isOccupation;
    final total = widget.data.latestValue;
    final result = <BreakdownItem>[];
    widget.data.byLevel.forEach((code, series) {
      if (series.isEmpty) return;
      final val = series.last.value;
      if (val == 0) return; // skip empty categories (e.g. "Not Stated" = 0)
      result.add(BreakdownItem(
        label: isSector
            ? (_sectorNames[code.toUpperCase()] ?? _prettifyCode(code))
            : isOccupation
                ? (_occupationNames[code.toUpperCase()] ?? _prettifyCode(code))
                : _levelLabel(code),
        value: val,
        percentage: share ? val : (total == 0 ? 0 : val / total * 100),
        isPercent: share,
      ));
    });
    // Counts, sector shares, top-category shares: rank biggest-first.
    // Employed-by-education shares keep natural (curriculum) order.
    final rankBySize = !share ||
        isSector ||
        isOccupation ||
        widget.data.isTopCategoryShare ||
        widget.data.meta.id == 'labour_unemployment_education';
    if (rankBySize) {
      result.sort((a, b) => b.value.compareTo(a.value));
    }
    return result;
  }

  /// Label for a category code, indicator-aware (sector vs education/econ names).
  String _categoryLabel(String code) {
    if (widget.data.isEmploymentSector) {
      return _sectorNames[code.toUpperCase()] ?? _prettifyCode(code);
    }
    if (_isOccupation) {
      return _occupationNames[code.toUpperCase()] ?? _prettifyCode(code);
    }
    // Economic activity (A–S, X1–X3) and education levels both resolve via
    // the shared _levelNames map / prettify fallback.
    return _levelLabel(code);
  }

  /// Per-level Male & Female pairs for the grouped "Male vs Female" tab,
  /// sorted by total (M+F) descending.
  List<_GenderComparePair> _genderComparePairs() {
    final male = widget.data.latestCategoryByGender('M');
    final female = widget.data.latestCategoryByGender('F');
    final codes = {...male.keys, ...female.keys};
    final pairs = <_GenderComparePair>[];
    for (final code in codes) {
      final m = male[code] ?? 0;
      final f = female[code] ?? 0;
      if (m == 0 && f == 0) continue;
      pairs.add(_GenderComparePair(_categoryLabel(code), m, f));
    }
    pairs.sort((a, b) => b.total.compareTo(a.total));
    return pairs;
  }

  /// Single-gender level breakdown (the "By Male" / "By Female" tabs for
  /// Labor Force by Occupation): each category's share for [genderCode],
  /// sorted biggest-first.
  List<BreakdownItem> _singleGenderLevelBreakdown(String genderCode) {
    final byCode = widget.data.latestCategoryByGender(genderCode);
    final result = <BreakdownItem>[];
    byCode.forEach((code, val) {
      if (val == 0) return;
      result.add(BreakdownItem(
        label: _categoryLabel(code),
        value: val,
        percentage: val,
        isPercent: true,
      ));
    });
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  List<BreakdownItem> _genderLevelBreakdown() {
    final share = _isShareData;
    final total = widget.data.latestValue;
    final result = <BreakdownItem>[];
    widget.data.byGenderLevel.forEach((key, series) {
      if (series.isEmpty) return;
      final parts = key.split('|');
      final g = parts.isNotEmpty ? _genderLabel(parts[0]) : '';
      final lvl = parts.length > 1 ? _levelLabel(parts[1]) : '';
      final gShort = g.isNotEmpty ? g[0] : '';
      final val = series.last.value;
      if (val == 0) return; // skip empty categories (e.g. "Not Stated" = 0)
      result.add(BreakdownItem(
        label: '$gShort – $lvl',
        value: val,
        percentage: share ? val : (total == 0 ? 0 : val / total * 100),
        isPercent: share,
      ));
    });
    if (!share) result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  List<BreakdownItem> _ageBreakdown() {
    // Age datasets (DF_LFEP_AGE) are % distributions — the API value IS the
    // share. Show it directly (no re-normalising) and keep natural age order.
    final result = <BreakdownItem>[];
    widget.data.byAge.forEach((code, series) {
      if (series.isEmpty) return;
      final val = series.last.value;
      if (val == 0) return; // skip empty bands
      result.add(BreakdownItem(
        label: _ageLabel(code),
        value: val,
        percentage: val,
        isPercent: true,
      ));
    });
    return result; // natural insertion (age band) order
  }

  List<BreakdownItem> _ageGenderBreakdown() {
    final result = <BreakdownItem>[];
    widget.data.byAgeGender.forEach((key, series) {
      if (series.isEmpty) return;
      final parts = key.split('|');
      final g = parts.isNotEmpty ? _genderLabel(parts[0]) : '';
      final age = parts.length > 1 ? _ageLabel(parts[1]) : '';
      final gShort = g.isNotEmpty ? g[0] : '';
      final val = series.last.value;
      if (val == 0) return; // skip empty bands
      result.add(BreakdownItem(
        label: '$gShort – $age',
        value: val,
        percentage: val,
        isPercent: true,
      ));
    });
    return result;
  }

  // ── Employed by Age & Gender (dedicated redesign) ─────────────────────────

  /// Natural age-band order (15-19 → 65+) used by the dedicated layout.
  static const _ageBandOrder = [
    'Y15T19', 'Y20T24', 'Y25T29', 'Y30T34', 'Y35T39', 'Y40T44',
    'Y45T49', 'Y50T54', 'Y55T59', 'Y60T64', 'Y_GE65',
  ];

  /// By Age (Total) items in natural age order (NOT value-sorted).
  List<BreakdownItem> _ageOrderedTotalItems() {
    final byAge = widget.data.byAge;
    final result = <BreakdownItem>[];
    for (final code in _ageBandOrder) {
      final series = byAge[code];
      if (series == null || series.isEmpty) continue;
      final val = series.last.value;
      result.add(BreakdownItem(
        label: _ageLabel(code),
        value: val,
        percentage: val,
        isPercent: true,
      ));
    }
    // Fallback: include any band not covered by the canonical order.
    if (result.isEmpty) {
      byAge.forEach((code, series) {
        if (series.isEmpty) return;
        final val = series.last.value;
        result.add(BreakdownItem(
          label: _ageLabel(code),
          value: val,
          percentage: val,
          isPercent: true,
        ));
      });
    }
    return result;
  }

  /// By Age (Total) items sorted by value DESCENDING (Unemployment by Age).
  List<BreakdownItem> _ageTotalSortedItems() {
    final items = _ageOrderedTotalItems()
      ..sort((a, b) => b.value.compareTo(a.value));
    return items;
  }

  /// Single-gender age-profile items sorted by value DESCENDING. [genderCode]
  /// is 'M' or 'F'; reads byAgeGender ("GENDER|AGECODE").
  List<BreakdownItem> _ageGenderSortedItems(String genderCode) {
    final result = <BreakdownItem>[];
    widget.data.byAgeGender.forEach((key, series) {
      if (series.isEmpty) return;
      final parts = key.split('|');
      if (parts.length < 2 || parts[0].toUpperCase() != genderCode) return;
      final val = series.last.value;
      result.add(BreakdownItem(
        label: _ageLabel(parts[1]),
        value: val,
        percentage: val,
        isPercent: true,
      ));
    });
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  /// Per-age-band Male & Female pairs in NATURAL AGE ORDER (not value-sorted).
  List<_GenderComparePair> _ageComparePairs() {
    // Build Male / Female maps keyed by age code from byAgeGender
    // ("GENDER|AGECODE" → series), since this dataflow carries the split in the
    // AGE dimension (not `level`).
    final male = <String, double>{};
    final female = <String, double>{};
    widget.data.byAgeGender.forEach((key, series) {
      if (series.isEmpty) return;
      final parts = key.split('|');
      if (parts.length < 2) return;
      final g = parts[0].toUpperCase();
      final age = parts[1];
      final v = series.last.value;
      if (g == 'M') male[age] = v;
      if (g == 'F') female[age] = v;
    });
    final pairs = <_GenderComparePair>[];
    final seen = <String>{};
    void addCode(String code) {
      if (seen.contains(code)) return;
      seen.add(code);
      final m = male[code] ?? 0;
      final f = female[code] ?? 0;
      if (m == 0 && f == 0) return;
      pairs.add(_GenderComparePair(_ageLabel(code), m, f));
    }
    for (final code in _ageBandOrder) {
      addCode(code);
    }
    // Any remaining (non-canonical) codes, appended in encounter order.
    for (final code in {...male.keys, ...female.keys}) {
      addCode(code);
    }
    return pairs;
  }

  /// Five grouped age cohorts (summed Total %), in fixed order.
  List<BreakdownItem> _ageCohortItems() {
    final byAge = widget.data.byAge;
    double sum(List<String> codes) {
      var t = 0.0;
      for (final c in codes) {
        final s = byAge[c];
        if (s != null && s.isNotEmpty) t += s.last.value;
      }
      return t;
    }

    final cohorts = <(String, List<String>)>[
      ('Youth 15–24', ['Y15T19', 'Y20T24']),
      ('Young 25–34', ['Y25T29', 'Y30T34']),
      ('Prime 35–44', ['Y35T39', 'Y40T44']),
      ('Mid-Sr 45–59', ['Y45T49', 'Y50T54', 'Y55T59']),
      ('Senior 60+', ['Y60T64', 'Y_GE65']),
    ];
    return [
      for (final (label, codes) in cohorts)
        BreakdownItem(
          label: label,
          value: sum(codes),
          percentage: sum(codes),
          isPercent: true,
        ),
    ];
  }

  // ── Livestock (head-count census) breakdowns ─────────────────────────────

  bool get _isLivestock => widget.data.isLivestock;

  /// Bars sized relative to the largest value in the set; numbers show the raw
  /// head count (not a percentage).
  List<BreakdownItem> _livestockBars(Map<String, double> cells,
      String Function(String code) label) {
    if (cells.isEmpty) return const [];
    final maxVal = cells.values.fold<double>(0, (m, v) => v > m ? v : m);
    final items = cells.entries
        .map((e) => BreakdownItem(
              label: label(e.key),
              value: e.value,
              percentage: maxVal == 0 ? 0 : e.value / maxVal * 100,
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return items;
  }

  /// By Age Class — gender × child age-class cells (excludes the parent total).
  List<BreakdownItem> _livestockAgeClassBreakdown() => _livestockBars(
        widget.data.livestockAgeClassCells,
        (key) {
          final parts = key.split('|');
          final g = parts.isNotEmpty ? _genderLabel(parts[0]) : '';
          final age = parts.length > 1 ? _livestockAgeLabel(parts[1]) : '';
          final gShort = g.isNotEmpty ? g[0] : '';
          return '$gShort · $age';
        },
      );

  /// Female Detail — Milch / Non-milch / young female classes.
  List<BreakdownItem> _livestockFemaleBreakdown() => _livestockBars(
        widget.data.livestockFemaleDetail,
        _livestockAgeLabel,
      );

  // ── Rainfall / Produced Water breakdowns (unit-suffixed bars) ────────────

  bool get _isRainfall => widget.data.isRainfall;
  bool get _isProducedWater => widget.data.isProducedWater;

  /// Bars sized relative to the largest value, with a unit-suffixed number
  /// (e.g. "119.7 mm", "622.0 MCM"). Sorted biggest-first.
  List<BreakdownItem> _unitBars(
      Map<String, double> cells, String Function(String) label, String unit) {
    if (cells.isEmpty) return const [];
    final maxVal = cells.values.fold<double>(0, (m, v) => v > m ? v : m);
    final items = cells.entries
        .map((e) => BreakdownItem(
              label: label(e.key),
              value: e.value,
              percentage: maxVal == 0 ? 0 : e.value / maxVal * 100,
              valueText: '${e.value.toStringAsFixed(1)} $unit',
            ))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return items;
  }

  List<BreakdownItem> _rainfallByStation() => _unitBars(
        widget.data.rainfallByStation,
        (c) => _stationNames[c.toUpperCase()] ?? _prettifyCode(c),
        'mm',
      );

  List<BreakdownItem> _waterByEntity() => _unitBars(
        widget.data.producedWaterByEntity,
        (c) => _waterEntityNames[c.toUpperCase()] ?? _prettifyCode(c),
        'MCM',
      );

  List<BreakdownItem> _waterBySource() => _unitBars(
        widget.data.producedWaterBySource,
        (c) => _waterSourceNames[c.toUpperCase()] ?? _prettifyCode(c),
        'MCM',
      );

  // ── Energy / Reserves breakdowns ──────────────────────────────────────────

  bool get _isCrudeOil => widget.data.isCrudeOil;
  bool get _isRenewable => widget.data.isRenewableEnergy;
  bool get _isReserves => widget.data.isNaturalReserves;
  bool get _isRamsar => widget.data.isRamsarWetlands;

  List<BreakdownItem> _renewableByCapacity() => _unitBars(
        widget.data.categoryBreakdown(reMeasure: 'REP'),
        (c) => _plantTypeNames[c.toUpperCase()] ?? _prettifyCode(c),
        'MW',
      );

  List<BreakdownItem> _renewableByProduction() => _unitBars(
        widget.data.categoryBreakdown(reMeasure: 'EP'),
        (c) => _plantTypeNames[c.toUpperCase()] ?? _prettifyCode(c),
        'GWh',
      );

  List<BreakdownItem> _oilTradeFlow() => _unitBars(
        widget.data.crudeOilTradeFlow,
        (c) => _oilSectorNames[c.toUpperCase()] ?? _prettifyCode(c),
        '000 bbl/d',
      );

  List<BreakdownItem> _reservesByType() => _unitBars(
        widget.data.reservesByType,
        (c) => _reserveTypeNames[c.toUpperCase()] ?? _prettifyCode(c),
        'km²',
      );

  List<BreakdownItem> _reservesByEmirate() => _unitBars(
        widget.data.reservesByEmirate,
        (c) => _emirateNames[c.toUpperCase()] ?? _prettifyCode(c),
        'km²',
      );

  /// Top individual reserve sites (largest first), labelled by site name.
  List<BreakdownItem> _reservesTopSites() {
    final sites = widget.data.nrTopReserves;
    if (sites.isEmpty) return const [];
    final maxVal = sites.first.value;
    return sites
        .map((s) => BreakdownItem(
              label: s.label,
              value: s.value,
              percentage: maxVal == 0 ? 0 : s.value / maxVal * 100,
              valueText: '${s.value.toStringAsFixed(1)} km²',
            ))
        .toList();
  }

  List<BreakdownItem> _ramsarByCohort() => _unitBars(
        widget.data.ramsarByCohort,
        (c) => 'Est. $c',
        'km²',
      );

  /// RAMSAR site counts by type (Marine / Terrestrial) — value text "N sites".
  List<BreakdownItem> _ramsarSiteCount() {
    final rows = widget.data.rwSiteCount;
    if (rows.isEmpty) return const [];
    final maxVal = rows.first.value;
    return rows
        .map((s) => BreakdownItem(
              label: s.label,
              value: s.value,
              percentage: maxVal == 0 ? 0 : s.value / maxVal * 100,
              valueText: '${s.value.toStringAsFixed(0)} sites',
            ))
        .toList();
  }

  List<BreakdownItem> _overallBreakdown() {
    // Livestock: show the per-emirate distribution as the overall view.
    if (_isLivestock) {
      final em = _emirateBreakdown();
      if (em.isNotEmpty) return em;
    }
    // For % distribution indicators a "UAE Total = 100%" row and 100%-each
    // gender rows are meaningless. Show the primary distribution directly
    // (top bands of By Age / By Education), preserving natural order.
    if (_isShareData) {
      final age = _ageBreakdown();
      if (age.isNotEmpty) return age;
      final level = _levelBreakdown();
      if (level.isNotEmpty) return level;
    }

    final total = widget.data.latestValue;
    final emirate = _emirateBreakdown();
    final gender = _genderBreakdown();
    final citizenship = _citizenshipBreakdown();
    final level = _levelBreakdown();
    final age = _ageBreakdown();

    // Marriages / Divorces: Overall = Total + ALL couple-types (no cap), so it
    // stays consistent with the By Type tab.
    if (widget.data.isMarriageDivorce) {
      return [
        BreakdownItem(label: 'Total', value: total, percentage: 100),
        ...level,
      ];
    }

    // Show a mix: total, then gender, then age / level / citizenship / emirates.
    final result = <BreakdownItem>[
      BreakdownItem(label: 'Total', value: total, percentage: 100),
      ...gender,
    ];

    if (age.isNotEmpty) {
      result.addAll(age.take(3));
    } else if (level.isNotEmpty) {
      result.addAll(level.take(3));
    } else if (citizenship.isNotEmpty) {
      result.addAll(citizenship);
    } else if (emirate.length >= 2) {
      result.addAll(emirate.take(2));
    }
    return result;
  }

  // ─── Tab configuration ────────────────────────────────────────────────────

  /// A breakdown tab is shown only when the dataset actually contains that
  /// dimension — driven entirely by the API/data, never forced. This avoids
  /// empty "not available" tabs (e.g. Marriages has no gender/nationality).
  List<_TabDef> _buildTabs(bool isAr) {
    // Unemployment by Age & Gender — By Age Group · Male Profile · Female
    // Profile. Every tab sorted by value descending; bars scale to the data.
    if (widget.data.meta.id == 'labour_unemployment_age_gender') {
      const femaleColor = Color(0xFFC8973A); // gold
      final tabs = <_TabDef>[
        _TabDef(
          isAr ? 'حسب الفئة العمرية' : 'By Age Group',
          () => const <BreakdownItem>[],
          customBuilder: () {
            final items = _ageTotalSortedItems();
            return _AgeBarList(
              items: items,
              colors: [for (final _ in items) AppColors.demBlue],
            );
          },
        ),
      ];
      if (widget.data.latestCategoryByGender('M').isNotEmpty ||
          _ageGenderSortedItems('M').isNotEmpty) {
        tabs.add(_TabDef(
          isAr ? 'ملف الذكور' : 'Male Profile',
          () => const <BreakdownItem>[],
          customBuilder: () {
            final items = _ageGenderSortedItems('M');
            return _AgeBarList(
              items: items,
              colors: [for (final _ in items) AppColors.demBlue],
            );
          },
        ));
      }
      if (_ageGenderSortedItems('F').isNotEmpty) {
        tabs.add(_TabDef(
          isAr ? 'ملف الإناث' : 'Female Profile',
          () => const <BreakdownItem>[],
          customBuilder: () {
            final items = _ageGenderSortedItems('F');
            return _AgeBarList(
              items: items,
              colors: [for (final _ in items) femaleColor],
            );
          },
        ));
      }
      return tabs;
    }

    // Employed by Age & Gender — dedicated three-tab redesign (this indicator
    // only). By Age (Total, color-coded) · Male vs Female · Age Cohorts.
    if (widget.data.meta.id == 'labour_employed_age_gender') {
      final tabs = <_TabDef>[
        _TabDef(
          isAr ? 'حسب العمر' : 'By Age (Total)',
          () => const <BreakdownItem>[],
          customBuilder: () {
            final items = _ageOrderedTotalItems();
            return _AgeBarList(
              items: items,
              colors: [for (final _ in items) AppColors.demBlue],
            );
          },
        ),
        _TabDef(
          isAr ? 'ذكور مقابل إناث' : 'Male vs Female',
          () => const <BreakdownItem>[],
          customBuilder: () =>
              _GenderCompareList(pairs: _ageComparePairs(), isPercent: true),
        ),
        _TabDef(
          isAr ? 'الفئات العمرية' : 'Age Cohorts',
          () => const <BreakdownItem>[],
          customBuilder: () {
            final items = _ageCohortItems();
            return _AgeBarList(
              items: items,
              colors: [for (final _ in items) AppColors.demBlue],
            );
          },
        ),
      ];
      return tabs;
    }
    // Annual Rainfall — By Station only (national average is the headline).
    if (_isRainfall) {
      final tabs = <_TabDef>[];
      if (widget.data.rainfallByStation.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب المحطة' : 'By Station', _rainfallByStation));
      }
      return tabs;
    }
    // Renewable Energy — By Capacity / By Production.
    if (_isRenewable) {
      final tabs = <_TabDef>[];
      if (widget.data.categoryBreakdown(reMeasure: 'REP').isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب القدرة' : 'By Capacity', _renewableByCapacity));
      }
      if (widget.data.categoryBreakdown(reMeasure: 'EP').isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب الإنتاج' : 'By Production', _renewableByProduction));
      }
      return tabs;
    }
    // Crude Oil — By Trade Flow.
    if (_isCrudeOil) {
      final tabs = <_TabDef>[];
      if (widget.data.crudeOilTradeFlow.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب تدفق التجارة' : 'By Trade Flow', _oilTradeFlow));
      }
      return tabs;
    }
    // Protected Natural Areas — By Type / By Emirate / Top Reserves.
    if (_isReserves) {
      final tabs = <_TabDef>[];
      if (widget.data.reservesByType.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب النوع' : 'By Reserve Type', _reservesByType));
      }
      if (widget.data.reservesByEmirate.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _reservesByEmirate));
      }
      if (widget.data.nrTopReserves.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'أكبر المحميات' : 'Top Reserves', _reservesTopSites));
      }
      return tabs;
    }
    // RAMSAR Wetlands — By Type / By Designation Year / Site Count.
    if (_isRamsar) {
      final tabs = <_TabDef>[];
      if (widget.data.reservesByType.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب النوع' : 'By Reserve Type', _reservesByType));
      }
      if (widget.data.ramsarByCohort.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب سنة الإدراج' : 'By Designation Year', _ramsarByCohort));
      }
      if (widget.data.rwSiteCount.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'عدد المواقع' : 'Site Count', _ramsarSiteCount));
      }
      return tabs;
    }
    // Produced Water — By Entity / By Water Source.
    if (_isProducedWater) {
      final tabs = <_TabDef>[];
      if (widget.data.producedWaterByEntity.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الجهة' : 'By Entity', _waterByEntity));
      }
      if (widget.data.producedWaterBySource.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب المصدر' : 'By Water Source', _waterBySource));
      }
      return tabs;
    }
    // Livestock census: a fixed, data-driven set — By Emirate / By Gender /
    // By Age Class / Female Detail. Each tab is shown only if it has data.
    if (_isLivestock) {
      final tabs = <_TabDef>[
        _TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown),
      ];
      if (widget.data.byGender.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الجنس' : 'By Gender', _genderBreakdown));
      }
      if (widget.data.livestockAgeClassCells.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الفئة العمرية' : 'By Age Class',
            _livestockAgeClassBreakdown));
      }
      if (widget.data.livestockFemaleDetail.length >= 2) {
        tabs.add(_TabDef(isAr ? 'تفاصيل الإناث' : 'Female Detail',
            _livestockFemaleBreakdown));
      }
      return tabs;
    }

    // Qualified Teachers: By Gender · By Teaching Level · Male vs Female
    // (grouped comparison; no Overall tab).
    if (widget.data.meta.id == 'teaching_staff') {
      final tabs = <_TabDef>[];
      if (widget.data.byGender.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الجنس' : 'By Gender', _genderBreakdown));
      }
      if (widget.data.byLevel.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب المستوى التعليمي' : 'By Teaching Level', _levelBreakdown));
      }
      if (widget.data.latestCategoryByGender('M').isNotEmpty ||
          widget.data.latestCategoryByGender('F').isNotEmpty) {
        tabs.add(_TabDef(
          isAr ? 'ذكور مقابل إناث' : 'Male vs Female',
          () => const <BreakdownItem>[],
          customBuilder: () => _GenderCompareList(pairs: _genderComparePairs()),
        ));
      }
      if (tabs.isNotEmpty) return tabs;
    }

    // Students by Level (higher education): By Level · By Gender ·
    // Male by Level · Female by Level — counts, matching the approved design.
    if (widget.data.meta.id == 'higher_education') {
      final tabs = <_TabDef>[];
      if (widget.data.byLevel.isNotEmpty) {
        tabs.add(_TabDef(
            isAr ? 'حسب المستوى التعليمي' : 'By Education Level', _levelBreakdown));
      }
      if (widget.data.byGender.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الجنس' : 'By Gender', _genderBreakdown));
      }
      // Single grouped Male-vs-Female comparison (replaces the separate
      // Male by Level / Female by Level tabs).
      if (widget.data.latestCategoryByGender('M').isNotEmpty ||
          widget.data.latestCategoryByGender('F').isNotEmpty) {
        tabs.add(_TabDef(
          isAr ? 'ذكور مقابل إناث' : 'Male vs Female',
          () => const <BreakdownItem>[],
          customBuilder: () => _GenderCompareList(pairs: _genderComparePairs()),
        ));
      }
      if (tabs.isNotEmpty) return tabs;
    }

    // Hospitals / Clinics & Centers / Hospital Beds (DF_HEALTH_FACILITIES):
    // Overall · Government vs Private · By Emirate.
    const healthFacilityIds = {
      'hospitals', 'health_clinics_centers', 'health_hospital_beds',
    };
    if (healthFacilityIds.contains(widget.data.meta.id)) {
      final tabs = <_TabDef>[
        _TabDef(isAr ? 'الإجمالي' : 'Overall', _overallBreakdown),
      ];
      if (widget.data.byLevel.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حكومي مقابل خاص' : 'Government vs Private',
            _levelBreakdown));
      }
      if (widget.data.byEmirate.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown));
      }
      return tabs;
    }

    // Unemployment by Education: By Education / Male / Female / Gender Gap.
    if (widget.data.meta.id == 'labour_unemployment_education' &&
        widget.data.byLevel.isNotEmpty) {
      final tabs = <_TabDef>[
        _TabDef(isAr ? 'حسب التعليم' : 'By Education', _levelBreakdown),
      ];
      final hasM = widget.data.latestCategoryByGender('M').isNotEmpty;
      final hasF = widget.data.latestCategoryByGender('F').isNotEmpty;
      if (hasM || hasF) {
        // Grouped M/F bars per education level (% shares).
        tabs.add(_TabDef(
          isAr ? 'ذكور مقابل إناث' : 'Male vs Female',
          () => const <BreakdownItem>[],
          customBuilder: () =>
              _GenderCompareList(pairs: _genderComparePairs(), isPercent: true),
        ));
        // Flat ranked ♀/♂ list across all levels.
        tabs.add(_TabDef(
          isAr ? 'الفجوة بين الجنسين' : 'Gender Gap',
          () => const <BreakdownItem>[],
          customBuilder: () => _GenderGapList(pairs: _genderComparePairs()),
        ));
      }
      return tabs;
    }

    // Labor Force by Occupation: All Occupations / By Male / By Female.
    if (widget.data.meta.id == 'labour_workforce_occupation' &&
        widget.data.byLevel.isNotEmpty) {
      final tabs = <_TabDef>[
        _TabDef(isAr ? 'كل المهن' : 'All Occupations', _levelBreakdown),
      ];
      if (widget.data.latestCategoryByGender('M').isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'ذكور' : 'By Male',
            () => _singleGenderLevelBreakdown('M')));
      }
      if (widget.data.latestCategoryByGender('F').isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'إناث' : 'By Female',
            () => _singleGenderLevelBreakdown('F')));
      }
      return tabs;
    }

    // Top-category % distributions (Economic Activity, Employment by Sector):
    // only By Level + grouped Male vs Female — no Overall, no separate gender
    // profiles.
    if ((widget.data.isTopCategoryShare || widget.data.isEmploymentSector) &&
        widget.data.byLevel.isNotEmpty) {
      // Workforce by Occupation calls its first tab "All Occupations";
      // Labour Force by Educational Status uses "By Education Level";
      // Employment by Sector uses "Total".
      final id = widget.data.meta.id;
      final firstLabel = id == 'labour_workforce_occupation'
          ? (isAr ? 'كل المهن' : 'All Occupations')
          : id == 'labour_employed_education'
              ? (isAr ? 'حسب المستوى التعليمي' : 'By Education Level')
              : id == 'labour_employment_sector'
                  ? (isAr ? 'الإجمالي' : 'Total')
                  : (isAr ? 'حسب المستوى' : 'By Level');
      final tabs = <_TabDef>[
        _TabDef(firstLabel, _levelBreakdown),
      ];
      if (widget.data.latestCategoryByGender('M').isNotEmpty ||
          widget.data.latestCategoryByGender('F').isNotEmpty) {
        tabs.add(_TabDef(
          isAr ? 'ذكور مقابل إناث' : 'Male vs Female',
          () => const <BreakdownItem>[],
          customBuilder: () => _GenderCompareList(pairs: _genderComparePairs()),
        ));
      }
      // Employment by Sector adds a Trend tab: year-wise share (2020–2024) of
      // the dominant sector (highest latest Total).
      if (id == 'labour_employment_sector') {
        tabs.add(_TabDef(
          isAr ? 'الاتجاه' : 'Trend',
          () => const <BreakdownItem>[],
          customBuilder: () => _SectorTrendList(
            series: widget.data.uaeTotalSeries,
            label: _sectorNames[(widget.data.topSectorCode ?? '').toUpperCase()] ??
                (isAr ? 'القطاع المهيمن' : 'Dominant sector'),
          ),
        ));
      }
      return tabs;
    }

    final tabs = <_TabDef>[
      _TabDef(isAr ? 'الإجمالي' : 'Overall', _overallBreakdown),
    ];
    // Labour (age) indicators: By Age / Age × Gender.
    if (widget.data.byAge.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب العمر' : 'By Age', _ageBreakdown));
    }
    // Marriages / Divorces: By Emirate first, then By Type (couple-type split),
    // mirroring each other exactly.
    if (widget.data.isMarriageDivorce) {
      if (widget.data.byEmirate.isNotEmpty) {
        tabs.add(
            _TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown));
      }
      if (widget.data.byLevel.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب النوع' : 'By Type', _levelBreakdown));
      }
      return tabs;
    }
    // Education indicators: By Level / Gender × Level.
    if (widget.data.byLevel.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب المستوى' : 'By Level', _levelBreakdown));
    }
    if (widget.data.byEmirate.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown));
    }
    // (Top-category share indicators — Economic Activity, Employment by Sector,
    // Unemployment by Education, Workforce by Occupation — are handled earlier
    // with a dedicated By Level + Male vs Female tab set.)
    // Standalone By Gender omitted for % distributions (gender-column totals
    // are each 100%); the gender split is shown via profiles / Age×Gender.
    if (!_isShareData && widget.data.byGender.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الجنس' : 'By Gender', _genderBreakdown));
    }
    if (widget.data.byAgeGender.isNotEmpty) {
      tabs.add(_TabDef(
          isAr ? 'العمر × الجنس' : 'Age × Gender', _ageGenderBreakdown));
    }
    // Gender × Level only for employed-education (not the top-category ones,
    // which use Male/Female profiles above).
    if (widget.data.byGenderLevel.isNotEmpty &&
        !widget.data.isTopCategoryShare &&
        !widget.data.isEmploymentSector) {
      tabs.add(_TabDef(
          isAr ? 'الجنس × المستوى' : 'Gender × Level', _genderLevelBreakdown));
    }
    if (widget.data.byCitizenship.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الجنسية' : 'By Nationality', _citizenshipBreakdown));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final tabs = _buildTabs(isAr);
    if (tabs.isEmpty) return const SizedBox.shrink();

    // Clamp active tab
    if (_activeTab >= tabs.length) _activeTab = 0;
    final activeTab = tabs[_activeTab];
    final items = activeTab.customBuilder != null ? const <BreakdownItem>[] : activeTab.buildFn();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            isAr ? 'التصنيف' : 'Breakdown',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.slate900,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // (Age summary cards moved up into the stats-chips row, above
        // Detailed Data — see _StatsChipsRow.)

        // Tab bar
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.silver, width: 1),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: tabs.asMap().entries.map((e) {
                final active = e.key == _activeTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = e.key),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 10, 14, 10),
                    margin: const EdgeInsets.only(right: 0),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active
                              ? widget.accentColor
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                        color: active
                            ? widget.accentColor
                            : AppColors.slate600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Custom comparison layout (Male vs Female) takes precedence.
        if (activeTab.customBuilder != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: activeTab.customBuilder!(),
          )
        // Bar list
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.slate400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'بيانات هذا التصنيف غير متاحة لهذا المؤشر'
                        : 'This breakdown is not available for this indicator',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.slate400),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _BarList(items: items, accentColor: widget.accentColor),
          ),
      ],
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.buildFn, {this.customBuilder});
  final String label;
  final List<BreakdownItem> Function() buildFn;

  /// When set, this widget is rendered for the tab instead of the standard
  /// [_BarList] (used by the grouped Male-vs-Female comparison).
  final Widget Function()? customBuilder;
}

// ─── Color-coded bar list (Employed by Age) ───────────────────────────────────

/// Like [_BarList] but each bar takes a per-item fill color (color-coded by
/// age band / cohort). Label left · horizontal bar center · % right (bold).
class _AgeBarList extends StatelessWidget {
  const _AgeBarList({required this.items, required this.colors});
  final List<BreakdownItem> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    // Scale bars to the largest value in the list so the top bar fills the
    // track and the rest scale proportionally (not against a fixed 100%).
    final maxVal = items.fold<double>(0, (m, it) => it.value > m ? it.value : m);
    return Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final color = e.key < colors.length ? colors[e.key] : AppColors.demBlue;
        return Padding(
          padding: EdgeInsets.only(bottom: e.key < items.length - 1 ? 14 : 0),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 10,
                    child: Stack(
                      children: [
                        Container(color: AppColors.pearlGray),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: maxVal == 0
                                ? 0.0
                                : (item.value / maxVal).clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val,
                            child: Container(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Text(
                  '${item.value.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Year-wise trend of the dominant sector's share (Employment by Sector
/// "Trend" tab). One progress bar per year, scaled to the series max so the
/// year-over-year movement is visible. Latest year highlighted.
class _SectorTrendList extends StatelessWidget {
  const _SectorTrendList({required this.series, required this.label});
  final List<DataPoint> series;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) return const SizedBox.shrink();
    final sorted = [...series]
      ..sort((a, b) => a.timePeriod.compareTo(b.timePeriod));
    final maxVal = sorted.fold<double>(
        0, (m, p) => p.value > m ? p.value : m);
    final lastPeriod = sorted.last.timePeriod;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
        ),
        ...sorted.asMap().entries.map((e) {
          final p = e.value;
          final isLast = p.timePeriod == lastPeriod;
          const color = AppColors.demBlue;
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < sorted.length - 1 ? 14 : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    p.timePeriod,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(color: AppColors.pearlGray),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxVal == 0
                                  ? 0.0
                                  : (p.value / maxVal).clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (_, val, __) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: val,
                              child: Container(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${p.value.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isLast ? AppColors.slate900 : AppColors.slate600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// One education level's Male & Female values, for the grouped comparison.
class _GenderComparePair {
  const _GenderComparePair(this.label, this.male, this.female);
  final String label;
  final double male;
  final double female;
  double get total => male + female;
}

// ─── Bar list ─────────────────────────────────────────────────────────────────

class _BarList extends StatelessWidget {
  const _BarList({required this.items, required this.accentColor});
  final List<BreakdownItem> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        return Padding(
          padding: EdgeInsets.only(
              bottom: e.key < items.length - 1 ? 14 : 0),
          child: Row(
            children: [
              // Label — 2 lines + a tooltip so long classes (e.g.
              // "F · Milch (≥4 yrs)") remain fully readable when truncated.
              SizedBox(
                width: 100,
                child: Tooltip(
                  message: item.label,
                  child: Text(
                    item.label,
                    maxLines: 2,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate600,
                      height: 1.15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Track + animated fill
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 10,
                    child: Stack(
                      children: [
                        // Track
                        Container(color: AppColors.pearlGray),
                        // Animated fill — single FractionallySizedBox, left-aligned.
                        // A small minimum width keeps tiny-but-nonzero values
                        // (e.g. Diesel 30 MW vs 22,589 MW) visible as a stub.
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: () {
                              final raw = (item.isPercent
                                      ? item.value
                                      : item.percentage) /
                                  100;
                              if (raw <= 0) return 0.0;
                              return raw.clamp(0.04, 1.0);
                            }(),
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val,
                            child: Container(
                              decoration: accentColor == AppColors.envGreen
                                  // Environment datasets use the green/black
                                  // gradient for visual consistency with the
                                  // dedicated Agriculture/Energy breakdowns.
                                  ? const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF24432B),
                                          Color(0xFF6FBF7F),
                                        ],
                                      ),
                                    )
                                  : BoxDecoration(color: accentColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Value
              SizedBox(
                width: 72,
                child: Text(
                  item.valueText ??
                      (item.isPercent
                          ? '${item.value.toStringAsFixed(1)}%'
                          : NumberFormatter.compact(item.value)),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Grouped Male-vs-Female comparison ────────────────────────────────────────

class _GenderCompareList extends StatelessWidget {
  const _GenderCompareList({required this.pairs, this.isPercent = false});
  final List<_GenderComparePair> pairs;

  /// When true the trailing value renders as "X.X%" (percent-share indicators
  /// such as Employed by Age & Gender) instead of a compact count.
  final bool isPercent;

  static const _maleColor = AppColors.demBlue;
  static const _femaleColor = Color(0xFFC8973A); // gold

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();
    // Scale all bars to the single largest M/F value across every level.
    final maxVal = pairs.fold<double>(0, (m, p) {
      final hi = p.male > p.female ? p.male : p.female;
      return hi > m ? hi : m;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        const Row(
          children: [
            _LegendSwatch(color: _maleColor, label: 'Male'),
            SizedBox(width: 16),
            _LegendSwatch(color: _femaleColor, label: 'Female'),
          ],
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < pairs.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Text(
            pairs[i].label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          _CompareBar(
              label: 'M',
              value: pairs[i].male,
              maxVal: maxVal,
              color: _maleColor,
              isPercent: isPercent),
          const SizedBox(height: 5),
          _CompareBar(
              label: 'F',
              value: pairs[i].female,
              maxVal: maxVal,
              color: _femaleColor,
              isPercent: isPercent),
        ],
      ],
    );
  }
}

/// Flat "Gender Gap" list — every (level × gender) value as its own bar,
/// ranked largest-first across both genders, each labeled with the level and a
/// ♀/♂ symbol. Female bars are gold, male bars blue.
class _GenderGapList extends StatelessWidget {
  const _GenderGapList({required this.pairs});
  final List<_GenderComparePair> pairs;

  static const _maleColor = AppColors.demBlue;
  static const _femaleColor = Color(0xFFC8973A); // gold

  @override
  Widget build(BuildContext context) {
    if (pairs.isEmpty) return const SizedBox.shrink();
    // Flatten M and F into individual ranked entries.
    final entries = <_GapEntry>[];
    for (final p in pairs) {
      if (p.female > 0) {
        entries.add(_GapEntry('${p.label} ♀', p.female, _femaleColor));
      }
      if (p.male > 0) {
        entries.add(_GapEntry('${p.label} ♂', p.male, _maleColor));
      }
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.fold<double>(0, (m, e) => e.value > m ? e.value : m);

    return Column(
      children: [
        const Row(
          children: [
            _LegendSwatch(color: _maleColor, label: 'Male'),
            SizedBox(width: 16),
            _LegendSwatch(color: _femaleColor, label: 'Female'),
          ],
        ),
        const SizedBox(height: 14),
        ...entries.asMap().entries.map((e) {
          final item = e.value;
          return Padding(
            padding:
                EdgeInsets.only(bottom: e.key < entries.length - 1 ? 14 : 0),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        children: [
                          Container(color: AppColors.pearlGray),
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: maxVal == 0
                                  ? 0.0
                                  : (item.value / maxVal).clamp(0.0, 1.0),
                            ),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (_, val, __) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: val,
                              child: Container(color: item.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    '${item.value.toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GapEntry {
  const _GapEntry(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate600)),
      ],
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({
    required this.label,
    required this.value,
    required this.maxVal,
    required this.color,
    this.isPercent = false,
  });
  final String label;
  final double value;
  final double maxVal;
  final Color color;
  final bool isPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate400)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: AppColors.pearlGray),
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: (maxVal == 0 ? 0.0 : value / maxVal)
                            .clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    builder: (_, val, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: val,
                      child: Container(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            isPercent
                ? '${value.toStringAsFixed(1)}%'
                : NumberFormatter.compact(value),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
