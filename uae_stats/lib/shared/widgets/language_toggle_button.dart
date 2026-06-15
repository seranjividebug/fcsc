import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

/// The single, shared language toggle pill used across ALL screens (home,
/// category pages, detail pages) — guaranteeing pixel-consistent styling:
/// a light-grey pill (#F0F0F0) with a dark globe icon + "عربي/EN" label
/// (#1A1A2E) and a subtle border so it reads on any background.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({
    super.key,
    // Kept for source compatibility with existing call-sites; the toggle now
    // renders with a fixed, consistent style regardless of these values.
    this.foregroundColor = _kFg,
    this.backgroundColor = _kBg,
  });

  static const Color _kFg = Color(0xFF1A1A2E); // dark slate (globe + text)
  static const Color _kBg = Color(0xFFF0F0F0); // light grey pill

  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';

    return Semantics(
      button: true,
      label: isArabic ? 'Switch to English' : 'Switch to Arabic',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => ref.read(localeProvider.notifier).toggle(),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.silver),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 16, color: _kFg),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'EN' : 'عربي',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
