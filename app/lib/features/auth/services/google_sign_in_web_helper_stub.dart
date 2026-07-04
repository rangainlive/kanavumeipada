Future<Map<String, dynamic>> signInWithGoogleWeb() async {
  throw UnsupportedError('Web sign-in not supported on this platform');
}

void handlePopupCallback(String code) {}

bool checkAndHandleIfPopup() => false;

String? getPendingOAuthCode() => null;

Future<Map<String, dynamic>> exchangeOAuthCodeWeb(String code) async {
  throw UnsupportedError('OAuth code exchange not supported on this platform');
}

Future<void> signOutGoogleWeb() async {}
