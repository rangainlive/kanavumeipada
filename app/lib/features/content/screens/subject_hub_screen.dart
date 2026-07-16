import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subject_model.dart';
import '../widgets/lang_toggle_button.dart';

class SubjectHubScreen extends ConsumerWidget {
  final String subjectId;
  final Subject? subject;
  const SubjectHubScreen({
    super.key,
    required this.subjectId,
    this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);
    final category = subject?.examCategory ?? '';
    final fullName = subject?.name ?? 'Exam';
    final displayName = fullName.replaceFirst('$category ', '').trim();
    final colors = colorsFor(category.isEmpty ? null : category);
    final hasSyllabus = category == 'TNPSC';
    final hasDbSubject = subject != null && subject!.id.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: const [
              LangToggleButton(),
              SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors[0], colors[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            )),
                        if (category.isNotEmpty)
                          Text(category,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: colors[0],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    isTamil ? 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?' : 'What would you like to do?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),

                // Syllabus
                _FeatureCard(
                  emoji: '📋',
                  title: isTamil ? 'பாடத்திட்டம்' : 'Syllabus',
                  subtitle: isTamil
                      ? 'முழு பாடப்பட்டியல் — முன்னோட்ட & முதன்மை'
                      : 'Full topic list — Preliminary & Main',
                  accentColor: colors[0],
                  isLocked: !hasSyllabus,
                  onTap: hasSyllabus ? () => context.push('/study/syllabus') : null,
                ),

                // Chapters & Questions
                _FeatureCard(
                  emoji: '📚',
                  title: isTamil ? 'அத்தியாயங்கள் & வினாக்கள்' : 'Chapters & Questions',
                  subtitle: hasDbSubject
                      ? (isTamil ? 'அத்தியாயங்களை பாருங்கள், MCQ பயிற்சி' : 'Browse chapters and practice MCQs')
                      : (isTamil ? 'விரைவில் வருகிறது' : 'Content loading — check back soon'),
                  accentColor: colors[0],
                  isLocked: !hasDbSubject,
                  onTap: hasDbSubject
                      ? () => context.push('/study/subject/${subject!.id}', extra: fullName)
                      : null,
                ),

                // Practice Tests
                _FeatureCard(
                  emoji: '🎯',
                  title: isTamil ? 'பயிற்சி தேர்வுகள்' : 'Practice Tests',
                  subtitle: isTamil ? 'நேரமிட்ட மாதிரி தேர்வுகள் விரைவில்' : 'Timed mock tests coming soon',
                  accentColor: const Color(0xFF9CA3AF),
                  isLocked: true,
                ),

                // AI Generate
                _FeatureCard(
                  emoji: '🤖',
                  title: isTamil ? 'AI வினா உருவாக்கி' : 'AI Question Generator',
                  subtitle: isTamil ? 'உள்ளடக்கத்திலிருந்து MCQ தானாக உருவாக்கம்' : 'Auto-generate MCQs from content',
                  accentColor: const Color(0xFF9CA3AF),
                  isLocked: true,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends ConsumerWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isLocked;
  final VoidCallback? onTap;
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isLocked ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked
                  ? const Color(0xFFE5E7EB)
                  : accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isLocked
                    ? Colors.black.withValues(alpha: 0.04)
                    : accentColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? const Color(0xFFF3F4F6)
                        : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isLocked
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827),
                          )),
                      const SizedBox(height: 3),
                      Text(
                        isLocked
                            ? (isTamil ? 'விரைவில் வருகிறது' : 'Coming soon')
                            : subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                isLocked
                    ? const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFD1D5DB), size: 20)
                    : Icon(Icons.arrow_forward_ios_rounded,
                        color: accentColor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
