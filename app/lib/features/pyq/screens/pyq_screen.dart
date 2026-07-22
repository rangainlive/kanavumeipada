import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';
import '../models/pyq_models.dart';
import '../providers/pyq_provider.dart';

class PyqScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const PyqScreen({super.key, required this.subjectId});

  @override
  ConsumerState<PyqScreen> createState() => _PyqScreenState();
}

class _PyqScreenState extends ConsumerState<PyqScreen> {
  String? _selectedTopic;

  static const _primary = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    final topicsAsync = ref.watch(pyqTopicsProvider(widget.subjectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        leading: _selectedTopic != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedTopic = null),
              )
            : null,
        title: Text(
          _selectedTopic != null
              ? _toTitleCase(_selectedTopic!)
              : (isTamil ? 'முந்தைய ஆண்டு வினாக்கள்' : 'Previous Year Questions'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const LangToggleButton(),
          IconButton(
            tooltip: isTamil ? 'விடைகளை குறிக்கவும்' : 'Mark answers',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () => context.push('/pyq/${widget.subjectId}/admin'),
          ),
        ],
      ),
      body: _selectedTopic == null
          ? _TopicSectionList(
              topicsAsync: topicsAsync,
              isTamil: isTamil,
              onSelect: (t) => setState(() => _selectedTopic = t),
            )
          : _TopicQuestionList(
              subjectId: widget.subjectId,
              topic: _selectedTopic!,
              isTamil: isTamil,
            ),
    );
  }

  static String _toTitleCase(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// Vertical, section-wise list of topic cards (one per PYQ topic).
class _TopicSectionList extends StatelessWidget {
  final AsyncValue<List<PyqTopic>> topicsAsync;
  final bool isTamil;
  final ValueChanged<String> onSelect;
  const _TopicSectionList({required this.topicsAsync, required this.isTamil, required this.onSelect});

  static const _primary = Color(0xFF059669);
  static const _icons = [
    Icons.account_balance_rounded,
    Icons.trending_up_rounded,
    Icons.groups_rounded,
    Icons.public_rounded,
    Icons.school_rounded,
    Icons.gavel_rounded,
    Icons.eco_rounded,
    Icons.factory_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return topicsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
      error: (e, _) => Center(
        child: Text(
          isTamil ? 'தலைப்புகளை ஏற்ற முடியவில்லை' : 'Could not load topics',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return Center(
            child: Text(
              isTamil ? 'இன்னும் வினாக்கள் இல்லை' : 'No questions yet',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
        final total = topics.fold<int>(0, (sum, t) => sum + t.count);
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
          itemCount: topics.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 2),
                child: Text(
                  isTamil
                      ? '$total வினாக்கள் · ${topics.length} பிரிவுகள்'
                      : '$total questions · ${topics.length} sections',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              );
            }
            final t = topics[i - 1];
            return _TopicSectionCard(
              topic: t,
              icon: _icons[(i - 1) % _icons.length],
              onTap: () => onSelect(t.topic),
            );
          },
        );
      },
    );
  }
}

class _TopicSectionCard extends StatelessWidget {
  final PyqTopic topic;
  final IconData icon;
  final VoidCallback onTap;
  const _TopicSectionCard({required this.topic, required this.icon, required this.onTap});

  static const _primary = Color(0xFF059669);

  static String _toTitleCase(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _toTitleCase(topic.topic),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${topic.count}',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TopicQuestionList extends ConsumerWidget {
  final String subjectId;
  final String topic;
  final bool isTamil;
  const _TopicQuestionList({required this.subjectId, required this.topic, required this.isTamil});

  static const _primary = Color(0xFF059669);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(pyqQuestionsProvider(PyqQuestionsArgs(subjectId, topic)));
    return questionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
      error: (e, _) => Center(
        child: Text(
          isTamil ? 'வினாக்களை ஏற்ற முடியவில்லை' : 'Could not load questions',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
      data: (questions) {
        if (questions.isEmpty) {
          return Center(
            child: Text(
              isTamil ? 'வினாக்கள் இல்லை' : 'No questions found',
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
          itemCount: questions.length,
          itemBuilder: (ctx, i) => _PyqCard(
            question: questions[i],
            index: i,
            isTamil: isTamil,
          ),
        );
      },
    );
  }
}

class _PyqCard extends StatefulWidget {
  final PyqQuestion question;
  final int index;
  final bool isTamil;
  const _PyqCard({required this.question, required this.index, required this.isTamil});

  @override
  State<_PyqCard> createState() => _PyqCardState();
}

class _PyqCardState extends State<_PyqCard> {
  String? _selectedOptionId;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isTamil = widget.isTamil;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q${widget.index + 1}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ),
                const Spacer(),
                if (!q.answerMarked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      isTamil ? 'விடை சரிபார்க்கப்படவில்லை' : 'Unverified answer',
                      style: TextStyle(fontSize: 10.5, color: Colors.amber.shade800),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.display(isTamil),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            ...q.options.map((o) {
              final isSelected = _selectedOptionId == o.id;
              final revealed = _selectedOptionId != null && q.answerMarked;
              final isCorrectOpt = o.isCorrect;
              Color bg = const Color(0xFFF9FAFB);
              Color border = const Color(0xFFE5E7EB);
              Color fg = const Color(0xFF374151);
              if (revealed) {
                if (isCorrectOpt) {
                  bg = Colors.green.shade50;
                  border = Colors.green.shade300;
                  fg = Colors.green.shade800;
                } else if (isSelected) {
                  bg = Colors.red.shade50;
                  border = Colors.red.shade300;
                  fg = Colors.red.shade800;
                }
              } else if (isSelected) {
                bg = const Color(0xFF059669).withValues(alpha: 0.08);
                border = const Color(0xFF059669);
              }
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedOptionId = o.id);
                  if (!q.answerMarked) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isTamil
                          ? 'இந்த வினாவிற்கான விடை இன்னும் சரிபார்க்கப்படவில்லை'
                          : "This question's answer hasn't been verified yet"),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.display(isTamil),
                          style: TextStyle(fontSize: 13, color: fg, fontWeight: revealed && isCorrectOpt ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ),
                      if (revealed && isCorrectOpt)
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade600)
                      else if (revealed && isSelected)
                        Icon(Icons.cancel, size: 14, color: Colors.red.shade600),
                    ],
                  ),
                ),
              );
            }),
            if (q.examName != null && q.examName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${q.examName}${q.examYear != null ? ' — ${q.examYear}' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
