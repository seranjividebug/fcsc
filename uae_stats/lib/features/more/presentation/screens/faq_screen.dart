// lib/features/more/presentation/screens/faq_screen.dart
//
// FAQ screen — searchable, category-filterable accordion of frequently asked
// questions (EN/AR), with a "still need help?" card linking to Feedback.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/features/more/presentation/widgets/more_app_bar.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';

enum _FaqCat { data, app, fcsc, tech }

class _Faq {
  const _Faq(this.cat, this.qEn, this.aEn, this.qAr, this.aAr);
  final _FaqCat cat;
  final String qEn, aEn, qAr, aAr;
}

const _faqs = <_Faq>[
  _Faq(_FaqCat.data, 'Is this data official and accurate?',
      'Yes. All data in UAE Stats comes directly from the Federal Competitiveness and Statistics Centre (FCSC) — the official national statistical authority of the UAE. Data is sourced from ministries, civil registration systems, and approved surveys, and follows international SDMX standards used by the World Bank and IMF.',
      'هل هذه البيانات رسمية ودقيقة؟',
      'نعم. جميع البيانات تأتي مباشرة من المركز الاتحادي للتنافسية والإحصاء — الجهة الإحصائية الرسمية في الدولة. البيانات مستقاة من الوزارات وأنظمة التسجيل المدني والمسوح المعتمدة وتتبع معايير SDMX الدولية.'),
  _Faq(_FaqCat.data, 'How current is the data?',
      'Data is updated based on the publication cycle of each indicator. For example, CPI (inflation) is updated monthly, while population estimates are updated annually. The date shown on each indicator tells you when it was last released.',
      'ما مدى حداثة البيانات؟',
      'يتم تحديث البيانات وفقاً لدورة نشر كل مؤشر. على سبيل المثال، يُحدّث مؤشر أسعار المستهلك شهرياً بينما تُحدّث تقديرات السكان سنوياً.'),
  _Faq(_FaqCat.data, 'What does the YoY percentage mean?',
      'YoY stands for Year-on-Year. It compares this year\'s value to the same period last year, expressed as a percentage change. A positive number means growth; a negative number means a decrease.',
      'ماذا تعني النسبة المئوية للتغير السنوي؟',
      'التغير السنوي (YoY) يقارن قيمة هذا العام بنفس الفترة من العام الماضي كنسبة مئوية. الرقم الموجب يعني نمواً والسالب يعني انخفاضاً.'),
  _Faq(_FaqCat.app, 'How do I switch between English and Arabic?',
      'Tap the language toggle (EN | AR) in the top-right of the app bar. The app switches immediately, including text direction.',
      'كيف أبدّل بين العربية والإنجليزية؟',
      'اضغط على زر تبديل اللغة (EN | AR) أعلى يمين شريط التطبيق. سيتحول التطبيق فوراً بما في ذلك اتجاه النص.'),
  _Faq(_FaqCat.app, 'Can I use the app without internet?',
      'The app works without an internet connection by showing the most recently saved data. Connect to the internet to see the most current figures.',
      'هل يمكن استخدام التطبيق بدون إنترنت؟',
      'يعمل التطبيق بدون اتصال بالإنترنت من خلال عرض آخر بيانات محفوظة. اتصل بالإنترنت لرؤية أحدث الأرقام.'),
  _Faq(_FaqCat.app, 'How do I save an indicator to view later?',
      'Tap the Bookmark icon on any indicator detail screen. Saved indicators appear in the Bookmarks section, accessible from the side menu.',
      'كيف أحفظ مؤشراً لأطّلع عليه لاحقاً؟',
      'اضغط على أيقونة الإشارة المرجعية في أي شاشة تفاصيل مؤشر. تظهر المؤشرات المحفوظة في قسم الإشارات المرجعية من القائمة الجانبية.'),
  _Faq(_FaqCat.fcsc, 'What is FCSC?',
      'The Federal Competitiveness and Statistics Centre (FCSC) is the official national statistical authority of the United Arab Emirates, responsible for producing, disseminating, and safeguarding official UAE statistics across all government sectors.',
      'ما هو المركز الاتحادي للتنافسية والإحصاء؟',
      'المركز الاتحادي للتنافسية والإحصاء هو الجهة الإحصائية الرسمية لدولة الإمارات، وهو مسؤول عن إنتاج ونشر وحماية الإحصاءات الرسمية عبر جميع القطاعات الحكومية.'),
  _Faq(_FaqCat.fcsc, 'How can I contact FCSC?',
      'You can reach FCSC via email at info@fcsc.gov.ae or visit uaestat.fcsc.gov.ae for the full data portal and contact information.',
      'كيف يمكنني التواصل مع المركز؟',
      'يمكنك التواصل مع المركز عبر البريد الإلكتروني info@fcsc.gov.ae أو زيارة الموقع uaestat.fcsc.gov.ae.'),
  _Faq(_FaqCat.tech, 'Where does the app get its data from?',
      'UAE Stats retrieves data directly from the FCSC public SDMX API — the same data source used by international organisations like the World Bank and IMF.',
      'من أين يحصل التطبيق على بياناته؟',
      'يسترجع التطبيق البيانات مباشرة من واجهة برمجة تطبيقات SDMX العامة للمركز — نفس مصدر البيانات الذي تستخدمه المنظمات الدولية.'),
  _Faq(_FaqCat.tech, 'Is my data private? Does the app track me?',
      'UAE Stats does not require login or registration and does not collect personally identifiable information. Anonymous usage data may be collected to improve the app, consistent with UAE Government data protection policies.',
      'هل بياناتي خاصة؟ هل يتتبعني التطبيق؟',
      'لا يتطلب التطبيق تسجيل دخول ولا يجمع معلومات تعريف شخصية. قد تُجمع بيانات استخدام مجهولة لتحسين التطبيق وفقاً لسياسات حماية البيانات الحكومية.'),
];

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});
  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  String _query = '';
  _FaqCat? _cat; // null = All
  int? _openIdx;

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    String catLabel(_FaqCat? c) => switch (c) {
          null => isAr ? 'الكل' : 'All',
          _FaqCat.data => isAr ? 'البيانات' : 'Data & Statistics',
          _FaqCat.app => isAr ? 'استخدام التطبيق' : 'Using the App',
          _FaqCat.fcsc => isAr ? 'عن المركز' : 'About FCSC',
          _FaqCat.tech => isAr ? 'التقنية' : 'Technical',
        };

    final q = _query.trim().toLowerCase();
    final items = _faqs.where((f) {
      if (_cat != null && f.cat != _cat) return false;
      if (q.isEmpty) return true;
      final hay = isAr ? '${f.qAr} ${f.aAr}' : '${f.qEn} ${f.aEn}';
      return hay.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          MoreAppBar(title: isAr ? 'الأسئلة الشائعة' : 'FAQs'),
          // Search
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 12, AppSpacing.lg, 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.pearlGraySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.silver),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.slate400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: isAr
                            ? 'ابحث في الأسئلة الشائعة...'
                            : 'Search frequently asked questions...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.slate400),
                      ),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.slate900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Category tabs
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  for (final c in [null, ..._FaqCat.values])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CatPill(
                        label: catLabel(c),
                        active: _cat == c,
                        onTap: () => setState(() {
                          _cat = c;
                          _openIdx = null;
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.silver),
          Expanded(
            child: items.isEmpty
                ? _noResults(isAr)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 12, AppSpacing.lg, 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 2),
                        child: Text(
                          '${items.length} ${isAr ? 'سؤال' : 'questions'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.slate400),
                        ),
                      ),
                      for (var i = 0; i < items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FaqTile(
                            faq: items[i],
                            isAr: isAr,
                            open: _openIdx == i,
                            onTap: () => setState(
                                () => _openIdx = _openIdx == i ? null : i),
                          ),
                        ),
                      const SizedBox(height: 8),
                      _HelpCard(isAr: isAr),
                    ],
                  ),
          ),
          const AppBottomNavBar(),
        ],
      ),
    );
  }

  Widget _noResults(bool isAr) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                    color: AppColors.pearlGray, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded,
                    color: AppColors.slate400),
              ),
              const SizedBox(height: 14),
              Text(isAr ? 'لا توجد نتائج مطابقة' : 'No matching questions',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900)),
              const SizedBox(height: 4),
              Text(
                isAr
                    ? 'جرّب مصطلح بحث مختلف أو تصفّح حسب الفئة.'
                    : 'Try a different search term or browse by category.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.slate600),
              ),
            ],
          ),
        ),
      );
}

