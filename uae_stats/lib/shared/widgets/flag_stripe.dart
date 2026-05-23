// lib/shared/widgets/flag_stripe.dart

import 'package:flutter/material.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';

/// The 3px UAE flag accent stripe used below the app bar on main screens.
/// Renders 4 equal segments: Red | White | Black | Green
class FlagStripe extends StatelessWidget {
  const FlagStripe({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppSpacing.flagStripeHeight,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: AppColors.flagRed)),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: AppColors.silver,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: ColoredBox(color: AppColors.flagBlack)),
          Expanded(child: ColoredBox(color: AppColors.flagGreen)),
        ],
      ),
    );
  }
}
