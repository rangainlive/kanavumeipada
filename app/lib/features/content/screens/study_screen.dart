import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class Subject {
  final String id;
  final String name;
  final String? icon;
  final String? examCategory;
  Subject({required this.id, required this.name, this.icon, this.examCategory});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
        id: j['id'],
        name: j['name'],
        icon: j['icon'],
        examCategory: j['examCategory'],
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

// Map of exam categories to color accents for the subject grid
const _categoryColors = {
  'UPSC': Color(0xFF6366F1),
  'TNPSC': Color(0xFF0EA5E9),
  'SSC': Color(0xFF10B981),
  'Banking': Color(0xFFF59E0B),
  'NEET': Color(0xFFEF4444),
  'JEE': Color(0xFF8B5CF6),
};

class StudyScreen extends ConsumerWidget {
  const StudyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final now = DateTime.now();
    final dateStr = '${_month(now.month)} ${now.day}, ${now.year}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Study'),
            floating: true,
            snap: true,
            forceElevated: false,
          ),

          SliverToBoxAdapter(
            child: _CurrentAffairsCard(dateStr: dateStr),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),

          subjectsAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('Could not load subjects.\n$e', textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.refresh(subjectsProvider),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
            ),
            data: (subjects) {
              if (subjects.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No subjects yet.\nContent is being added — check back soon!',
                          textAlign: TextAlign.center),
                    ]),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SubjectCard(
                      subject: subjects[i],
                      onTap: () => context.push('/study/subject/${subjects[i].id}',
                          extra: subjects[i].name),
                    ),
                    childCount: subjects.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

class _CurrentAffairsCard extends StatelessWidget {
  final String dateStr;
  const _CurrentAffairsCard({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today\'s Current Affairs',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Coming Soon',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.newspaper_rounded, color: Colors.white38, size: 56),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;
  const _SubjectCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[subject.examCategory] ??
        Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subject.icon ?? '📚',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subject.examCategory != null)
                    Text(subject.examCategory!,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: color)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
