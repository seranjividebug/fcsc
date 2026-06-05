// lib/shared/widgets/bottom_nav_bar.dart
//
// 4-tab bottom navigation: UAE Numbers | Demography | Economy | Environment

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    final int activeTab;
    if (location.startsWith('/demography')) {
      activeTab = 1;
    } else if (location.startsWith('/economy')) {
      activeTab = 2;
    } else if (location.startsWith('/environment')) {
      activeTab = 3;
    } else {
      activeTab = 0;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.silver, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavTab(
                index: 0,
                activeIndex: activeTab,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (activeTab != 0) appRouter.go(AppRoutes.home);
                },
              ),
              _NavTab(
                index: 1,
                activeIndex: activeTab,
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Demography',
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (activeTab != 1) appRouter.go(AppRoutes.demography);
                },
              ),
              _NavTab(
                index: 2,
                activeIndex: activeTab,
                icon: Icons.trending_up_outlined,
                activeIcon: Icons.trending_up_rounded,
                label: 'Economy',
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (activeTab != 2) appRouter.go(AppRoutes.economy);
                },
              ),
              _NavTab(
                index: 3,
                activeIndex: activeTab,
                icon: Icons.eco_outlined,
                activeIcon: Icons.eco_rounded,
                label: 'Environment',
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (activeTab != 3) appRouter.go(AppRoutes.environment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.index,
    required this.activeIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int activeIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  bool get isActive => index == activeIndex;

  @override
  Widget build(BuildContext context) {
    const activeColor   = AppColors.emiratesGreen;
    const inactiveColor = AppColors.slate400;
    final color = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              margin: EdgeInsets.only(bottom: isActive ? 4 : 0),
              decoration: const BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
