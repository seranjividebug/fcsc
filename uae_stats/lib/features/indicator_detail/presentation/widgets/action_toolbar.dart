// lib/features/indicator_detail/presentation/widgets/action_toolbar.dart
//
// Four outlined pill action chips below the breadcrumb.
// Design: white bg, 12px 20px padding, gap 8px, pearl border-bottom.
// Chips: 40px height, 1.5px green border, radius 999, 12px weight 600.
// Bookmark chip toggles to filled (active) state on tap.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uae_stats/core/theme/app_colors.dart';

class ActionToolbar extends StatefulWidget {
  const ActionToolbar({super.key, required this.indicatorName});
  final String indicatorName;

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
          // Bookmark — toggleable
          _ActionChip(
            icon: _bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
            label: _bookmarked ? 'Bookmarked' : 'Bookmark',
            isActive: _bookmarked,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _bookmarked = !_bookmarked);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_bookmarked
                      ? '${widget.indicatorName} bookmarked'
                      : 'Bookmark removed'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.slate900,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          _ActionChip(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () => _toast(context, 'Share coming soon'),
          ),

          const SizedBox(width: 8),

          _ActionChip(
            icon: Icons.download_outlined,
            label: 'Download',
            onTap: () => _toast(context, 'Download coming soon'),
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

class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
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
            color: active
                ? AppColors.emiratesGreen
                : Colors.transparent,
            border: Border.all(
              color: AppColors.emiratesGreen,
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
                color: active ? AppColors.white : AppColors.emiratesGreen,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.white : AppColors.emiratesGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
