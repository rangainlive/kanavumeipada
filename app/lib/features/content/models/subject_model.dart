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

// Dark-mode tuned category gradients. TNPSC uses the brand teal; the other
// exams (currently "coming soon") use muted, desaturated dark gradients.
const catColors = {
  'TNPSC':   [Color(0xFF0D9488), Color(0xFF14B8A6)],
  'UPSC':    [Color(0xFF3B3172), Color(0xFF5B4B9E)],
  'SSC':     [Color(0xFF7A5320), Color(0xFF9C6F2A)],
  'Banking': [Color(0xFF23507A), Color(0xFF356A99)],
  'NEET':    [Color(0xFF7A2E3E), Color(0xFF9C4457)],
  'JEE':     [Color(0xFF5B3172), Color(0xFF7A459E)],
};

List<Color> colorsFor(String? cat) =>
    catColors[cat] ?? [AppTheme.primaryDim, AppTheme.primary];

// Global study-section language toggle: false = English, true = Tamil
final studyLangProvider = StateProvider<bool>((ref) => false);
