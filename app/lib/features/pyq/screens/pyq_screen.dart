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
    final questionsAsync = ref.watch(
      pyqQuestionsProvider(PyqQuestionsArgs(widget.subjectId, _selectedTopic)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          isTamil ? 'முந்தைய ஆண்டு வினாக்கள்' : 'Previous Year Questions',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
      body: Column(
        children: [
          // Topic filter chips
          topicsAsync.when(
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox.shrink(),
            data: (topics) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _TopicChip(
                    label: isTamil ? 'அனைத்தும்' : 'All',
                    selected: _selectedTopic == null,
                    onTap: () => setState(() => _selectedTopic = null),
                  ),
                  ...topics.map((t) => _TopicChip(
                        label: '${_toTitleCase(t.topic)} (${t.count})',
                        selected: _selectedTopic == t.topic,
                        onTap: () => setState(() => _selectedTopic = t.topic),
                      )),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: questionsAsync.when(
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
            ),
          ),
        ],
      ),
    );
  }

  static String _toTitleCase(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class _TopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TopicChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: selected,
        selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF059669) : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        ),
        onSelected: (_) => onTap(),
      ),
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
