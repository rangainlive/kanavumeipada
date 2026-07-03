import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/feed/screens/feed_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/phone',
    routes: [
      GoRoute(
        path: '/auth',
        redirect: (context, state) => '/auth/phone',
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final phone = state.extra as String?;
          if (phone == null) {
            return const Scaffold(
              body: Center(child: Text('Error: Phone number not provided')),
            );
          }
          return OTPScreen(phone: phone);
        },
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
