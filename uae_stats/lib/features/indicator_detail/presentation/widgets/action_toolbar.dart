// lib/features/indicator_detail/presentation/widgets/action_toolbar.dart
//
// Action options row below the breadcrumb on the Indicator Detail screen.
// Design: white bg, 12px/20px padding, gap 8px, pearl border-bottom.
// Chips: 40px height, 1.5px accent border, radius 999, 12px weight 600.
// Includes: Bookmark/favorite (toggles to filled), Share, Download, and an
// overflow (three-dots) menu. The accent color follows the indicator category
// (Demography blue, Economy gold, Environment green).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uae_stats/core/theme/app_colors.dart';

class ActionToolbar extends StatefulWidget {
  const ActionToolbar({
    super.key,
    required this.indicatorName,
    this.accentColor = AppColors.demBlue,
  });

  final String indicatorName;
  final Color accentColor;

  @override
  State<ActionToolbar> createState() => _ActionToolbarState();
}

class _ActionToolbarState extends State<ActionToolbar> {
  bool _bookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.pearlGray, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Bookmark / favorite — toggleable
          _ActionChip(
            icon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            label: _bookmarked ? 'Bookmarked' : 'Bookmark',
            accentColor: widget.accentColor,
            isActive: _bookmarked,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _bookmarked = !_bookmarked);
              _toast(
                context,
                _bookmarked
                    ? '${widget.indicatorName} bookmarked'
                    : 'Bookmark removed',
              );
            },
          ),

          const SizedBox(width: 8),

          _ActionChip(
            icon: Icons.share_outlined,
            label: 'Share',
            accentColor: widget.accentColor,
            onTap: () => _toast(context, 'Share coming soon'),
          ),

          const SizedBox(width: 8),

          _ActionChip(
            icon: Icons.download_outlined,
            label: 'Download',
            accentColor: widget.accentColor,
            onTap: () => _toast(context, 'Download coming soon'),
          ),

          const SizedBox(width: 8),

          // Overflow (three-dots) menu
          _OverflowMenu(
            accentColor: widget.accentColor,
            onSelected: (value) => _toast(context, '$value coming soon'),
          ),
        ],
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      backgroundColor: AppColors.slate900,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─── Overflow (three-dots) menu ───────────────────────────────────────────────

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({
    required this.accentColor,
    required this.onSelected,
  });

  final Color accentColor;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: PopupMenuButton<String>(
        tooltip: 'More options',
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: AppColors.white,
        onSelected: onSelected,
        itemBuilder: (context) => [
          _menuItem('Add to compare', Icons.compare_arrows_rounded),
          _menuItem('Copy citation', Icons.format_quote_rounded),
          _menuItem('View source', Icons.open_in_new_rounded),
          _menuItem('Report an issue', Icons.flag_outlined),
        ],
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: accentColor, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: accentColor,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String label, IconData icon) {
    return PopupMenuItem<String>(
      value: label,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate600),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action chip ──────────────────────────────────────────────────────────────

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accentColor,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accentColor;
  final bool isActive;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive || _pressed;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          decoration: BoxDecoration(
            color: active ? widget.accentColor : Colors.transparent,
            border: Border.all(
              color: widget.accentColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: active ? AppColors.white : widget.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
