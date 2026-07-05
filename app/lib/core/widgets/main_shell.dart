import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  static const _destinations = [
    _Dest('/feed', Icons.home_rounded, Icons.home_outlined, 'Feed'),
    _Dest('/study', Icons.menu_book_rounded, Icons.menu_book_outlined, 'Study'),
    _Dest('/tests', Icons.assignment_rounded, Icons.assignment_outlined, 'Tests'),
    _Dest('/battle', Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Battle'),
    _Dest('/profile', Icons.person_rounded, Icons.person_outline_rounded, 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int selected = _destinations.indexWhere((d) => location.startsWith(d.route));
    if (selected < 0) selected = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_destinations.length, (i) {
                final dest = _destinations[i];
                final isActive = i == selected;
                return Expanded(
                  child: _NavItem(
                    dest: dest,
                    isActive: isActive,
                    onTap: () {
                      if (!isActive) context.go(dest.route);
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _Dest dest;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.dest,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40, height: 30,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                active ? widget.dest.icon : widget.dest.outlineIcon,
                size: 22,
                color: active ? AppTheme.primary : AppTheme.textHint,
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppTheme.primary : AppTheme.textHint,
            ),
            child: Text(widget.dest.label),
          ),
        ],
      ),
    );
  }
}

class _Dest {
  final String route;
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  const _Dest(this.route, this.icon, this.outlineIcon, this.label);
}
