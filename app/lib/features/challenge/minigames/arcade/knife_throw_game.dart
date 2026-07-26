import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Knife Throw — stick knives into the spinning target. Hit an existing knife
/// and you're out. Score = knives landed.
class KnifeThrowGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const KnifeThrowGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<KnifeThrowGame> createState() => _KnifeThrowGameState();
}

class _KnifeThrowGameState extends ConsumerState<KnifeThrowGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<double> _stuck = []; // target-relative angles (radians)
  int _count = 0;
  bool _playing = true;
  static const _minSep = 0.34; // radians (~19.5°)

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  double get _rot => _ctrl.value * 2 * pi;

  double _norm(double a) {
    a = a % (2 * pi);
    if (a < 0) a += 2 * pi;
    return a;
  }

  void _throw() {
    if (!_playing) return;
    // Knife sticks at the top (screen angle 0): target-relative angle = -rot
    final a = _norm(-_rot);
    for (final s in _stuck) {
      double d = (a - s).abs();
      d = min(d, 2 * pi - d);
      if (d < _minSep) {
        _end();
        return;
      }
    }
    setState(() {
      _stuck.add(a);
      _count++;
    });
    // speed up slightly each hit
    final ms = (2000 - _count * 60).clamp(750, 2000);
    _ctrl.duration = Duration(milliseconds: ms);
    _ctrl
      ..reset()
      ..repeat();
  }

  void _end() {
    _playing = false;
    _ctrl.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (!_playing) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '🔪',
        score: _count * 15,
        subtitle: isTamil ? '$_count கத்திகளை பதித்தீர்கள்' : 'You landed $_count knives',
        onFinish: widget.onFinish,
      );
    }
    return GestureDetector(
      onTap: _throw,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xFF2A1A12),
        child: Column(
          children: [
            GameHud(
              left: isTamil ? 'கத்திகள்: $_count' : 'Knives: $_count',
              right: isTamil ? 'தட்டவும்!' : 'Tap to throw!',
            ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    const r = 96.0;
                    return SizedBox(
                      width: 300,
                      height: 380,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // target
                          Container(
                            width: 176,
                            height: 176,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFFB45309), Color(0xFF7C3E0A)],
                              ),
                            ),
                            child: const Center(child: Text('🎯', style: TextStyle(fontSize: 40))),
                          ),
                          // stuck knives (rotate with target)
                          ..._stuck.map((a) {
                            final theta = a + _rot; // 0 = top
                            final dx = r * sin(theta);
                            final dy = -r * cos(theta);
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: Transform.rotate(
                                angle: theta,
                                child: const Text('🔪', style: TextStyle(fontSize: 30)),
                              ),
                            );
                          }),
                          // incoming knife at bottom
                          const Positioned(
                            bottom: 24,
                            child: Text('🔪', style: TextStyle(fontSize: 40)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
