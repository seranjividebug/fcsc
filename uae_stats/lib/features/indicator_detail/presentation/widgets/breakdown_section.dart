// lib/features/indicator_detail/presentation/widgets/breakdown_section.dart
//
// Breakdown section with tab bar: Overall | By Emirate | By Gender | By Nationality.
// Each tab shows a list of horizontal progress bars with label + value + %.
// Tabs are only shown if the underlying data is available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
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
  'EMIRATI': 'UAE National',
  'NON-EMIRATI': 'Non-Emirati',
  'NON_EMIRATI': 'Non-Emirati',
  'CIT': 'UAE National',
  'NCIT': 'Non-Emirati',
  'NON_CIT': 'Non-Emirati',
  'NAT': 'UAE National',
  'NON_NAT': 'Non-Emirati',
  'CITIZEN': 'UAE National',
  'NON_CITIZEN': 'Non-Emirati',
  'LOCAL': 'UAE National',
  'EXPAT': 'Non-Emirati',
  'NATIONAL': 'UAE National',
};

// Education level code variants → display label.
const _levelNames = {
  'NURSERY': 'Nursery',
  'NUR': 'Nursery',
  'KG': 'Kindergarten',
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
  'BACH': "Bachelor's",
  'HDIP': 'Higher Diploma',
  'MAST': "Master's",
  'DOCT': 'Doctoral',
  'NO_STA': 'Not Stated',
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
    // Counts, sector shares, and unemployment-by-education: rank biggest-first.
    // Employed-by-education shares: keep natural (curriculum) order.
    final rankBySize = !share ||
        isSector ||
        isOccupation ||
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

  /// Male / Female "profile": each category's share within that gender column,
  /// sorted biggest-first (matches the HTML Male Profile / Female Profile tabs).
  List<BreakdownItem> _genderProfileBreakdown(String genderCode) {
    final map = widget.data.latestCategoryByGender(genderCode);
    final result = <BreakdownItem>[];
    map.forEach((code, val) {
      if (val == 0) return; // skip empty categories (e.g. "Not Stated" = 0)
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

    // Show a mix: total, then gender, then age / level / citizenship / emirates.
    final result = <BreakdownItem>[
      BreakdownItem(label: 'UAE Total (${widget.data.latestPeriod})',
          value: total, percentage: 100),
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
    // Annual Rainfall — By Station only (national average is the headline).
    if (_isRainfall) {
      final tabs = <_TabDef>[];
      if (widget.data.rainfallByStation.isNotEmpty) {
        tabs.add(_TabDef(isAr ? 'حسب المحطة' : 'By Station', _rainfallByStation));
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

    final tabs = <_TabDef>[
      _TabDef(isAr ? 'الإجمالي' : 'Overall', _overallBreakdown),
    ];
    // Labour (age) indicators: By Age / Age × Gender.
    if (widget.data.byAge.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب العمر' : 'By Age', _ageBreakdown));
    }
    // Education indicators: By Level / Gender × Level.
    if (widget.data.byLevel.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب المستوى' : 'By Level', _levelBreakdown));
    }
    if (widget.data.byEmirate.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown));
    }
    // Top-category share indicators (Economic Activity, Employment by Sector,
    // Unemployment by Education): Male Profile / Female Profile tabs — each
    // category's share within that gender column, sorted biggest-first.
    final hasGenderProfile = (widget.data.isTopCategoryShare ||
            widget.data.isEmploymentSector) &&
        widget.data.latestCategoryByGender('M').isNotEmpty;
    if (hasGenderProfile) {
      tabs.add(_TabDef(isAr ? 'الذكور' : 'Male Profile',
          () => _genderProfileBreakdown('M')));
      tabs.add(_TabDef(isAr ? 'الإناث' : 'Female Profile',
          () => _genderProfileBreakdown('F')));
    }
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
    final items = tabs[_activeTab].buildFn();

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

        // Bar list
        if (items.isEmpty)
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
  const _TabDef(this.label, this.buildFn);
  final String label;
  final List<BreakdownItem> Function() buildFn;
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
              // Label
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
                        // Animated fill — single FractionallySizedBox, left-aligned
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: ((item.isPercent
                                        ? item.value
                                        : item.percentage) /
                                    100)
                                .clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val,
                            child: Container(color: accentColor),
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
