import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/feed/screens/feed_screen.dart';

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
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/content/:id',
        builder: (context, state) => PlaceholderScreen(
          title: 'Content Details',
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/test/:id',
        builder: (context, state) => PlaceholderScreen(
          title: 'Test',
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/challenge/:id',
        builder: (context, state) => PlaceholderScreen(
          title: 'Challenge',
          id: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Profile',
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String id;

  const PlaceholderScreen({
    Key? key,
    required this.title,
    this.id = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title ${id.isNotEmpty ? '- $id' : ''}'),
      ),
    );
  }
}
