import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';

const _kApiUrl = 'https://kanavumeipada-production.up.railway.app/api';

enum ReviewStatus { pending, approved, rejected }

class QuestionOption {
  final String id;
  final String text;
  final bool isCorrect;

  const QuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> j) => QuestionOption(
        id: j['id'] as String,
        text: j['text'] as String,
        isCorrect: j['isCorrect'] as bool? ?? false,
      );
}

class AiQuestion {
  final String id;
  final String text;
  final List<QuestionOption> options;
  final int correctIndex;
  final String explanation;
  final int difficulty;
  final String bloomLevel;
  final ReviewStatus review;

  const AiQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.difficulty,
    required this.bloomLevel,
    this.review = ReviewStatus.pending,
  });

  AiQuestion copyWith({ReviewStatus? review}) => AiQuestion(
        id: id,
        text: text,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
        difficulty: difficulty,
        bloomLevel: bloomLevel,
        review: review ?? this.review,
      );

  factory AiQuestion.fromJson(Map<String, dynamic> j) {
    final opts = (j['options'] as List)
        .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
        .toList();
    final ci = j['correctIndex'];
    final corrIdx = (ci is int ? ci : opts.indexWhere((o) => o.isCorrect))
        .clamp(0, opts.isEmpty ? 0 : opts.length - 1);
    return AiQuestion(
      id: j['id'] as String,
      text: j['text'] as String,
      options: opts,
      correctIndex: corrIdx,
      explanation: j['explanation'] as String? ?? '',
      difficulty: j['difficulty'] as int? ?? 1,
      bloomLevel: j['bloomLevel'] as String? ?? 'remember',
    );
  }
}

class GenerationState {
  final bool isLoading;
  final String? error;
  final List<AiQuestion> questions;
  final bool hasResults;

  const GenerationState({
    this.isLoading = false,
    this.error,
    this.questions = const [],
    this.hasResults = false,
  });

  int get approvedCount =>
      questions.where((q) => q.review == ReviewStatus.approved).length;
  int get pendingCount =>
      questions.where((q) => q.review == ReviewStatus.pending).length;
}

class GenerationNotifier extends StateNotifier<GenerationState> {
  final String? _token;
  final String _chapterId;

  GenerationNotifier(this._token, this._chapterId)
      : super(const GenerationState());

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> generate({
    required int count,
    required int difficulty,
    required String bloomLevel,
    required bool isTamil,
  }) async {
    state = const GenerationState(isLoading: true);
    try {
      final r = await http.post(
        Uri.parse('$_kApiUrl/chapters/$_chapterId/generate-questions'),
        headers: _headers,
        body: jsonEncode({
          'count': count,
          'difficulty': difficulty,
          'bloomLevel': bloomLevel,
          'language': isTamil ? 'tamil' : 'english',
        }),
      );
      if (!mounted) return;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (r.statusCode == 200) {
        final questions = (data['questions'] as List)
            .map((q) => AiQuestion.fromJson(q as Map<String, dynamic>))
            .toList();
        state = GenerationState(questions: questions, hasResults: true);
      } else {
        state = GenerationState(
            error: data['error'] as String? ?? 'Generation failed');
      }
    } catch (e) {
      if (!mounted) return;
      state = GenerationState(error: e.toString());
    }
  }

  Future<void> approve(String questionId) async {
    _setReview(questionId, ReviewStatus.approved);
    try {
      final r = await http.post(
        Uri.parse('$_kApiUrl/questions/$questionId/approve'),
        headers: _headers,
      );
      if (!mounted) return;
      if (r.statusCode != 200) _setReview(questionId, ReviewStatus.pending);
    } catch (_) {
      if (!mounted) return;
      _setReview(questionId, ReviewStatus.pending);
    }
  }

  Future<void> reject(String questionId) async {
    _setReview(questionId, ReviewStatus.rejected);
    try {
      final r = await http.delete(
        Uri.parse('$_kApiUrl/questions/$questionId'),
        headers: _headers,
      );
      if (!mounted) return;
      if (r.statusCode != 200) _setReview(questionId, ReviewStatus.pending);
    } catch (_) {
      if (!mounted) return;
      _setReview(questionId, ReviewStatus.pending);
    }
  }

  Future<void> approveAll() async {
    final ids = state.questions
        .where((q) => q.review == ReviewStatus.pending)
        .map((q) => q.id)
        .toList();
    for (final id in ids) {
      await approve(id);
    }
  }

  Future<String?> uploadContent(String contentText) async {
    try {
      final r = await http.post(
        Uri.parse('$_kApiUrl/chapters/$_chapterId/content'),
        headers: _headers,
        body: jsonEncode({'contentText': contentText}),
      );
      if (!mounted) return null;
      if (r.statusCode == 200) return null;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return data['error'] as String? ?? 'Upload failed';
    } catch (e) {
      return e.toString();
    }
  }

  void _setReview(String questionId, ReviewStatus review) {
    if (!mounted) return;
    state = GenerationState(
      isLoading: state.isLoading,
      error: state.error,
      hasResults: state.hasResults,
      questions: state.questions
          .map((q) => q.id == questionId ? q.copyWith(review: review) : q)
          .toList(),
    );
  }
}

final generationProvider = StateNotifierProvider.autoDispose
    .family<GenerationNotifier, GenerationState, String>(
  (ref, chapterId) =>
      GenerationNotifier(ref.watch(authProvider).token, chapterId),
);
