// Web-only: uses GIS google.accounts.id (id_token) flow via CustomEvent.
// No google_sign_in Flutter package, no People API.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _webClientId =
    '379413625356-vaq7s6p1k5q6fbld5haahero5gekb8g3.apps.googleusercontent.com';
const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

const _credentialEvent = '_flutter_gsi_credential';
const _cancelEvent = '_flutter_gsi_cancelled';

Future<Map<String, dynamic>> signInWithGoogleWeb() async {
  final completer = Completer<String>();

  late html.EventListener onCredential;
  late html.EventListener onCancel;

  onCredential = (html.Event e) {
    html.window.removeEventListener(_credentialEvent, onCredential);
    html.window.removeEventListener(_cancelEvent, onCancel);
    final credential = (e as html.CustomEvent).detail as String;
    if (!completer.isCompleted) completer.complete(credential);
  };

  onCancel = (html.Event _) {
    html.window.removeEventListener(_credentialEvent, onCredential);
    html.window.removeEventListener(_cancelEvent, onCancel);
    if (!completer.isCompleted) {
      completer.completeError(Exception('Google sign in was cancelled'));
    }
  };

  html.window.addEventListener(_credentialEvent, onCredential);
  html.window.addEventListener(_cancelEvent, onCancel);

  js.context.callMethod('eval', ['''
    (function() {
      function handleCredential(response) {
        window.dispatchEvent(
          new CustomEvent("$_credentialEvent", { detail: response.credential })
        );
      }

      function showButtonOverlay() {
        var existing = document.getElementById("_flutter_gsi_overlay");
        if (existing) existing.remove();

        var overlay = document.createElement("div");
        overlay.id = "_flutter_gsi_overlay";
        overlay.style.cssText = "position:fixed;inset:0;background:rgba(0,0,0,0.6);display:flex;align-items:center;justify-content:center;z-index:999999;";

        var card = document.createElement("div");
        card.style.cssText = "background:white;border-radius:16px;padding:40px 32px;text-align:center;min-width:320px;box-shadow:0 8px 32px rgba(0,0,0,0.25);";

        var title = document.createElement("div");
        title.textContent = "Sign in to KanavuMeipada";
        title.style.cssText = "font-size:20px;font-weight:600;margin-bottom:8px;color:#1a1a1a;font-family:sans-serif;";

        var sub = document.createElement("div");
        sub.textContent = "Choose your Google account to continue";
        sub.style.cssText = "font-size:14px;color:#666;margin-bottom:24px;font-family:sans-serif;";

        var btnDiv = document.createElement("div");
        btnDiv.id = "_flutter_gsi_btn";
        btnDiv.style.cssText = "display:flex;justify-content:center;";

        var cancelBtn = document.createElement("button");
        cancelBtn.textContent = "Cancel";
        cancelBtn.style.cssText = "margin-top:16px;background:none;border:none;color:#666;cursor:pointer;font-size:14px;font-family:sans-serif;text-decoration:underline;";
        cancelBtn.onclick = function() {
          overlay.remove();
          window.dispatchEvent(new CustomEvent("$_cancelEvent"));
        };

        card.appendChild(title);
        card.appendChild(sub);
        card.appendChild(btnDiv);
        card.appendChild(cancelBtn);
        overlay.appendChild(card);
        document.body.appendChild(overlay);

        google.accounts.id.renderButton(btnDiv, {
          type: "standard", theme: "outline",
          size: "large", text: "sign_in_with",
          shape: "rectangular", width: 250
        });
      }

      google.accounts.id.initialize({
        client_id: "$_webClientId",
        callback: handleCredential,
        auto_select: false,
        cancel_on_tap_outside: false,
        use_fedcm_for_prompt: false,
        itp_support: true
      });

      // Skip One Tap (FedCM causes issues) — go straight to button overlay
      showButtonOverlay();
    })();
  ''']);

  try {
    final credential = await completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw Exception('Sign in timed out'),
    );
    _removeOverlay();
    return await _sendToBackend(credential);
  } catch (e) {
    _removeOverlay();
    return {
      'success': false,
      'error': e.toString().replaceAll('Exception: ', ''),
    };
  }
}

Future<void> signOutGoogleWeb() async {
  try {
    js.context.callMethod('eval', [
      'if (typeof google !== "undefined" && google.accounts) { google.accounts.id.disableAutoSelect(); }'
    ]);
  } catch (_) {}
}

void _removeOverlay() {
  try {
    final el = html.document.getElementById('_flutter_gsi_overlay');
    el?.remove();
  } catch (_) {}
}

Future<Map<String, dynamic>> _sendToBackend(String idToken) async {
  final response = await http.post(
    Uri.parse('$_apiUrl/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'token': idToken}),
  ).timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    final data = jsonDecode(response.body);
    throw Exception(data['error'] ?? 'Authentication failed');
  }

  final data = jsonDecode(response.body);
  return {
    'success': true,
    'token': data['token'],
    'refreshToken': data['refreshToken'],
    'user': data['user'],
  };
}
