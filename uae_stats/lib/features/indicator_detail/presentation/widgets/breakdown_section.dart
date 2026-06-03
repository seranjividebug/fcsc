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
  });
  final String label;
  final double value;
  final double percentage;
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

const _genderNames = {'M': 'Male', 'F': 'Female'};
const _citizenshipNames = {
  'EMIRATI': 'UAE National',
  'NON-EMIRATI': 'Expatriate',
};

// ─── Main widget ──────────────────────────────────────────────────────────────

class BreakdownSection extends ConsumerStatefulWidget {
  const BreakdownSection({super.key, required this.data});
  final IndicatorData data;

  @override
  ConsumerState<BreakdownSection> createState() => _BreakdownSectionState();
}

class _BreakdownSectionState extends ConsumerState<BreakdownSection> {
  int _activeTab = 0;

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
      if (series.isNotEmpty && _genderNames.containsKey(code)) {
        final val = series.last.value;
        result.add(BreakdownItem(
          label: _genderNames[code]!,
          value: val,
          percentage: val / total * 100,
        ));
      }
    });
    return result;
  }

  List<BreakdownItem> _citizenshipBreakdown() {
    final total = widget.data.latestValue;
    if (total == 0) return [];
    final result = <BreakdownItem>[];
    widget.data.byCitizenship.forEach((code, series) {
      if (series.isNotEmpty && _citizenshipNames.containsKey(code)) {
        final val = series.last.value;
        result.add(BreakdownItem(
          label: _citizenshipNames[code]!,
          value: val,
          percentage: val / total * 100,
        ));
      }
    });
    return result;
  }

  List<BreakdownItem> _overallBreakdown() {
    final total = widget.data.latestValue;
    final emirate = _emirateBreakdown();
    final gender = _genderBreakdown();
    final citizenship = _citizenshipBreakdown();

    // Show a mix: total, then gender, then top 2 emirates
    final result = <BreakdownItem>[
      BreakdownItem(label: 'UAE Total (${widget.data.latestPeriod})',
          value: total, percentage: 100),
      ...gender,
    ];

    if (citizenship.isNotEmpty) {
      result.addAll(citizenship);
    } else if (emirate.length >= 2) {
      result.addAll(emirate.take(2));
    }
    return result;
  }

  // ─── Tab configuration ────────────────────────────────────────────────────

  List<_TabDef> _buildTabs(bool isAr) {
    final tabs = <_TabDef>[];
    final hasCitizenship = widget.data.byCitizenship.isNotEmpty;
    tabs.add(_TabDef(isAr ? 'الإجمالي' : 'Overall', _overallBreakdown));
    if (widget.data.byEmirate.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الإمارة' : 'By Emirate', _emirateBreakdown));
    }
    if (widget.data.byGender.isNotEmpty) {
      tabs.add(_TabDef(isAr ? 'حسب الجنس' : 'By Gender', _genderBreakdown));
    }
    if (hasCitizenship) {
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
                              ? AppColors.aeGold
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
                            ? AppColors.aeGold
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isAr ? 'بيانات التصنيف غير متاحة' : 'Breakdown data not available',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.slate400),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _BarList(items: items),
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
  const _BarList({required this.items});
  final List<BreakdownItem> items;

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
                            end: (item.percentage / 100).clamp(0.0, 1.0),
                          ),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (_, val, __) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: val,
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.aeGold,
                                    Color(0xFF1A8C78),
                                  ],
                                ),
                              ),
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
                width: 58,
                child: Text(
                  NumberFormatter.compact(item.value),
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
