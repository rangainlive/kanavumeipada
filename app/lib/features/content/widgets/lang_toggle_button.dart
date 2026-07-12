import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';

/// Language toggle button. Use [onLight] = true when placed inside a white /
/// light AppBar. Default (false) is white text for dark/gradient backgrounds.
class LangToggleButton extends ConsumerWidget {
  final bool onLight;
  const LangToggleButton({super.key, this.onLight = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTamil = ref.watch(studyLangProvider);

    final fg = onLight ? const Color(0xFF374151) : Colors.white;
    final activeBg = onLight
        ? const Color(0xFF059669).withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.3);
    final inactiveBg = onLight ? Colors.transparent : Colors.white.withValues(alpha: 0.15);

    return GestureDetector(
      onTap: () => ref.read(studyLangProvider.notifier).state = !isTamil,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isTamil ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
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
