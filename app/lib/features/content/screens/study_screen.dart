import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subject_model.dart';
import '../widgets/lang_toggle_button.dart';
import '../../../core/theme/app_theme.dart';

class StudyScreen extends ConsumerWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final isTamil = ref.watch(studyLangProvider);
    final now = DateTime.now();
    final months = ['', 'Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${months[now.month]} ${now.day}, ${now.year}';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0EA5E9)],
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
                        Text(isTamil ? 'படிப்பு மையம் 📚' : 'Study Hub 📚',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            )),
                        const Spacer(),
                        const LangToggleButton(),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(dateStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        isTamil
                            ? 'ஒவ்வொரு தலைப்பையும் தேர்ச்சி பெறுங்கள்'
                            : 'Master every topic, ace every exam',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Current affairs card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          const Text('📰', style: TextStyle(fontSize: 36)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Today's Current Affairs",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(dateStr,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    )),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Soon',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Section header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(isTamil ? 'தேர்வு வகைகள்' : 'Exam Categories',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      )),
                  const Spacer(),
                  subjectsAsync.whenOrNull(
                        data: (s) {
                          final cats = s.map((x) => x.examCategory ?? 'Other').toSet();
                          final n = cats.isEmpty ? 1 : cats.length;
                          return Text(
                            isTamil ? '$n வகைகள்' : '$n categories',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textHint),
                          );
                        },
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Category cards grid
          subjectsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorState(
                onRetry: () => ref.refresh(subjectsProvider),
              ),
            ),
            data: (subjects) {
              // Group by examCategory — but always include TNPSC even if DB empty
              final Map<String, List<Subject>> byCategory = {};
              for (final s in subjects) {
                final cat = s.examCategory ?? 'Other';
                byCategory.putIfAbsent(cat, () => []).add(s);
              }
              // TNPSC is always present regardless of API data
              byCategory.putIfAbsent('TNPSC', () => []);
              final categories = byCategory.entries.toList()
                ..sort((a, b) => a.key == 'TNPSC' ? -1 : (b.key == 'TNPSC' ? 1 : a.key.compareTo(b.key)));

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final cat = categories[i].key;
                      final subs = categories[i].value;
                      return _CategoryCard(
                        category: cat,
                        subjects: subs,
                        onTap: () => ctx.push('/study/category/$cat'),
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String category;
  final List<Subject> subjects;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.category,
    required this.subjects,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = colorsFor(category);
    final icon = subjects.isNotEmpty ? (subjects.first.icon ?? '📖') : '📋';
    final examCount = subjects.length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors[0], colors[1]],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.35),
              blurRadius: 12,
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
              Text(icon, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 13),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    )),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    examCount > 0 ? '$examCount exam${examCount > 1 ? "s" : ""}' : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textHint),
        const SizedBox(height: 12),
        const Text('Could not load subjects',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
