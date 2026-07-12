import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/generation_provider.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';

class GenerateScreen extends ConsumerStatefulWidget {
  final String chapterId;
  final String? chapterTitle;

  const GenerateScreen({
    super.key,
    required this.chapterId,
    this.chapterTitle,
  });

  @override
  ConsumerState<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends ConsumerState<GenerateScreen> {
  int _count = 10;
  int _difficulty = 2;
  String _bloomLevel = 'understand';

  static const _primary = Color(0xFF4338CA);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generationProvider(widget.chapterId));
    final notifier = ref.read(generationProvider(widget.chapterId).notifier);
    final isTamil = ref.watch(studyLangProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTamil ? 'AI வினா உருவாக்கி' : 'AI Question Generator',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (widget.chapterTitle != null)
              Text(
                widget.chapterTitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          const LangToggleButton(),
          const SizedBox(width: 4),
          if (state.hasResults)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    '${state.approvedCount}/${state.questions.length} ✓',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? _buildLoading(isTamil)
          : state.hasResults
              ? _buildReview(state, notifier, isTamil)
              : _buildConfigure(context, state, notifier, isTamil),
    );
  }

  Widget _buildLoading(bool isTamil) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 3, color: _primary),
          ),
          const SizedBox(height: 24),
          Text(
            isTamil ? 'AI மூலம் வினாக்கள் உருவாக்கப்படுகின்றன...' : 'Generating questions with AI...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isTamil ? 'இது 10–30 வினாடிகள் ஆகலாம்' : 'This may take 10–30 seconds',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigure(
    BuildContext context,
    GenerationState state,
    GenerationNotifier notifier,
    bool isTamil,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.auto_awesome, size: 52, color: _primary)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              isTamil ? 'AI மூலம் உருவாக்கு' : 'Generate with AI',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              isTamil
                  ? 'Gemini மூலம் அத்தியாய உள்ளடக்கத்திலிருந்து MCQ உருவாக்கும்'
                  : 'Creates MCQs from chapter content using Gemini',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          _label(isTamil ? 'உருவாக்க வேண்டிய வினாக்கள்' : 'Questions to generate'),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _count.toDouble(),
                  min: 3,
                  max: 20,
                  divisions: 17,
                  activeColor: _primary,
                  label: '$_count',
                  onChanged: (v) => setState(() => _count = v.round()),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$_count',
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _label(isTamil ? 'கடினத்தன்மை' : 'Difficulty'),
          Wrap(
            spacing: 8,
            children: [
              _chip(isTamil ? 'எளிதானது' : 'Easy', _difficulty == 1, () => setState(() => _difficulty = 1)),
              _chip(isTamil ? 'நடுத்தரம்' : 'Medium', _difficulty == 2, () => setState(() => _difficulty = 2)),
              _chip(isTamil ? 'கடினம்' : 'Hard', _difficulty == 3, () => setState(() => _difficulty = 3)),
            ],
          ),
          const SizedBox(height: 20),

          _label(isTamil ? 'அறிவு நிலை' : 'Cognitive Level'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(isTamil ? 'நினைவு' : 'Recall', _bloomLevel == 'remember',
                  () => setState(() => _bloomLevel = 'remember')),
              _chip(isTamil ? 'புரிதல்' : 'Understand', _bloomLevel == 'understand',
                  () => setState(() => _bloomLevel = 'understand')),
              _chip(isTamil ? 'பயன்பாடு' : 'Apply', _bloomLevel == 'apply',
                  () => setState(() => _bloomLevel = 'apply')),
              _chip(isTamil ? 'பகுப்பாய்வு' : 'Analyze', _bloomLevel == 'analyze',
                  () => setState(() => _bloomLevel = 'analyze')),
            ],
          ),
          const SizedBox(height: 32),

          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          state.error!,
                          style:
                              TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (state.error!.toLowerCase().contains('content')) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: Text(isTamil ? 'அத்தியாய உள்ளடக்கம் சேர்க்கவும்' : 'Add Chapter Content'),
                      style: TextButton.styleFrom(
                        foregroundColor: _primary,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _showContentDialog(context, isTamil),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text(
                isTamil ? 'வினாக்கள் உருவாக்கு' : 'Generate Questions',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () => notifier.generate(
                count: _count,
                difficulty: _difficulty,
                bloomLevel: _bloomLevel,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Requires GEMINI_API_KEY on the server',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReview(GenerationState state, GenerationNotifier notifier, bool isTamil) {
    return Column(
      children: [
        Container(
          color: _primary.withOpacity(0.06),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isTamil
                      ? '${state.questions.length} வினாக்கள் உருவாக்கப்பட்டன'
                      : '${state.questions.length} questions generated',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (state.pendingCount > 0)
                TextButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    isTamil
                        ? 'அனைத்தையும் அனுமதி (${state.pendingCount})'
                        : 'Approve all (${state.pendingCount})',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: notifier.approveAll,
                )
              else
                Text(
                  isTamil
                      ? '${state.approvedCount} அனுமதிக்கப்பட்டவை · '
                          '${state.questions.length - state.approvedCount} நிராகரிக்கப்பட்டவை'
                      : '${state.approvedCount} approved · '
                          '${state.questions.length - state.approvedCount} rejected',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
            itemCount: state.questions.length,
            itemBuilder: (ctx, i) {
              final q = state.questions[i];
              return _QuestionCard(
                question: q,
                index: i,
                isTamil: isTamil,
                onApprove: () => notifier.approve(q.id),
                onReject: () => notifier.reject(q.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showContentDialog(BuildContext context, bool isTamil) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isTamil ? 'அத்தியாய உள்ளடக்கம் சேர்க்கவும்' : 'Add Chapter Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTamil
                  ? 'அத்தியாய உரையை ஒட்டவும் (குறைந்தது 100 எழுத்துகள்). MCQ உருவாக்க பயன்படும்.'
                  : 'Paste the chapter text (min 100 chars). This will be used to generate MCQs.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: isTamil ? 'அத்தியாய உள்ளடக்கத்தை இங்கே ஒட்டவும்...' : 'Paste chapter content here...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isTamil ? 'ரத்து செய்' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = ctrl.text.trim();
              if (text.length < 100) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTamil
                          ? 'உள்ளடக்கம் குறைந்தது 100 எழுத்துகள் இருக்க வேண்டும்'
                          : 'Content must be at least 100 characters',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final error = await ref
                  .read(generationProvider(widget.chapterId).notifier)
                  .uploadContent(text);
              if (!mounted) return;
              messenger.showSnackBar(
                error != null
                    ? SnackBar(
                        content: Text(isTamil ? 'பதிவேற்றம் தோல்வி: $error' : 'Upload failed: $error'),
                        backgroundColor: Colors.red,
                      )
                    : SnackBar(
                        content: Text(isTamil ? 'உள்ளடக்கம் சேமிக்கப்பட்டது! இப்போது உருவாக்கு தட்டவும்.' : 'Content saved! Now tap Generate.'),
                        backgroundColor: Colors.green,
                      ),
              );
            },
            child: Text(isTamil ? 'உள்ளடக்கம் சேமி' : 'Save Content'),
          ),
        ],
      ),
    );
  }

  static Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF374151),
          ),
        ),
      );

  static Widget _chip(String label, bool selected, VoidCallback onTap) =>
      ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: const Color(0xFF4338CA).withOpacity(0.15),
        labelStyle: TextStyle(
          color: selected ? const Color(0xFF4338CA) : Colors.grey.shade700,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        onSelected: (_) => onTap(),
      );
}

