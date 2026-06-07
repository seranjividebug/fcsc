// lib/features/more/presentation/widgets/more_app_bar.dart
//
// Shared top bar for the "more" section screens (Bookmarks, FAQ, Feedback,
// About). White app bar with a back button, centred title, and the language
// toggle, followed by the UAE flag accent stripe — matching the main screens.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/shared/widgets/flag_stripe.dart';
import 'package:uae_stats/shared/widgets/language_toggle_button.dart';

class MoreAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MoreAppBar({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppSpacing.appBarHeight + AppSpacing.flagStripeHeight);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            height: AppSpacing.appBarHeight,
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      size: 24, color: AppColors.slate900),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing ??
                        const LanguageToggleButton(
                            foregroundColor: AppColors.slate600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const FlagStripe(),
      ],
    );
  }
}
