import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../../../core/theme/app_theme.dart';

/// EN / தமிழ் language toggle. [onLight] is kept for call-site compatibility;
/// in the dark theme it selects a teal-tinted style for solid surface app bars,
/// while the default is a translucent "glass" style for gradient heroes.
class LangToggleButton extends ConsumerWidget {
  final bool onLight;
  const LangToggleButton({super.key, this.onLight = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);

    final Color fg = onLight ? AppTheme.textPrimary : Colors.white;
    final Color activeBg = onLight
        ? AppTheme.primary.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.22);
    final Color inactiveBg = onLight
        ? AppTheme.surface2
        : Colors.white.withValues(alpha: 0.12);
    final Color borderCol = isTamil
        ? AppTheme.primary.withValues(alpha: 0.6)
        : fg.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: () => ref.read(studyLangProvider.notifier).state = !isTamil,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isTamil ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderCol),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isTamil ? Icons.language : Icons.translate_rounded, color: fg, size: 14),
            const SizedBox(width: 5),
            Text(
              isTamil ? 'EN' : 'தமிழ்',
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