class _QuestionCard extends StatelessWidget {
  final AiQuestion question;
  final int index;
  final bool isTamil;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.isTamil,
    required this.onApprove,
    required this.onReject,
  });

  static const _primary = Color(0xFF4338CA);

  @override
  Widget build(BuildContext context) {
    final approved = question.review == ReviewStatus.approved;
    final rejected = question.review == ReviewStatus.rejected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: approved
            ? Colors.green.shade50
            : rejected
                ? Colors.red.shade50
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: approved
              ? Colors.green.shade200
              : rejected
                  ? Colors.red.shade200
                  : const Color(0xFFE5E7EB),
        ),
        boxShadow: approved || rejected
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _badge('Q${index + 1}', _primary.withOpacity(0.1), _primary),
                const SizedBox(width: 6),
                _DifficultyBadge(question.difficulty),
                const SizedBox(width: 6),
                _BloomBadge(question.bloomLevel),
                const Spacer(),
                if (approved)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20)
                else if (rejected)
                  const Icon(Icons.cancel, color: Colors.red, size: 20),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              question.text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),

            ...question.options.asMap().entries.map((e) {
              final isCorrect = e.key == question.correctIndex;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.shade50
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.shade300
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + e.key),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isCorrect
                            ? Colors.green.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value.text,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCorrect
                              ? Colors.green.shade800
                              : const Color(0xFF374151),
                          fontWeight: isCorrect
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green.shade600),
                  ],
                ),
              );
            }),

            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFCD34D).withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!approved && !rejected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(isTamil ? 'நிராகரி' : 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onReject,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(isTamil ? 'அனுமதி' : 'Approve'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: onApprove,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: fg),
        ),
      );
}

class _DifficultyBadge extends StatelessWidget {
  final int difficulty;
  const _DifficultyBadge(this.difficulty);

  @override
  Widget build(BuildContext context) {
    final label =
        difficulty == 1 ? 'Easy' : difficulty == 3 ? 'Hard' : 'Medium';
    final color =
        difficulty == 1 ? Colors.green : difficulty == 3 ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color.shade700),
      ),
    );
  }
}

class _BloomBadge extends StatelessWidget {
  final String bloomLevel;
  const _BloomBadge(this.bloomLevel);

  @override
  Widget build(BuildContext context) {
    final label = switch (bloomLevel) {
      'remember' => 'Recall',
      'understand' => 'Understand',
      'apply' => 'Apply',
      'analyze' => 'Analyze',
      _ => bloomLevel,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6D28D9)),
      ),
    );
  }
}
