import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'google_sign_in_web_helper.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class GoogleAuthService {
  static const String _androidClientId =
      '379413625356-d2elf1uui20i2eglsvcl3aqhl923pl8c.apps.googleusercontent.com';

  // Android uses google_sign_in package
  late final GoogleSignIn _googleSignIn;

  GoogleAuthService() {
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(
        clientId: _androidClientId,
        scopes: ['email', 'profile'],
      );
    }
  }

  Future<Map<String, dynamic>> authenticateWithGoogle() async {
    if (kIsWeb) {
      // Web: pure JS interop — never touches People API
      try {
        return await signInWithGoogleWeb();
      } catch (e) {
        return {
          'success': false,
          'error': e.toString().replaceAll('Exception: ', ''),
        };
      }
    } else {
      // Android: google_sign_in package
      return await _authenticateAndroid();
    }
  }

  Future<Map<String, dynamic>> _authenticateAndroid() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign in was cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {'success': false, 'error': 'Failed to obtain ID token'};
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Authentication failed',
        };
      }

      final data = jsonDecode(response.body);
      return {
        'success': true,
        'token': data['token'],
        'refreshToken': data['refreshToken'],
        'user': data['user'],
      };
    } catch (e) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      return {
        'success': false,
        'error': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<Map<String, dynamic>> exchangeOAuthCode(String code) async {
    if (kIsWeb) {
      return await exchangeOAuthCodeWeb(code);
    }
    return {'success': false, 'error': 'Not supported on this platform'};
  }

  Future<void> signOut() async {
    if (kIsWeb) {
      await signOutGoogleWeb();
    } else {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }
}
