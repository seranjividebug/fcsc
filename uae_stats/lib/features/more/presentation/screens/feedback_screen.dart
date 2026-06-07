// lib/features/more/presentation/screens/feedback_screen.dart
//
// Feedback form — emoji rating, optional comment, topic chips, and a "what
// brought you here" radio group. Submissions are stored locally (anonymous;
// no backend) and a success state is shown. Matches the AEGold app style.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uae_stats/core/routing/app_router.dart';
import 'package:uae_stats/core/theme/app_colors.dart';
import 'package:uae_stats/core/theme/app_spacing.dart';
import 'package:uae_stats/features/more/presentation/widgets/more_app_bar.dart';
import 'package:uae_stats/shared/providers/locale_provider.dart';
import 'package:uae_stats/shared/widgets/bottom_nav_bar.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});
  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int? _rating; // 0..4
  final _controller = TextEditingController();
  final Set<int> _topics = {};
  int? _visit;
  bool _submitted = false;

  static const _emojis = ['😞', '🙁', '😐', '🙂', '😄'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      final box = Hive.box<String>('bookmarks'); // reuse open box namespace
      // Store under a feedback_ prefix so it never clashes with indicator ids.
      await box.put(
        'feedback_${DateTime.now().millisecondsSinceEpoch}',
        '${_rating ?? -1}|${_topics.join(',')}|${_visit ?? -1}',
      );
    } catch (_) {
      // Local persistence is best-effort; never block the success state.
    }
    if (mounted) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          MoreAppBar(title: isAr ? 'الملاحظات' : 'Feedback'),
          Expanded(
            child: _submitted
                ? _Success(isAr: isAr)
                : _form(isAr),
          ),
          const AppBottomNavBar(),
        ],
      ),
    );
  }

  Widget _form(bool isAr) {
    final ratingLabels = isAr
        ? ['ضعيف', 'مقبول', 'جيد', 'رائع', 'ممتاز']
        : ['Poor', 'Fair', 'Good', 'Great', 'Excellent'];
    final topics = isAr
        ? ['دقة البيانات', 'الرسوم البيانية', 'أداء التطبيق', 'التصفح', 'التجربة العربية', 'أخرى']
        : ['Data Accuracy', 'Charts & Visuals', 'App Performance', 'Navigation', 'Arabic Experience', 'Other'];
    final visits = isAr
        ? [('تصفّح عام', 'استكشاف البيانات بدافع الفضول'),
           ('بحث أو عمل', 'استخدام البيانات لغرض مهني'),
           ('أكاديمي أو تعليمي', 'بحث طلابي أو أكاديمي'),
           ('حكومي أو سياسات', 'اتخاذ قرارات أو إعداد تقارير'),
           ('إعلام أو صحافة', 'كتابة أو تقارير عن الإحصاءات')]
        : [('Just browsing', 'Exploring data out of general interest'),
           ('Research or work', 'Using data for a professional purpose'),
           ('Academic or education', 'Student or academic research'),
           ('Government or policy', 'Informing decisions or reports'),
           ('Media or journalism', 'Writing or reporting on UAE statistics')];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 24),
      children: [
        Text(
          isAr ? 'يسعدنا سماع رأيك' : "We'd love to hear from you",
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              height: 1.25),
        ),
        const SizedBox(height: 8),
        Text(
          isAr
              ? 'ملاحظاتك تساعدنا على تحسين تطبيق إحصاءات الإمارات وجعل البيانات الرسمية أكثر سهولة للجميع.'
              : 'Your feedback helps us improve UAE Stats and make official data more accessible to everyone.',
          style: const TextStyle(
              fontSize: 15, height: 1.5, color: AppColors.slate600),
        ),
        const SizedBox(height: 20),

        // Rating
        _Card(
          label: isAr
              ? 'كيف تقيّم تجربتك مع التطبيق؟'
              : 'How would you rate your experience?',
          child: Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    child: _EmojiOption(
                      emoji: _emojis[i],
                      label: ratingLabels[i],
                      selected: _rating == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _rating = i);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comment
        _Card(
          label: isAr ? 'أخبرنا المزيد (اختياري)' : 'Tell us more (optional)',
          child: TextField(
            controller: _controller,
            maxLength: 500,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            decoration: InputDecoration(
              hintText: isAr
                  ? 'ما الذي أعجبك؟ وما الذي يمكننا تحسينه؟'
                  : 'What did you like? What could we improve?',
              hintStyle:
                  const TextStyle(fontSize: 14, color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.pearlGraySoft,
              counterStyle:
                  const TextStyle(fontSize: 11, color: AppColors.slate400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.silver),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.silver),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.aeGold, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 15, color: AppColors.slate900),
          ),
        ),
        const SizedBox(height: 16),

        // Topics
        _Card(
          label: isAr ? 'ما موضوع ملاحظتك؟' : 'What is your feedback about?',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < topics.length; i++)
                _Chip(
                  label: topics[i],
                  selected: _topics.contains(i),
                  onTap: () => setState(() =>
                      _topics.contains(i) ? _topics.remove(i) : _topics.add(i)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Visit purpose
        _Card(
          label: isAr ? 'عن زيارتك اليوم (اختياري)' : 'About your visit today (Optional)',
          child: Column(
            children: [
              for (var i = 0; i < visits.length; i++)
                _RadioRow(
                  title: visits[i].$1,
                  sub: visits[i].$2,
                  selected: _visit == i,
                  last: i == visits.length - 1,
                  onTap: () => setState(() => _visit = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.aeGold,
            disabledBackgroundColor: AppColors.aeGold.withValues(alpha: 0.4),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          ),
          onPressed: _rating == null ? null : _submit,
          child: Text(isAr ? 'إرسال الملاحظات' : 'Submit Feedback',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: Text(isAr ? 'تخطّي الآن' : 'Skip for now',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.slate600)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isAr
              ? 'ملاحظاتك مجهولة الهوية. نستخدم هذه المعلومات لتحسين التطبيق ولا نشاركها مع أطراف خارجية.'
              : 'Your feedback is anonymous. We use this to improve the app and do not share it with third parties.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, height: 1.5, color: AppColors.slate400),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmojiOption extends StatelessWidget {
  const _EmojiOption(
      {required this.emoji,
      required this.label,
      required this.selected,
      required this.onTap});
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.aeGoldBg : AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: selected ? AppColors.aeGold : AppColors.silver,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: selected ? 26 : 22)),
            const SizedBox(height: 6),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.slate400)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.aeGoldBg : AppColors.pearlGray,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.aeGold : AppColors.silver,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.aeGoldDeep : AppColors.slate600,
            )),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow(
      {required this.title,
      required this.sub,
      required this.selected,
      required this.last,
      required this.onTap});
  final String title, sub;
  final bool selected, last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.silver)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.aeGold : AppColors.slate300,
                  width: selected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate900)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, height: 1.35, color: AppColors.slate400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.isAr});
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.aeGold, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  size: 36, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              isAr ? 'شكراً لملاحظاتك!' : 'Thank you for your feedback!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900),
            ),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'تم استلام ملاحظاتك. نراجع جميع الرسائل ونستخدمها لتحسين التطبيق.'
                  : "We've received your feedback. We review all submissions and use them to improve UAE Stats.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, height: 1.55, color: AppColors.slate600),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.aeGold,
                minimumSize: const Size(240, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
              onPressed: () => context.go(AppRoutes.home),
              child: Text(isAr ? 'العودة للرئيسية' : 'Back to Home',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
