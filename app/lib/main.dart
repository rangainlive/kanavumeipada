import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_widgets.dart';
import 'core/router/app_router.dart';
import 'features/auth/services/google_sign_in_web_helper.dart';

String? pendingOAuthCode;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    if (checkAndHandleIfPopup()) return;
    pendingOAuthCode = getPendingOAuthCode();
  } else {
    await dotenv.load().catchError((_) {});
  }

  runApp(const ProviderScope(child: KanavuMeipada()));
}

class KanavuMeipada extends ConsumerWidget {
  const KanavuMeipada({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'KanavuMeipada',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      // Global aurora backdrop behind every screen (scaffolds are transparent).
      builder: (context, child) =>
          AuroraBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
