import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/google_auth_service.dart';
import '../../../main.dart' show pendingOAuthCode;

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class User {
  final String id;
  final String? phone;
  final String? email;
  final String? name;
  final String? examTarget;
  final String? userState;
  final int coinsBalance;
  final int xp;

  User({
    required this.id,
    this.phone,
    this.email,
    this.name,
    this.examTarget,
    this.userState,
    this.coinsBalance = 0,
    this.xp = 0,
  });

  bool get isProfileComplete =>
      name != null && name!.isNotEmpty && examTarget != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      examTarget: json['examTarget'] as String?,
      userState: json['state'] as String?,
      coinsBalance: (json['coinsBalance'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
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
    if (pendingOAuthCode != null) {
      final code = pendingOAuthCode!;
      pendingOAuthCode = null;
      _exchangeOAuthCode(code);
    } else {
      _loadToken();
    }
  }

  Future<void> _exchangeOAuthCode(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _googleAuthService.exchangeOAuthCode(code);
    if (!result['success']) {
      state = state.copyWith(isLoading: false, error: result['error'] as String?);
      return;
    }
    await _saveToken(result['token'] as String);
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      token: result['token'] as String,
      user: User.fromJson(result['user'] as Map<String, dynamic>),
    );
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

  Future<void> register(String phone, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password, 'name': name}),
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

  Future<void> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
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
        body: jsonEncode({'name': name, 'examTarget': examTarget, 'state': 'Tamil Nadu'}),
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