({Color color, Color tint, IconData icon}) _catStyle(_FaqCat c) => switch (c) {
      _FaqCat.data => (
          color: AppColors.demBlue,
          tint: AppColors.demBlueTint,
          icon: Icons.bar_chart_rounded
        ),
      _FaqCat.app => (
          color: AppColors.envGreen,
          tint: AppColors.envGreenTint,
          icon: Icons.smartphone_rounded
        ),
      _FaqCat.fcsc => (
          color: AppColors.aeGold,
          tint: AppColors.aeGoldBg,
          icon: Icons.account_balance_rounded
        ),
      _FaqCat.tech => (
          color: const Color(0xFF8B5CF6),
          tint: const Color(0xFFF3E8FF),
          icon: Icons.code_rounded
        ),
    };

class _CatPill extends StatelessWidget {
  const _CatPill(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.aeGold : AppColors.pearlGray,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : AppColors.slate600,
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile(
      {required this.faq,
      required this.isAr,
      required this.open,
      required this.onTap});
  final _Faq faq;
  final bool isAr;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = _catStyle(faq.cat);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppColors.shadowCard,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: st.tint,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(st.icon, size: 16, color: st.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isAr ? faq.qAr : faq.qEn,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: open ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.slate900,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: open ? AppColors.aeGold : AppColors.slate400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.pearlGraySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border(
                    left: isAr
                        ? BorderSide.none
                        : const BorderSide(color: AppColors.aeGold, width: 3),
                    right: isAr
                        ? const BorderSide(color: AppColors.aeGold, width: 3)
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  isAr ? faq.aAr : faq.aEn,
                  textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.65,
                    color: AppColors.slate600,
                  ),
                ),
              ),
            ),
            crossFadeState:
                open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.aeGoldBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.aeGold.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.aeGold,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'لم تجد إجابتك؟' : "Didn't find your answer?",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900),
                ),
                const SizedBox(height: 2),
                Text(
                  isAr
                      ? 'أرسل لنا رسالة وسنعاود الاتصال بك.'
                      : "Send us a message and we'll get back to you.",
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.4, color: AppColors.slate600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.aeGold,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            ),
            onPressed: () => context.push(AppRoutes.feedback),
            child: Text(isAr ? 'تواصل' : 'Contact',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
