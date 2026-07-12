import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/create_post_screen.dart';
import '../../features/feed/screens/post_detail_screen.dart';
import '../../features/feed/providers/feed_provider.dart';
import '../../features/content/models/subject_model.dart';
import '../../features/content/screens/study_screen.dart';
import '../../features/content/screens/category_screen.dart';
import '../../features/content/screens/subject_hub_screen.dart';
import '../../features/content/screens/subject_chapters_screen.dart';
import '../../features/content/screens/syllabus_screen.dart';
import '../../features/test_engine/screens/tests_screen.dart';
import '../../features/challenge/screens/battle_screen.dart';
import '../../features/ai_generator/screens/generate_screen.dart';
import '../widgets/main_shell.dart';

// ChangeNotifier that fires whenever auth state changes, used as GoRouter refreshListenable
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    // Still loading — don't redirect yet
    if (auth.isLoading) return null;

    final isAuth = auth.isAuthenticated;
    final isProfileComplete = auth.user?.isProfileComplete ?? false;
    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/auth');

    if (!isAuth && !isAuthRoute) return '/auth/login';
    if (isAuth && !isProfileComplete && loc != '/auth/profile') {
      return '/auth/profile';
    }
    if (isAuth && isProfileComplete && isAuthRoute) return '/feed';
    return null;
  }
}

final _routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

final goRouterProvider = Provider<GoRouter>((ref) {
  // Use ref.read so the GoRouter instance is created only once.
  // The refreshListenable handles re-evaluation of redirect on auth changes.
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/feed/post/:id',
        builder: (context, state) {
          final post = state.extra as FeedPost?;
          if (post == null) return const Scaffold(body: Center(child: Text('Post not found')));
          return PostDetailScreen(post: post);
        },
      ),
      GoRoute(
        path: '/auth/profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/feed/create',
            builder: (context, state) => const CreatePostScreen(),
          ),
          GoRoute(
            path: '/study',
            builder: (context, state) => const StudyScreen(),
          ),
          GoRoute(
            path: '/study/category/:category',
            builder: (context, state) => CategoryScreen(
              category: state.pathParameters['category']!,
            ),
          ),
          GoRoute(
            path: '/study/subject/:id/hub',
            builder: (context, state) => SubjectHubScreen(
              subjectId: state.pathParameters['id']!,
              subject: state.extra as Subject?,
            ),
          ),
          GoRoute(
            path: '/study/subject/:id',
            builder: (context, state) => SubjectChaptersScreen(
              subjectId: state.pathParameters['id']!,
              subjectName: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/study/chapter/:id/generate',
            builder: (context, state) => GenerateScreen(
              chapterId: state.pathParameters['id']!,
              chapterTitle: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/study/syllabus',
            builder: (context, state) => const SyllabusScreen(),
          ),
          GoRoute(
            path: '/tests',
            builder: (context, state) => const TestsScreen(),
          ),
          GoRoute(
            path: '/battle',
            builder: (context, state) => const BattleScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});
