import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/google_auth_service.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class User {
  final String id;
  final String email;
  final String? name;
  final String? examTarget;
  final String? userState;
  final int coinsBalance;
  final int xp;

  User({
    required this.id,
    required this.email,
    this.name,
    this.examTarget,
    this.userState,
    this.coinsBalance = 0,
    this.xp = 0,
  });

  bool get isProfileComplete =>
      name != null && name!.isNotEmpty && examTarget != null && userState != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'],
      examTarget: json['examTarget'],
      userState: json['state'],
      coinsBalance: json['coinsBalance'] ?? 0,
      xp: json['xp'] ?? 0,
    );
  }
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? token;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  late GoogleAuthService _googleAuthService;

  AuthNotifier() : super(AuthState()) {
    _googleAuthService = GoogleAuthService();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      state = state.copyWith(isLoading: true);
      try {
        final response = await http.get(
          Uri.parse('$_apiUrl/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          state = state.copyWith(
            isLoading: false,
            isAuthenticated: true,
            token: token,
            user: User.fromJson(data['user']),
          );
        } else {
          await prefs.remove('token');
          state = AuthState();
        }
      } catch (_) {
        state = AuthState();
      }
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 201) {
        throw Exception(data['error'] ?? 'Registration failed');
      }
      await _saveToken(data['token']);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: data['token'],
        user: User.fromJson(data['user']),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Login failed');
      }
      await _saveToken(data['token']);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        token: data['token'],
        user: User.fromJson(data['user']),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> updateProfile({
    required String name,
    required String examTarget,
    required String userState,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${state.token}',
        },
        body: jsonEncode({'name': name, 'examTarget': examTarget, 'state': userState}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw Exception(data['error'] ?? 'Profile update failed');
      }
      state = state.copyWith(
        isLoading: false,
        user: User.fromJson(data['user']),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _googleAuthService.authenticateWithGoogle();

    if (!result['success']) {
      state = state.copyWith(isLoading: false, error: result['error']);
      return;
    }

    await _saveToken(result['token']);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      token: result['token'],
      user: User.fromJson(result['user']),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await _googleAuthService.signOut();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
