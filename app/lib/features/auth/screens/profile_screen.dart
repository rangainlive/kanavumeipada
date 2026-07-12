import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) return const SizedBox.shrink();

    final isTamil = ref.watch(studyLangProvider);
    final initials = _initials(user.name ?? user.phone ?? '?');
    final exams = (user.examTarget ?? '').split(',').where((e) => e.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Gradient hero
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    children: [
                      // Toggle row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [const LangToggleButton()],
                      ),
                      const SizedBox(height: 8),
                      // Avatar
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              )),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.name ?? 'Welcome!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 4),
                      if (user.phone != null)
                        Text(user.phone!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            )),
                      const SizedBox(height: 12),
                      // Exam tags
                      if (exams.isNotEmpty)
                        Wrap(
                          spacing: 6, runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: exams.map((e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(e.trim(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                )),
                          )).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      _StatItem(
                        icon: '🪙',
                        value: '${user.coinsBalance}',
                        label: isTamil ? 'நாணயங்கள்' : 'Coins',
                        color: AppTheme.warning,
                      ),
                      _vDiv(),
                      _StatItem(
                        icon: '⚡',
                        value: '${user.xp}',
                        label: 'XP',
                        color: AppTheme.primary,
                      ),
                      _vDiv(),
                      _StatItem(
                        icon: '🔥',
                        value: '—',
                        label: isTamil ? 'தொடர்ச்சி' : 'Streak',
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // XP level card
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('⚡',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(isTamil ? 'நிலை ${(user.xp ~/ 100) + 1}' : 'Level ${(user.xp ~/ 100) + 1}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          const Spacer(),
                          Text('${user.xp % 100} / 100 XP',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textHint)),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (user.xp % 100) / 100.0,
                            minHeight: 10,
                            backgroundColor: AppTheme.bgLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTamil
                              ? 'தினசரி வினாடி வினா மற்றும் போர்களை முடித்து நிலை உயர்த்துங்கள்!'
                              : 'Complete daily quizzes and battles to level up!',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // How to earn
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('💰', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(isTamil ? 'நாணயங்கள் எப்படி சம்பாதிப்பது' : 'How to Earn Coins',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                        ]),
                        const SizedBox(height: 12),
                        _EarnRow('🎯', isTamil ? 'தினசரி வினாடி வினா முடிக்கவும்' : 'Complete daily quiz', '+50 🪙'),
                        _EarnRow('⚔️', isTamil ? 'ஒரு போரில் வெற்றி' : 'Win a battle', 'Prize pool 🪙'),
                        _EarnRow('🔥', isTamil ? 'தினசரி தொடர்ச்சி போனஸ்' : 'Daily streak bonus', '+20 🪙/day'),
                        _EarnRow('🎉', isTamil ? 'சாதனையை பகிர்' : 'Share achievement', '+10 🪙'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Your exams
                  if (exams.isNotEmpty)
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Text('🎓', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(isTamil ? 'உங்கள் தேர்வுகள்' : 'Your Exams',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary)),
                          ]),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: exams.map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(e.trim(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  )),
                            )).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isTamil
                                ? 'தமிழ்நாடு பகுதி · ஊட்டம் மற்றும் தேர்வுகள் உங்கள் தேர்வுகளுக்கு ஏற்ப தனிப்பயனாக்கப்பட்டுள்ளன.'
                                : 'Tamil Nadu region · Feed and tests are personalized for your exams.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.2)),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(context, ref, isTamil),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 18),
                        label: Text(isTamil ? 'வெளியேறு' : 'Sign Out',
                            style: const TextStyle(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Center(
                    child: Text('KanavuMeipada v1.0.0',
                        style: TextStyle(
                            color: AppTheme.textHint, fontSize: 11)),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  void _confirmLogout(BuildContext context, WidgetRef ref, bool isTamil) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.logout_rounded,
                size: 44, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(isTamil ? 'வெளியேற வேண்டுமா?' : 'Sign Out?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'உங்கள் கணக்கை அணுக மீண்டும் உள்நுழைய வேண்டும்.'
                  : 'You\'ll need to sign in again to access your account.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).logout();
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isTamil ? 'ஆம், வெளியேறு' : 'Yes, Sign Out',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTamil ? 'ரத்து செய்' : 'Cancel',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 15)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

Widget _vDiv() => Container(
    width: 1, height: 40, color: const Color(0xFFE2E8F0));

class _StatItem extends StatelessWidget {
  final String icon, value, label;
  final Color color;
  const _StatItem({required this.icon, required this.value,
      required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textHint)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }
}

class _EarnRow extends StatelessWidget {
  final String emoji, label, reward;
  const _EarnRow(this.emoji, this.label, this.reward);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ),
        Text(reward,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.accent)),
      ]),
    );
  }
}
