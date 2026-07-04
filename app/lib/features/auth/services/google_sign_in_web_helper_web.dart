// Web-only: Google OAuth redirect flow (no popup, no COOP issues).
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _webClientId =
    '379413625356-vaq7s6p1k5q6fbld5haahero5gekb8g3.apps.googleusercontent.com';
const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

// Redirect user to Google OAuth (full page redirect, no popup).
// The page will navigate away; the app restarts when Google redirects back.
Future<Map<String, dynamic>> signInWithGoogleWeb() async {
  final redirectUri = html.window.location.origin;

  final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'response_type': 'code',
    'client_id': _webClientId,
    'redirect_uri': redirectUri,
    'scope': 'openid email profile',
    'access_type': 'online',
    'prompt': 'select_account',
  });

  html.window.location.href = authUrl.toString();

  // Page is navigating away — this future never resolves normally.
  await Future.delayed(const Duration(seconds: 60));
  return {'success': false, 'error': 'Redirect did not complete'};
}

// Exchange the authorization code returned by Google for a session token.
Future<Map<String, dynamic>> exchangeOAuthCodeWeb(String code) async {
  final redirectUri = html.window.location.origin;

  try {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/google/code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code, 'redirectUri': redirectUri}),
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
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}

Future<void> signOutGoogleWeb() async {}
