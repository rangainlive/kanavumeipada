import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Frog Leap — tap when the marker is inside the lily pad zone to leap across.
/// Each leap gets faster and the zone shrinks. Miss and you splash.
class FrogLeapGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const FrogLeapGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<FrogLeapGame> createState() => _FrogLeapGameState();
}

class _FrogLeapGameState extends ConsumerState<FrogLeapGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _leaps = 0;
  double _half = 0.16; // half-width of the safe zone
  bool _playing = true;
  bool _splash = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    // Safety net: without input the marker just oscillates forever.
    _idleTimer = Timer(const Duration(seconds: 50), () {
      if (_playing) {
        setState(() {
          _splash = true;
          _playing = false;
        });
        _ctrl.stop();
      }
    });
  }

  void _tap() {
    if (!_playing) return;
    final pos = _ctrl.value;
    if ((pos - 0.5).abs() <= _half) {
      setState(() {
        _leaps++;
        _half = (_half - 0.012).clamp(0.055, 0.16);
      });
      final ms = (1400 - _leaps * 55).clamp(520, 1400);
      _ctrl.duration = Duration(milliseconds: ms);
      _ctrl
        ..reset()
        ..repeat(reverse: true);
    } else {
      setState(() {
        _splash = true;
        _playing = false;
      });
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (!_playing) {
      return GameResultView(
        isTamil: isTamil,
        emoji: _splash ? '💦' : '🐸',
        score: _leaps * 20,
        subtitle: isTamil ? '$_leaps தாவல்கள்' : '$_leaps leaps across',
        onFinish: widget.onFinish,
      );
    }
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0xFF06402B),
        child: Column(
          children: [
            GameHud(
              left: isTamil ? 'தாவல்: $_leaps' : 'Leaps: $_leaps',
              right: isTamil ? 'சரியான நேரத்தில் தட்டு' : 'Tap in the zone',
            ),
            const Spacer(),
            const Text('🐸', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  return SizedBox(
                    height: 46,
                    child: AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // track
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            // safe zone (lily pad)
                            Positioned(
                              left: (0.5 - _half) * w,
                              width: (2 * _half) * w,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                    child: Text('🪷', style: TextStyle(fontSize: 14))),
                              ),
                            ),
                            // marker
                            Positioned(
                              left: (_ctrl.value * w).clamp(0.0, w - 6),
                              child: Container(width: 6, height: 40, color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
