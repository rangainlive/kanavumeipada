import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../models/subject_model.dart';
import '../widgets/lang_toggle_button.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class Chapter {
  final String id;
  final String title;
  final String? titleTamil;
  final String? contentText;
  final String? contentTextTamil;
  final String? contentUrl;
  final int orderIndex;
  Chapter({
    required this.id,
    required this.title,
    this.titleTamil,
    this.contentText,
    this.contentTextTamil,
    this.contentUrl,
    required this.orderIndex,
  });
  factory Chapter.fromJson(Map<String, dynamic> j) => Chapter(
        id: j['id'],
        title: j['title'],
        titleTamil: j['titleTamil'],
        contentText: j['contentText'],
        contentTextTamil: j['contentTextTamil'],
        contentUrl: j['contentUrl'],
        orderIndex: j['orderIndex'] ?? 0,
      );
}

final _chaptersProvider =
    FutureProvider.autoDispose.family<List<Chapter>, String>((ref, subjectId) async {
  final token = ref.watch(authProvider).token;
  final response = await http.get(
    Uri.parse('$_apiUrl/subjects/$subjectId/chapters'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load chapters');
  final data = jsonDecode(response.body);
  final list = data is List ? data : (data['chapters'] as List? ?? []);
  return list.map((j) => Chapter.fromJson(j as Map<String, dynamic>)).toList();
});

class SubjectChaptersScreen extends ConsumerWidget {
  final String subjectId;
  final String? subjectName;
  const SubjectChaptersScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(_chaptersProvider(subjectId));
    final isTamil = ref.watch(studyLangProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTamil ? 'அத்தியாயங்கள்' : 'Chapters',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (subjectName != null)
              Text(subjectName!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: const [
          LangToggleButton(onLight: true),
          SizedBox(width: 8),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                isTamil ? 'அத்தியாயங்களை ஏற்ற முடியவில்லை' : 'Could not load chapters',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.refresh(_chaptersProvider(subjectId)),
                child: Text(isTamil ? 'மீண்டும் முயற்சி' : 'Retry'),
              ),
            ],
          ),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    isTamil
                        ? 'இன்னும் அத்தியாயங்கள் இல்லை.\nஉள்ளடக்கம் விரைவில் வருகிறது!'
                        : 'No chapters yet.\nContent coming soon!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final ch = chapters[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${ch.orderIndex + 1}',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(isTamil ? (ch.titleTamil ?? ch.title) : ch.title),
                  subtitle: (ch.contentText != null || ch.contentTextTamil != null)
                      ? Text(
                          isTamil
                              ? (ch.contentTextTamil ?? ch.contentText ?? '')
                              : (ch.contentText ?? ''),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, size: 20),
                        color: const Color(0xFF4338CA),
                        tooltip: isTamil ? 'AI மூலம் வினாக்கள் உருவாக்கு' : 'Generate Questions with AI',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push(
                          '/study/chapter/${ch.id}/generate',
                          extra: ch.title,
                        ),
                      ),
                      Icon(
                        ch.contentText != null || ch.contentUrl != null
                            ? Icons.chevron_right
                            : Icons.lock_outline,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  onTap: (ch.contentText != null || ch.contentTextTamil != null)
                      ? () => _showContent(context, ch, isTamil)
                      : null,

                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showContent(BuildContext context, Chapter chapter, bool isTamil) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(controller: controller, children: [
            Text(isTamil ? (chapter.titleTamil ?? chapter.title) : chapter.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Text(
              isTamil
                  ? (chapter.contentTextTamil ?? chapter.contentText ?? '')
                  : (chapter.contentText ?? ''),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ]),
        ),
      ),
    );
  }
}
