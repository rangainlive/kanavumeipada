import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';
import '../models/pyq_models.dart';
import '../providers/pyq_provider.dart';

class PyqAdminScreen extends ConsumerWidget {
  final String subjectId;
  const PyqAdminScreen({super.key, required this.subjectId});

  static const _primary = Color(0xFF059669);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);
    final unmarkedAsync = ref.watch(pyqUnmarkedProvider(subjectId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Text(
          isTamil ? 'சரியான விடையை குறிக்கவும்' : 'Mark Correct Answers',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: const [LangToggleButton(), SizedBox(width: 8)],
      ),
      body: unmarkedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
        error: (e, _) => Center(
          child: Text(
            isTamil ? 'ஏற்ற முடியவில்லை' : 'Could not load',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        data: (questions) {
          if (questions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF059669)),
                    const SizedBox(height: 12),
                    Text(
                      isTamil
                          ? 'சரிபார்க்க வேண்டிய வினாக்கள் இல்லை!'
                          : 'No questions left to verify!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
            itemCount: questions.length,
            itemBuilder: (ctx, i) => _AdminQuestionCard(
              question: questions[i],
              index: i,
              isTamil: isTamil,
              subjectId: subjectId,
            ),
          );
        },
      ),
    );
  }
}

class _AdminQuestionCard extends ConsumerStatefulWidget {
  final PyqQuestion question;
  final int index;
  final bool isTamil;
  final String subjectId;
  const _AdminQuestionCard({
    required this.question,
    required this.index,
    required this.isTamil,
    required this.subjectId,
  });

  @override
  ConsumerState<_AdminQuestionCard> createState() => _AdminQuestionCardState();
}

class _AdminQuestionCardState extends ConsumerState<_AdminQuestionCard> {
  bool _saving = false;

  Future<void> _mark(String optionId) async {
    setState(() => _saving = true);
    final error = await ref.read(pyqAdminProvider.notifier).markAnswer(widget.question.id, optionId);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ref.invalidate(pyqUnmarkedProvider(widget.subjectId));
  }

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
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
                  child: Text('Q${widget.index + 1}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ),
                const SizedBox(width: 8),
                if (q.topic != null)
                  Expanded(
                    child: Text(
                      q.topic!,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              q.text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5, color: Color(0xFF111827)),
            ),
            if (isTamil && q.textTamil != null) ...[
              const SizedBox(height: 6),
              Text(
                q.textTamil!,
                style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF4B5563)),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              isTamil ? 'சரியான விடையை தட்டவும்:' : 'Tap the correct option:',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            ...q.options.map((o) => GestureDetector(
                  onTap: _saving ? null : () => _mark(o.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(o.text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                        ),
                        if (_saving)
                          const SizedBox(
                              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.radio_button_unchecked, size: 16, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                )),
            if (q.examName != null && q.examName!.isNotEmpty) ...[
              const SizedBox(height: 4),
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
