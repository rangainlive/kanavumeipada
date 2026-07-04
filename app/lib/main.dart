import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window;
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

// Set when Google OAuth redirects back with ?code=...
String? pendingOAuthCode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Detect Google OAuth redirect: http://localhost:5000/?code=...
    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      pendingOAuthCode = code;
      // Clean the URL so back-navigation doesn't re-trigger auth
      html.window.history.replaceState(null, '', '/');
    }
  } else {
    await dotenv.load().catchError((_) {});
  }

  runApp(const ProviderScope(child: KanavuMeipada()));
}

class KanavuMeipada extends ConsumerWidget {
  const KanavuMeipada({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'KanavuMeipada',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
