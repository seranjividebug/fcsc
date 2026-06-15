// lib/shared/widgets/hero_action_buttons.dart
//
// Circular bookmark + overflow (three-dots) buttons shown on the bottom-right
// of indicator hero cards. Translucent white circles with white icons, sized
// to sit over the dark hero gradient — matches the approved HTML design.
//
// Actions:
//   • Bookmark — toggles filled/outline state (local).
//   • Share    — shares the current insight/card summary.
//   • Download — exports the full data table as an .xlsx workbook.
//   • View UAE Stats — opens the official SDMX source URL in a new tab.

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/utils/number_formatter.dart';
import 'package:uae_stats/data/models/indicator_data.dart';
import 'package:uae_stats/shared/providers/bookmark_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bookmark + overflow buttons. Bookmark state is persisted via
/// [bookmarkProvider] (Hive-backed), keyed by the indicator id.
class HeroActionButtons extends ConsumerStatefulWidget {
  const HeroActionButtons({
    super.key,
    required this.indicatorName,
    this.data,
  });

  /// Localized indicator name (used for share text / file naming).
  final String indicatorName;

  /// Full indicator dataset — required for Share, Download and View actions.
  /// When null, those actions show a friendly "not available" message.
  final IndicatorData? data;

  @override
  ConsumerState<HeroActionButtons> createState() => _HeroActionButtonsState();
}

class _HeroActionButtonsState extends ConsumerState<HeroActionButtons> {

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.slate900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Share ────────────────────────────────────────────────────────────────

  Future<void> _share() async {
    final d = widget.data;
    if (d == null) {
      _toast('Sharing not available');
      return;
    }
    final series = d.uaeTotalSeries;
    final latest = series.isNotEmpty
        ? NumberFormatter.full(series.last.value)
        : '—';
    final unit = d.meta.unit.en;
    final period = d.latestPeriod;
    final text = StringBuffer()
      ..writeln('${widget.indicatorName} — UAE')
      ..writeln('$latest $unit ($period)')
      ..writeln('Source: UAE Stats (FCSC)')
      ..writeln(d.sourceUrl);
    try {
      await Share.share(text.toString(), subject: widget.indicatorName);
    } catch (_) {
      _toast('Unable to share');
    }
  }

  // ─── Download (.xlsx) ───────────────────────────────────────────────────────

  Future<void> _download() async {
    final d = widget.data;
    if (d == null) {
      _toast('Download not available');
      return;
    }
    try {
      final book = xls.Excel.createExcel();
      // Rename the auto-created default sheet to "Data".
      final defaultSheet = book.getDefaultSheet() ?? book.sheets.keys.first;
      if (defaultSheet != 'Data') {
        book.rename(defaultSheet, 'Data');
      }
      final sheet = book['Data'];

      // Header row
      sheet.appendRow([
        xls.TextCellValue('Year'),
        xls.TextCellValue('Value'),
        xls.TextCellValue('Unit'),
      ]);

      final unit = d.meta.unit.en;
      for (final p in d.uaeTotalSeries) {
        sheet.appendRow([
          xls.TextCellValue(p.timePeriod),
          xls.DoubleCellValue(p.value),
          xls.TextCellValue(unit),
        ]);
      }

      final encoded = book.encode();
      if (encoded == null) {
        _toast('Could not generate file');
        return;
      }
      final bytes = Uint8List.fromList(encoded);

      final safeName = widget.indicatorName
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final fileName = '${safeName.isEmpty ? 'indicator' : safeName}_data.xlsx';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: [fileName],
        subject: widget.indicatorName,
      );
    } catch (_) {
      _toast('Download failed');
    }
  }

  // ─── View UAE Stats ─────────────────────────────────────────────────────────

  Future<void> _viewSource() async {
    // Open the public UAE Stats portal — not the raw SDMX REST file.
    const url = 'https://uaestat.fcsc.gov.ae/en';
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _toast('Source link unavailable');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _toast('Could not open source');
    } catch (_) {
      _toast('Could not open source');
    }
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'Share':
        _share();
      case 'Download':
        _download();
      case 'View UAE Stats':
        _viewSource();
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.data?.meta.id;
    final bookmarked = id != null && ref.watch(isBookmarkedProvider(id));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeroCircleButton(
          icon: bookmarked
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          onTap: () async {
            if (id == null) {
              _toast('Bookmark not available');
              return;
            }
            HapticFeedback.lightImpact();
            final nowSaved =
                await ref.read(bookmarkProvider.notifier).toggle(id);
            _toast(nowSaved
                ? '${widget.indicatorName} bookmarked'
                : 'Bookmark removed');
          },
        ),
        const SizedBox(width: 8),
        _HeroOverflowButton(onSelected: _onMenuSelected),
      ],
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.white),
      ),
    );
  }
}

class _HeroOverflowButton extends StatelessWidget {
  const _HeroOverflowButton({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        _item('Share', Icons.share_outlined),
        _item('Download', Icons.download_outlined),
        _item('View UAE Stats', Icons.open_in_new_rounded),
      ],
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.more_horiz_rounded,
            size: 18, color: AppColors.white),
      ),
    );
  }

  PopupMenuItem<String> _item(String label, IconData icon) {
    return PopupMenuItem<String>(
      value: label,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate600),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.slate900)),
        ],
      ),
    );
  }
}
