import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  static const _destinations = [
    _Dest('/feed', Icons.home_rounded, 'Feed'),
    _Dest('/study', Icons.menu_book_rounded, 'Study'),
    _Dest('/tests', Icons.assignment_rounded, 'Tests'),
    _Dest('/battle', Icons.emoji_events_rounded, 'Battle'),
    _Dest('/profile', Icons.person_rounded, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int selected = _destinations.indexWhere((d) => location.startsWith(d.route));
    if (selected < 0) selected = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          if (i != selected) context.go(_destinations[i].route);
        },
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Dest {
  final String route;
  final IconData icon;
  final String label;
  const _Dest(this.route, this.icon, this.label);
}
