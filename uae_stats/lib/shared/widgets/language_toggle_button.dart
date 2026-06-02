import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({
    super.key,
    this.foregroundColor = AppColors.slate900,
    this.backgroundColor = AppColors.pearlGray,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 16, color: foregroundColor),
              const SizedBox(width: 5),
              Text(
                isArabic ? 'EN' : 'عربي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
