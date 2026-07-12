import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';

class _Exam {
  final String name, emoji, subtitle, subtitleTamil;
  final List<Color> colors;
  const _Exam(this.name, this.emoji, this.colors, this.subtitle, this.subtitleTamil);
}

const _exams = [
  _Exam('UPSC',    '🏛️', [Color(0xFF4F46E5), Color(0xFF7C3AED)], 'Civil Services',        'சிவில் சேவைகள்'),
  _Exam('TNPSC',   '🌴', [Color(0xFF059669), Color(0xFF0EA5E9)], 'State Services',         'மாநில சேவைகள்'),
  _Exam('SSC',     '⚖️', [Color(0xFFD97706), Color(0xFFF59E0B)], 'Combined Exams',         'ஒருங்கிணைந்த தேர்வுகள்'),
  _Exam('Banking', '🏦', [Color(0xFF0EA5E9), Color(0xFF4F46E5)], 'PO / Clerk / SO',        'PO / குமாஸ்தா / SO'),
  _Exam('NEET',    '🩺', [Color(0xFFDC2626), Color(0xFFEC4899)], 'Medical Entrance',       'மருத்துவ நுழைவு'),
  _Exam('JEE',     '🔬', [Color(0xFF7C3AED), Color(0xFFEC4899)], 'Engineering Entrance',   'பொறியியல் நுழைவு'),
];

class TestsScreen extends ConsumerWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFEF4444)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(isTamil ? 'தேர்வு அரங்கம் 🎯' : 'Test Arena 🎯',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            )),
                        const Spacer(),
                        const LangToggleButton(),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        isTamil
                            ? 'பயிற்சி • போட்டி • தேசிய தரவரிசை'
                            : 'Practice • Compete • Rank nationally',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Daily quiz card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          const Text('🎯', style: TextStyle(fontSize: 38)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTamil ? 'தினசரி சவால்' : 'Daily Challenge',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  isTamil ? '10 வினாக்கள் · 50 🪙 பெறுங்கள்' : '10 questions · Earn 50 🪙',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(isTamil
                                  ? 'தினசரி வினாடி வினா விரைவில் வருகிறது!'
                                  : 'Daily quiz launching soon!'),
                              behavior: SnackBarBehavior.floating,
                            )),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isTamil ? 'தொடங்கு' : 'Start',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats strip
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickStat('0',  isTamil ? 'எடுத்த தேர்வுகள்' : 'Tests Taken',  Icons.assignment_turned_in_rounded),
                  _vDivider(),
                  _QuickStat('0%', isTamil ? 'சராசரி மதிப்பெண்' : 'Avg Score',    Icons.bar_chart_rounded),
                  _vDivider(),
                  _QuickStat('—',  isTamil ? 'தரவரிசை' : 'Rank',                  Icons.leaderboard_rounded),
                ],
              ),
            ),
          ),

          // Section title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                isTamil ? 'தேர்வின் படி தேர்வு செய்யுங்கள்' : 'Choose by Exam',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),

          // Exam grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _ExamCard(
                  exam: _exams[i],
                  isTamil: isTamil,
                  onTap: () => ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('${_exams[i].name} ${isTamil ? 'தேர்வுகள் விரைவில் வருகிறது!' : 'tests coming soon!'}'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  )),
                ),
                childCount: _exams.length,
              ),
            ),
          ),

          // Coming soon banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.07),
                      AppTheme.secondary.withValues(alpha: 0.07),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15)),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const Text('🚀', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTamil ? 'முழு மாதிரி தேர்வுகள் வருகின்றன' : 'Full Mock Tests Coming',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isTamil
                              ? 'தேசிய தரவரிசை, விரிவான பகுப்பாய்வு மற்றும் AI கருத்துரை.'
                              : 'National rankings, detailed analysis, and AI-powered feedback.',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _vDivider() => Container(
    height: 36, width: 1, color: const Color(0xFFE2E8F0));

class _QuickStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _QuickStat(this.value, this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 18, color: AppTheme.primary),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary)),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
    ]);
  }
}

class _ExamCard extends StatelessWidget {
  final _Exam exam;
  final bool isTamil;
  final VoidCallback onTap;
  const _ExamCard({required this.exam, required this.isTamil, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: exam.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: exam.colors[0].withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(exam.emoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 12),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  )),
              Text(isTamil ? exam.subtitleTamil : exam.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                  )),
            ]),
          ],
        ),
      ),
    );
  }
}
