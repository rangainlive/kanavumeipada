import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

enum _PostKind { text, mcq, poll, score }

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  _PostKind _kind = _PostKind.text;
  bool _submitting = false;
  String? _error;

  // Text post
  final _textCtrl = TextEditingController();

  // MCQ
  final _mcqQCtrl = TextEditingController();
  final _mcqOpts = List.generate(4, (_) => TextEditingController());
  int _mcqAnswer = 0;

  // Poll
  final _pollQCtrl = TextEditingController();
  final _pollOpts = [
    TextEditingController(),
    TextEditingController(),
  ];

  // Score
  String _scoreExam = 'TNPSC';
  final _scoreMarksCtrl = TextEditingController();
  final _scoreNoteCtrl = TextEditingController();
  static const _scoreExams = ['UPSC', 'TNPSC', 'SSC', 'Banking', 'NEET', 'JEE'];

  late AnimationController _tabAnim;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _tabAnim.forward();
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    _textCtrl.dispose();
    _mcqQCtrl.dispose();
    for (final c in _mcqOpts) c.dispose();
    _pollQCtrl.dispose();
    for (final c in _pollOpts) c.dispose();
    _scoreMarksCtrl.dispose();
    _scoreNoteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    switch (_kind) {
      case _PostKind.text:
        return _textCtrl.text.trim().isNotEmpty;
      case _PostKind.mcq:
        return _mcqQCtrl.text.trim().isNotEmpty &&
            _mcqOpts.every((c) => c.text.trim().isNotEmpty);
      case _PostKind.poll:
        return _pollQCtrl.text.trim().isNotEmpty &&
            _pollOpts.where((c) => c.text.trim().isNotEmpty).length >= 2;
      case _PostKind.score:
        return _scoreMarksCtrl.text.trim().isNotEmpty;
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit || _submitting) return;
    setState(() { _submitting = true; _error = null; });

    String postType = 'discussion';
    String bodyText = '';

    switch (_kind) {
      case _PostKind.text:
        bodyText = _textCtrl.text.trim();
        break;
      case _PostKind.mcq:
        postType = 'discussion';
        bodyText = jsonEncode({
          '_t': 'mcq',
          'q': _mcqQCtrl.text.trim(),
          'opts': _mcqOpts.map((c) => c.text.trim()).toList(),
          'ans': _mcqAnswer,
        });
        break;
      case _PostKind.poll:
        postType = 'discussion';
        bodyText = jsonEncode({
          '_t': 'poll',
          'q': _pollQCtrl.text.trim(),
          'opts': _pollOpts
              .where((c) => c.text.trim().isNotEmpty)
              .map((c) => c.text.trim())
              .toList(),
        });
        break;
      case _PostKind.score:
        postType = 'result_shared';
        bodyText = jsonEncode({
          '_t': 'score',
          'exam': _scoreExam,
          'marks': _scoreMarksCtrl.text.trim(),
          'note': _scoreNoteCtrl.text.trim(),
        });
        break;
    }

    final token = ref.read(authProvider).token;
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/feed/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'postType': postType, 'bodyText': bodyText}),
      );
      if (r.statusCode == 201) {
        ref.read(feedProvider.notifier).loadFeed(refresh: true);
        if (mounted) context.pop();
      } else {
        final d = jsonDecode(r.body);
        setState(() => _error = d['error'] ?? 'Post failed');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _switchKind(_PostKind k) {
    setState(() => _kind = k);
    _tabAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Post',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _canSubmit ? AppTheme.brandGradient : null,
                color: _canSubmit ? null : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _canSubmit
                    ? [BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : null,
              ),
              child: TextButton(
                onPressed: _canSubmit && !_submitting ? _submit : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Post',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _canSubmit
                              ? Colors.white
                              : AppTheme.textHint,
                        )),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post type selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: _PostKind.values.map((k) {
                final selected = _kind == k;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _switchKind(k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.brandGradient : null,
                        color: selected ? null : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_kindEmoji(k),
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(_kindLabel(k),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppTheme.textHint,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Content form
          Expanded(
            child: FadeTransition(
              opacity: _tabAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16),
                child: _buildForm(),
              ),
            ),
          ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppTheme.error.withValues(alpha: 0.08),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13))),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    switch (_kind) {
      case _PostKind.text: return _buildText();
      case _PostKind.mcq: return _buildMCQ();
      case _PostKind.poll: return _buildPoll();
      case _PostKind.score: return _buildScore();
    }
  }

  // ── Text ──────────────────────────────────────────────────────────────────

  Widget _buildText() {
    final count = _textCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('What\'s on your mind?',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ),
        TextField(
          controller: _textCtrl,
          autofocus: true,
          maxLength: 500,
          maxLines: 10,
          minLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText:
                'Share a study tip, important topic, concept, or anything useful for your fellow aspirants…',
            hintStyle: const TextStyle(color: AppTheme.textHint, fontSize: 14),
            hintMaxLines: 4,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
          style: const TextStyle(
              fontSize: 15, color: AppTheme.textPrimary, height: 1.5),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('$count / 500',
                  style: TextStyle(
                      fontSize: 11,
                      color: count > 450 ? AppTheme.error : AppTheme.textHint)),
            ],
          ),
        ),
      ],
    );
  }

  // ── MCQ ───────────────────────────────────────────────────────────────────

  Widget _buildMCQ() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Question'),
          _inputField(_mcqQCtrl, 'Type your MCQ question here…', maxLines: 3),
          const SizedBox(height: 20),
          _label('Answer Options'),
          const SizedBox(height: 4),
          Text('Tap the circle to mark the correct answer',
              style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
          const SizedBox(height: 12),
          ...List.generate(4, (i) {
            final isCorrect = _mcqAnswer == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => setState(() => _mcqAnswer = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      gradient: isCorrect ? AppTheme.accentGradient : null,
                      border: isCorrect
                          ? null
                          : Border.all(color: const Color(0xFFCBD5E1), width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        ['A', 'B', 'C', 'D'][i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isCorrect ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _mcqOpts[i],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Option ${['A', 'B', 'C', 'D'][i]}',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: isCorrect
                          ? AppTheme.accent.withValues(alpha: 0.06)
                          : AppTheme.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isCorrect
                                ? AppTheme.accent.withValues(alpha: 0.4)
                                : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: isCorrect
                                ? AppTheme.accent.withValues(alpha: 0.4)
                                : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                if (isCorrect) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.accent, size: 20),
                ],
              ]),
            );
          }),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: AppTheme.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Correct answer: Option ${['A', 'B', 'C', 'D'][_mcqAnswer]}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Poll ──────────────────────────────────────────────────────────────────

  Widget _buildPoll() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Poll Question'),
          _inputField(_pollQCtrl, 'Ask your community something…', maxLines: 2),
          const SizedBox(height: 20),
          _label('Options  (min 2, max 4)'),
          const SizedBox(height: 10),
          ...List.generate(_pollOpts.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _pollOpts[i],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Option ${i + 1}',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                if (_pollOpts.length > 2) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _pollOpts.removeAt(i)),
                    child: const Icon(Icons.remove_circle_outline_rounded,
                        color: AppTheme.error, size: 20),
                  ),
                ],
              ]),
            );
          }),
          if (_pollOpts.length < 4)
            GestureDetector(
              onTap: () => setState(() => _pollOpts.add(TextEditingController())),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: AppTheme.primary),
                    SizedBox(width: 6),
                    Text('Add Option',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Score ─────────────────────────────────────────────────────────────────

  Widget _buildScore() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Exam'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _scoreExams.map((e) {
              final sel = _scoreExam == e;
              return GestureDetector(
                onTap: () => setState(() => _scoreExam = e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: sel ? AppTheme.brandGradient : null,
                    color: sel ? null : AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: sel
                        ? [BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(e,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppTheme.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _label('Your Score / Marks'),
          _inputField(_scoreMarksCtrl, 'e.g. 145/200 or 85%'),
          const SizedBox(height: 16),
          _label('Add a note (optional)'),
          _inputField(_scoreNoteCtrl,
              'Share what helped you, tips for others…', maxLines: 3),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary)),
  );

  Widget _inputField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      minLines: 1,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }

  String _kindEmoji(_PostKind k) {
    switch (k) {
      case _PostKind.text: return '💬';
      case _PostKind.mcq: return '❓';
      case _PostKind.poll: return '📊';
      case _PostKind.score: return '🏆';
    }
  }

  String _kindLabel(_PostKind k) {
    switch (k) {
      case _PostKind.text: return 'Text';
      case _PostKind.mcq: return 'MCQ';
      case _PostKind.poll: return 'Poll';
      case _PostKind.score: return 'Score';
    }
  }
}
