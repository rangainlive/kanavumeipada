import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../content/models/subject_model.dart';
import '../models/pyq_models.dart';

final pyqTopicsProvider =
    FutureProvider.autoDispose.family<List<PyqTopic>, String>((ref, subjectId) async {
  final token = ref.watch(authProvider).token;
  final response = await http.get(
    Uri.parse('$kApiUrl/subjects/$subjectId/pyq/topics'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load PYQ topics');
  final data = jsonDecode(response.body);
  final list = data['topics'] as List? ?? [];
  return list.map((j) => PyqTopic.fromJson(j as Map<String, dynamic>)).toList();
});

class PyqQuestionsArgs {
  final String subjectId;
  final String? topic;
  const PyqQuestionsArgs(this.subjectId, this.topic);

  @override
  bool operator ==(Object other) =>
      other is PyqQuestionsArgs && other.subjectId == subjectId && other.topic == topic;
  @override
  int get hashCode => Object.hash(subjectId, topic);
}

final pyqQuestionsProvider =
    FutureProvider.autoDispose.family<List<PyqQuestion>, PyqQuestionsArgs>((ref, args) async {
  final token = ref.watch(authProvider).token;
  final uri = Uri.parse('$kApiUrl/subjects/${args.subjectId}/pyq/questions').replace(
    queryParameters: {
      'limit': '100',
      if (args.topic != null) 'topic': args.topic,
    },
  );
  final response = await http.get(
    uri,
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load PYQ questions');
  final data = jsonDecode(response.body);
  final list = data['questions'] as List? ?? [];
  return list.map((j) => PyqQuestion.fromJson(j as Map<String, dynamic>)).toList();
});

// Fetches the correct option id for a question — called only after the
// user has picked an answer, so the answer key isn't loaded up front.
final revealPyqAnswerProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, questionId) async {
  final token = ref.watch(authProvider).token;
  final response = await http.get(
    Uri.parse('$kApiUrl/pyq/questions/$questionId/reveal'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to reveal answer');
  final data = jsonDecode(response.body);
  return data['correctOptionId'] as String?;
});

final pyqUnmarkedProvider =
    FutureProvider.autoDispose.family<List<PyqQuestion>, String>((ref, subjectId) async {
  final token = ref.watch(authProvider).token;
  final response = await http.get(
    Uri.parse('$kApiUrl/subjects/$subjectId/pyq/unmarked?limit=20'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load unmarked PYQ questions');
  final data = jsonDecode(response.body);
  final list = data['questions'] as List? ?? [];
  return list.map((j) => PyqQuestion.fromJson(j as Map<String, dynamic>)).toList();
});

class PyqAdminNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  PyqAdminNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<String?> markAnswer(String questionId, String optionId) async {
    final token = ref.read(authProvider).token;
    try {
      final response = await http.post(
        Uri.parse('$kApiUrl/pyq/questions/$questionId/mark-answer'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'optionId': optionId}),
      );
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        return body['error'] ?? 'Failed to mark answer';
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final pyqAdminProvider =
    StateNotifierProvider<PyqAdminNotifier, AsyncValue<void>>((ref) => PyqAdminNotifier(ref));
