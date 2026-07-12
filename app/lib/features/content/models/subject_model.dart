import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

const kApiUrl = 'https://kanavumeipada-production.up.railway.app/api';

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
    Uri.parse('$kApiUrl/subjects'),
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );
  if (response.statusCode != 200) throw Exception('Failed to load subjects');
  final data = jsonDecode(response.body);
  final list = data is List ? data : (data['subjects'] as List? ?? []);
  return list.map((j) => Subject.fromJson(j as Map<String, dynamic>)).toList();
});

const catColors = {
  'UPSC':    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  'TNPSC':   [Color(0xFF059669), Color(0xFF0EA5E9)],
  'SSC':     [Color(0xFFD97706), Color(0xFFF59E0B)],
  'Banking': [Color(0xFF0EA5E9), Color(0xFF6366F1)],
  'NEET':    [Color(0xFFDC2626), Color(0xFFEC4899)],
  'JEE':     [Color(0xFF7C3AED), Color(0xFFEC4899)],
};

List<Color> colorsFor(String? cat) =>
    catColors[cat] ?? [AppTheme.primary, AppTheme.secondary];

// Global study-section language toggle: false = English, true = Tamil
final studyLangProvider = StateProvider<bool>((ref) => false);
