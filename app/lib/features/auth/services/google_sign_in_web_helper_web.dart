// Web-only: Google OAuth popup flow. Popup redirects back to this origin,
// detects window.opener, postMessages the code, and closes itself.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _webClientId =
    '379413625356-vaq7s6p1k5q6fbld5haahero5gekb8g3.apps.googleusercontent.com';
const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

Future<Map<String, dynamic>> signInWithGoogleWeb() async {
  final origin = html.window.location.origin;

  final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'response_type': 'code',
    'client_id': _webClientId,
    'redirect_uri': origin,
    'scope': 'openid email profile',
    'access_type': 'online',
    'prompt': 'select_account',
  });

  // Open a small popup — main window stays alive
  final popup = html.window.open(
    authUrl.toString(),
    'google_oauth',
    'width=520,height=650,scrollbars=yes,resizable=yes',
  );

  if (popup == null) {
    return {
      'success': false,
      'error': 'Popup was blocked. Allow popups for localhost:5000 and try again.',
    };
  }

  final completer = Completer<String>();

  late html.EventListener onMessage;
  onMessage = (html.Event e) {
    final msg = e as html.MessageEvent;
    if (msg.origin != origin) return;
    final data = msg.data?.toString() ?? '';
    if (data.startsWith('oauth_code:')) {
      html.window.removeEventListener('message', onMessage);
      final code = data.substring('oauth_code:'.length);
      if (!completer.isCompleted) completer.complete(code);
    } else if (data == 'oauth_cancelled') {
      html.window.removeEventListener('message', onMessage);
      if (!completer.isCompleted) {
        completer.completeError(Exception('Sign in was cancelled'));
      }
    }
  };

  html.window.addEventListener('message', onMessage);

  try {
    final code = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw Exception('Sign in timed out'),
    );
    return await exchangeOAuthCodeWeb(code);
  } catch (e) {
    html.window.removeEventListener('message', onMessage);
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}

// Called when this page is loaded inside the popup (window.opener != null).
// Sends the auth code back to the opener then closes the popup.
void handlePopupCallback(String code) {
  final opener = html.window.opener;
  if (opener != null) {
    opener.postMessage('oauth_code:$code', html.window.location.origin);
  }
  html.window.close();
}

// Returns true if running inside the OAuth popup — also handles the callback and closes window.
bool checkAndHandleIfPopup() {
  final uri = Uri.parse(html.window.location.href);
  final code = uri.queryParameters['code'];
  if (code != null && code.isNotEmpty && html.window.opener != null) {
    handlePopupCallback(code);
    return true;
  }
  return false;
}

// Returns the OAuth code when Google redirected to the main window (popup blocked fallback).
String? getPendingOAuthCode() {
  final uri = Uri.parse(html.window.location.href);
  final code = uri.queryParameters['code'];
  if (code == null || code.isEmpty || html.window.opener != null) return null;
  html.window.history.replaceState(null, '', '/');
  return code;
}

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
      return {'success': false, 'error': data['error'] ?? 'Authentication failed'};
    }

    final data = jsonDecode(response.body);
    return {
      'success': true,
      'token': data['token'],
      'refreshToken': data['refreshToken'],
      'user': data['user'],
    };
  } catch (e) {
    return {'success': false, 'error': e.toString().replaceAll('Exception: ', '')};
  }
}

Future<void> signOutGoogleWeb() async {}
