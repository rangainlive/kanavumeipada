import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ambient "aurora" background: a near-black canvas lit by large, soft glowing
/// color orbs (teal + emerald + gold). Wrap a screen's body in this and keep
/// the Scaffold background transparent for the premium Aurora-Glass look.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool dense; // dense = a bit more glow (for hero/login screens)
  const AuroraBackground({super.key, required this.child, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final k = dense ? 1.0 : 0.72;
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: AppTheme.bg)),
        _orb(top: -140, left: -110, size: 420, color: AppTheme.primary, opacity: 0.34 * k),
        _orb(top: -80, right: -120, size: 360, color: AppTheme.primaryGlow, opacity: 0.22 * k),
        _orb(top: 180, right: -160, size: 300, color: AppTheme.gold, opacity: 0.12 * k),
        _orb(bottom: -120, left: -130, size: 420, color: AppTheme.primaryDim, opacity: 0.24 * k),
        _orb(bottom: 40, right: -80, size: 300, color: AppTheme.gold, opacity: 0.10 * k),
        // Subtle darkening vignette so content stays readable over the glow.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [Colors.transparent, Color(0x66040807)],
                stops: [0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _orb({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted glassmorphic panel: blurs whatever is behind it, with a translucent
/// gradient fill, a light top-edge border and a soft drop shadow. The core of
/// the Aurora-Glass card language.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final bool strong;
  final VoidCallback? onTap;
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 18,
    this.strong = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: strong ? 0.14 : 0.10),
                  Colors.white.withValues(alpha: strong ? 0.06 : 0.035),
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
    if (onTap == null) return panel;
    return GestureDetector(onTap: onTap, child: panel);
  }
}

/// Standard dark surface card. Optional [glow] adds a teal halo (for hero/primary
/// cards), [onTap] makes it a pressable surface with a subtle press-scale.
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool glow;
  final Color? glowColor;
  final Color? borderColor;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.glow = false,
    this.glowColor,
    this.borderColor,
    this.radius = 16,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 110),
      child: Container(
        padding: widget.padding,
        margin: widget.margin,
        decoration: BoxDecoration(
          // Slightly translucent so the aurora glow subtly shows through,
          // tying every card into the Aurora-Glass background.
          color: AppTheme.surface.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: widget.borderColor ?? AppTheme.glassBorder),
          boxShadow: widget.glow ? AppTheme.glow(widget.glowColor) : AppTheme.cardShadow,
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap == null) return card;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: card,
    );
  }
}

/// Translucent "glass" card for placing on top of gradient heroes.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: child,
    );
  }
}

/// Reusable gradient hero header. Use inside a [SliverToBoxAdapter] or directly
/// at the top of a Column. Provide [title], optional [subtitle], [emoji], a
/// [trailing] action (e.g. language toggle), and optional [child] rendered below
/// the title (e.g. a glass stat card).
class GradientHero extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final Widget? trailing;
  final Widget? child;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;
  final bool roundedBottom;

  const GradientHero({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.trailing,
    this.child,
    this.gradient = AppTheme.brandGradientDeep,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 24),
    this.roundedBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: roundedBottom
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emoji != null ? '$title $emoji' : title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 12), trailing!],
                ],
              ),
              if (child != null) ...[const SizedBox(height: 20), child!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent section heading used above lists/grids.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A compact stat tile (coins / XP / streak / score). Gold-accented by default.
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? color;
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.gold;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
      ],
    );
  }
}

/// Small pill badge (e.g. "Soon", counts, tags).
class PillBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color? bg;
  const PillBadge(this.text, {super.key, this.color = AppTheme.gold, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
