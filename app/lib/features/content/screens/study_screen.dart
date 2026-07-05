import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class Subject {
  final String id;
  final String name;
  final String? icon;
  final String? examCategory;
  Subject({required this.id, required this.name, this.icon, this.examCategory});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'], name: j['name'],
        icon: j['icon'], examCategory: j['examCategory'],
      );
}

final subjectsProvider = FutureProvider.autoDispose<List<Subject>>((ref) async {
  final token = ref.watch(authProvider).token;
  final response = await http.get(
    Uri.parse('$_apiUrl/subjects'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load subjects');
  final data = jsonDecode(response.body);
  final list = data is List ? data : (data['subjects'] as List? ?? []);
  return list.map((j) => Subject.fromJson(j as Map<String, dynamic>)).toList();
});

const _catColors = {
  'UPSC':    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  'TNPSC':   [Color(0xFF059669), Color(0xFF0EA5E9)],
  'SSC':     [Color(0xFFD97706), Color(0xFFF59E0B)],
  'Banking': [Color(0xFF0EA5E9), Color(0xFF6366F1)],
  'NEET':    [Color(0xFFDC2626), Color(0xFFEC4899)],
  'JEE':     [Color(0xFF7C3AED), Color(0xFFEC4899)],
};

List<Color> _colorsFor(String? cat) =>
    _catColors[cat] ?? [AppTheme.primary, AppTheme.secondary];

class StudyScreen extends ConsumerWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
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
                        const Text('Study Hub 📚',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            )),
                        const Spacer(),
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
                      Text('Master every topic, ace every exam',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          )),
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
                  const Text('All Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      )),
                  const Spacer(),
                  subjectsAsync.whenOrNull(
                        data: (s) => Text('${s.length} subjects',
                            style: const TextStyle(
                                fontSize: 12.5, color: AppTheme.textHint)),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
          ),

          // Subjects grid
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
              if (subjects.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptySubjects());
              }
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
                    (ctx, i) => _SubjectCard(
                      subject: subjects[i],
                      index: i,
                      onTap: () => ctx.push(
                          '/study/subject/${subjects[i].id}',
                          extra: subjects[i].name),
                    ),
                    childCount: subjects.length,
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

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final int index;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(subject.examCategory);
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
              Text(subject.icon ?? '📖',
                  style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 13),
            ]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (subject.examCategory != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(subject.examCategory!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySubjects extends StatelessWidget {
  const _EmptySubjects();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📖', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        const Text('Subjects coming soon!',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text('We\'re adding quality content — check back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
      ]),
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
