import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Road Safety Dodge — tap to step up across the traffic lanes. Reach the top
/// safely to score a crossing; get hit and it's over.
class RoadSafetyDodgeGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const RoadSafetyDodgeGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<RoadSafetyDodgeGame> createState() => _RoadSafetyDodgeGameState();
}

class _Lane {
  final double speed; // fraction/tick, signed
  final String car;
  double phase;
  _Lane(this.speed, this.car, this.phase);
}

class _RoadSafetyDodgeGameState extends ConsumerState<RoadSafetyDodgeGame> {
  static const _rows = 6; // row 0 = start (bottom), row _rows-1 = goal (top)
  final _rng = Random();
  late final List<_Lane?> _lanes; // index by row; null = safe (start/goal)
  Timer? _loop;
  int _playerRow = 0;
  int _crossings = 0;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _lanes = List.generate(_rows, (r) {
      if (r == 0 || r == _rows - 1) return null; // safe rows
      final dir = _rng.nextBool() ? 1.0 : -1.0;
      final sp = (0.006 + _rng.nextDouble() * 0.006) * dir;
      const cars = ['🚗', '🚕', '🚙', '🚌', '🏍️'];
      return _Lane(sp, cars[_rng.nextInt(cars.length)], _rng.nextDouble());
    });
    _loop = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_playing) return;
    for (final l in _lanes) {
      if (l == null) continue;
      l.phase = (l.phase + l.speed) % 1.0;
      if (l.phase < 0) l.phase += 1.0;
    }
    // collision: two cars per lane at phase and phase+0.5
    final lane = _lanes[_playerRow];
    if (lane != null) {
      for (final off in [0.0, 0.5]) {
        final cx = (lane.phase + off) % 1.0;
        if ((cx - 0.5).abs() < 0.09) {
          _end(false);
          return;
        }
      }
    }
    setState(() {});
  }

  void _step() {
    if (!_playing) return;
    setState(() => _playerRow++);
    if (_playerRow >= _rows - 1) {
      _crossings++;
      _playerRow = 0;
    }
  }

  void _end(bool safe) {
    _playing = false;
    _loop?.cancel();
    setState(() {});
  }

  @override
  void dispose() {
    _loop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (!_playing) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '🚸',
        score: _crossings * 25,
        subtitle: isTamil ? '$_crossings முறை பாதுகாப்பாக கடந்தீர்கள்' : '$_crossings safe crossings',
        onFinish: widget.onFinish,
      );
    }
    return GestureDetector(
      onTap: _step,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          GameHud(
            left: isTamil ? 'கடந்தது: $_crossings' : 'Crossings: $_crossings',
            right: isTamil ? 'மேலே செல்ல தட்டு' : 'Tap to step up',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final rowH = c.maxHeight / _rows;
                return Stack(
                  children: [
                    // rows
                    for (int r = 0; r < _rows; r++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (_rows - 1 - r) * rowH,
                        height: rowH,
                        child: Container(
                          color: _lanes[r] == null
                              ? const Color(0xFF14532D)
                              : (r.isEven ? const Color(0xFF3F3F46) : const Color(0xFF52525B)),
                        ),
                      ),
                    // cars
                    for (int r = 0; r < _rows; r++)
                      if (_lanes[r] != null)
                        for (final off in [0.0, 0.5])
                          Positioned(
                            left: (((_lanes[r]!.phase + off) % 1.0) * (c.maxWidth - 40)),
                            top: (_rows - 1 - r) * rowH + rowH / 2 - 18,
                            child: Text(_lanes[r]!.car, style: const TextStyle(fontSize: 34)),
                          ),
                    // player
                    Positioned(
                      left: c.maxWidth / 2 - 18,
                      top: (_rows - 1 - _playerRow) * rowH + rowH / 2 - 18,
                      child: const Text('🚶', style: TextStyle(fontSize: 34)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
