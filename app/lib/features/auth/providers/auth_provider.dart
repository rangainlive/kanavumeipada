import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class User {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? examTarget;
  final String? state;
  final String language;
  final int coinsBalance;
  final int xp;

  User({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.examTarget,
    this.state,
    this.language = 'en',
    this.coinsBalance = 0,
    this.xp = 0,
  });

  bool get isProfileComplete =>
      name != null && name!.isNotEmpty && examTarget != null && state != null;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      name: json['name'],
      email: json['email'],
      examTarget: json['examTarget'],
      state: json['state'],
      language: json['language'] ?? 'en',
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
  final String? refreshToken;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.token,
    this.refreshToken,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? token,
    String? refreshToken,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final String apiUrl = 'http://localhost:3000/api';

  AuthNotifier() : super(AuthState());

  Future<void> requestOTP(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to request OTP');
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOTP(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Verification failed');
      }

      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        token: data['token'],
        refreshToken: data['refreshToken'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile({
    required String name,
    required String examTarget,
    required String state,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${this.state.token}',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'examTarget': examTarget,
          'state': state,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile');
      }

      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user']);

      state = state.copyWith(
        isLoading: false,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void logout() {
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
