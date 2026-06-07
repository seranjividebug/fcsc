// lib/shared/widgets/app_drawer.dart
//
// Side navigation drawer opened from the home hamburger icon. Lists the four
// "more" sections — Bookmarks, FAQ, Feedback, About FCSC — styled with the
// AEGold brand to match the rest of the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/shared/providers/bookmark_provider.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/app_logo.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final bookmarkCount = ref.watch(bookmarkProvider).length;

    return Drawer(
      backgroundColor: AppColors.offWhite,
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand header ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                AppSpacing.lg, MediaQuery.of(context).padding.top + 24,
                AppSpacing.lg, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.deepForest,
                  AppColors.aeGoldDeep,
                  AppColors.aeGold,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(),
                    const SizedBox(width: 10),
                    Text(
                      isAr ? 'إحصاءات الإمارات' : 'UAE Stats',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'بيانات رسمية من المركز الاتحادي للتنافسية والإحصاء'
                      : 'Official statistics from the FCSC',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── Menu items ──────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.bookmark_outline_rounded,
            label: isAr ? 'الإشارات المرجعية' : 'Bookmarks',
            trailing: bookmarkCount > 0 ? '$bookmarkCount' : null,
            onTap: () => _go(context, AppRoutes.bookmarks),
          ),
          _DrawerItem(
            icon: Icons.help_outline_rounded,
            label: isAr ? 'الأسئلة الشائعة' : 'FAQ',
            onTap: () => _go(context, AppRoutes.faq),
          ),
          _DrawerItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: isAr ? 'الملاحظات' : 'Feedback',
            onTap: () => _go(context, AppRoutes.feedback),
          ),
          _DrawerItem(
            icon: Icons.info_outline_rounded,
            label: isAr ? 'عن المركز' : 'About FCSC',
            onTap: () => _go(context, AppRoutes.about),
          ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.silver),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              isAr
                  ? '© 2026 المركز الاتحادي للتنافسية والإحصاء'
                  : '© 2026 Federal Competitiveness\nand Statistics Centre',
              style: const TextStyle(
                color: AppColors.slate400,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop(); // close drawer
    context.push(route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: 14),
        child: Row(
          children: [
            Container(
              width: AppSpacing.iconContainerMd,
              height: AppSpacing.iconContainerMd,
              decoration: BoxDecoration(
                color: AppColors.aeGoldBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.aeGoldDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
            ),
            if (trailing != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.aeGold,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
