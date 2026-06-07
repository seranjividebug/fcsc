// lib/features/more/presentation/screens/about_screen.dart
//
// About FCSC — brand hero, key stats, mandate cards, contact rows, social
// links and a "visit website" CTA. Styled with the AEGold brand to match the
// rest of the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/features/more/presentation/widgets/more_app_bar.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          MoreAppBar(title: isAr ? 'عن المركز' : 'About FCSC'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Hero ────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepForest,
                        AppColors.aeGoldDeep,
                        AppColors.aeGoldAccent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isAr
                            ? 'المركز الاتحادي للتنافسية والإحصاء'
                            : 'Federal Competitiveness\nand Statistics Centre',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'Federal Competitiveness and Statistics Centre'
                            : 'المركز الاتحادي للتنافسية والإحصاء',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Key stats ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              num: '2015',
                              label: isAr ? 'سنة التأسيس' : 'Year Established')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                              num: '350+',
                              label: isAr
                                  ? 'مؤشر إحصائي'
                                  : 'Statistical Indicators')),
                    ],
                  ),
                ),

                // ── Who we are ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _SectionCard(
                    icon: Icons.info_outline_rounded,
                    title: isAr ? 'من نحن' : 'Who We Are',
                    body: isAr
                        ? 'المركز الاتحادي للتنافسية والإحصاء هو الجهة الإحصائية الرسمية لدولة الإمارات، المكلّف بإنتاج ونشر وحوكمة الإحصاءات الوطنية التي تدعم صنع القرار القائم على الأدلة وأهداف التنمية الاستراتيجية للدولة.'
                        : "The Federal Competitiveness and Statistics Centre (FCSC) is the official statistical authority of the UAE, mandated to produce, disseminate, and govern national statistics that inform evidence-based policymaking and support the UAE's strategic development goals.",
                  ),
                ),

                // ── Mandate ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 16, 12),
                  child: Text(
                    isAr ? 'مهمتنا' : 'Our Mandate',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900),
                  ),
                ),
                SizedBox(
                  height: 150,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _MandateCard(
                        color: AppColors.aeGold,
                        tint: AppColors.aeGoldBg,
                        icon: Icons.bar_chart_rounded,
                        title: isAr ? 'بيانات رسمية' : 'Official Data',
                        body: isAr
                            ? 'إنتاج إحصاءات وطنية موثوقة'
                            : 'Producing authoritative national statistics',
                      ),
                      _MandateCard(
                        color: AppColors.demBlue,
                        tint: AppColors.demBlueTint,
                        icon: Icons.account_balance_rounded,
                        title: isAr ? 'سياسات حكومية' : 'Government Policy',
                        body: isAr
                            ? 'دعم رؤية الإمارات برؤى قائمة على الأدلة'
                            : 'Supporting UAE Vision with evidence-based insights',
                      ),
                      _MandateCard(
                        color: AppColors.envGreen,
                        tint: AppColors.envGreenTint,
                        icon: Icons.public_rounded,
                        title:
                            isAr ? 'معايير دولية' : 'International Standards',
                        body: isAr
                            ? 'متوافقة مع أطر الأمم المتحدة الإحصائية'
                            : 'Aligned with UN statistical frameworks',
                      ),
                    ],
                  ),
                ),

                // ── Contact ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppColors.shadowCard,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 20, color: AppColors.aeGoldDeep),
                            const SizedBox(width: 8),
                            Text(isAr ? 'تواصل معنا' : 'Contact Us',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _ContactRow(
                          icon: Icons.mail_outline_rounded,
                          label: isAr ? 'البريد الإلكتروني' : 'Email',
                          value: 'info@fcsc.gov.ae',
                          onTap: () => _open('mailto:info@fcsc.gov.ae'),
                        ),
                        _ContactRow(
                          icon: Icons.phone_outlined,
                          label: isAr ? 'الهاتف' : 'Phone',
                          value: '+971-2-617-5000',
                          onTap: () => _open('tel:+97126175000'),
                        ),
                        _ContactRow(
                          icon: Icons.location_on_outlined,
                          label: isAr ? 'الموقع' : 'Location',
                          value: isAr ? 'أبوظبي، الإمارات' : 'Abu Dhabi, UAE',
                        ),
                        _ContactRow(
                          icon: Icons.public_rounded,
                          label: isAr ? 'الموقع الإلكتروني' : 'Website',
                          value: 'uaestat.fcsc.gov.ae',
                          last: true,
                          onTap: () => _open('https://uaestat.fcsc.gov.ae/en'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Vision ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.aeGoldBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                          color: AppColors.aeGold.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.aeGold,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.layers_rounded,
                              size: 28, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'مساهمةً في رؤية الإمارات'
                                    : 'Contributing to UAE Vision',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAr
                                    ? 'تمكين الاستراتيجية الوطنية ببيانات موثوقة وبنية إحصائية عالمية المستوى.'
                                    : 'Empowering national strategy with trusted data and world-class statistical infrastructure.',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: AppColors.slate600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTA ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.aeGold,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                    onPressed: () => _open('https://uaestat.fcsc.gov.ae/en'),
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: Colors.white),
                    label: Text(
                        isAr ? 'زيارة الموقع الرسمي' : 'Visit Official Website',
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),

                // ── Footer ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Text(
                    isAr
                        ? '© 2026 المركز الاتحادي للتنافسية والإحصاء · دولة الإمارات العربية المتحدة'
                        : '© 2026 Federal Competitiveness and Statistics Centre · United Arab Emirates',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, height: 1.5, color: AppColors.slate400),
                  ),
                ),
              ],
            ),
          ),
          const AppBottomNavBar(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.num, required this.label});
  final String num, label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        children: [
          Text(num,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.aeGoldDeep,
                  height: 1)),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, height: 1.3, color: AppColors.slate600)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.aeGoldDeep),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900)),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.65, color: AppColors.slate600)),
        ],
      ),
    );
  }
}

class _MandateCard extends StatelessWidget {
  const _MandateCard(
      {required this.color,
      required this.tint,
      required this.icon,
      required this.title,
      required this.body});
  final Color color, tint;
  final IconData icon;
  final String title, body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                  height: 1.3)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, height: 1.5, color: AppColors.slate600)),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap,
      this.last = false});
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.pearlGray)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.aeGoldBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: AppColors.aeGoldDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.slate400)),
                  const SizedBox(height: 1),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate900)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}
