import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/create_post_screen.dart';
import '../../features/content/screens/study_screen.dart';
import '../../features/content/screens/subject_chapters_screen.dart';
import '../../features/test_engine/screens/tests_screen.dart';
import '../../features/challenge/screens/battle_screen.dart';
import '../widgets/main_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated
        ? (authState.user?.isProfileComplete == true ? '/feed' : '/auth/profile')
        : '/auth/login',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isProfileComplete = authState.user?.isProfileComplete ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && !isProfileComplete && state.matchedLocation != '/auth/profile') {
        return '/auth/profile';
      }
      if (isAuth && isProfileComplete && isAuthRoute) return '/feed';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
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
            path: '/study/subject/:id',
            builder: (context, state) => SubjectChaptersScreen(
              subjectId: state.pathParameters['id']!,
              subjectName: state.extra as String?,
            ),
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
