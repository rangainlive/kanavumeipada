import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Autobahn — tap left / right to switch lanes and dodge oncoming cars.
/// Score = cars dodged.
class AutobahnGame extends ConsumerStatefulWidget {
  final String challengeId;
  final Map<String, dynamic>? config;
  final ValueChanged<MiniGameResult> onFinish;
  const AutobahnGame({super.key, required this.challengeId, this.config, required this.onFinish});

  @override
  ConsumerState<AutobahnGame> createState() => _AutobahnGameState();
}

class _Ob {
  final int lane;
  double y;
  bool passed = false;
  _Ob(this.lane, this.y);
}

class _AutobahnGameState extends ConsumerState<AutobahnGame> {
  static const _lanes = 3;
  static const _playerY = 0.82;
  final _rng = Random();
  final List<_Ob> _obs = [];
  Timer? _loop;
  int _player = 1;
  int _dodged = 0;
  double _speed = 0.018;
  double _spawnAcc = 0;
  bool _playing = true;
  final _cars = ['🚙', '🚚', '🚕', '🚌'];
  final _carFor = <_Ob, String>{};

  @override
  void initState() {
    super.initState();
    _loop = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_playing) return;
    _spawnAcc += 1;
    if (_spawnAcc >= 22) {
      _spawnAcc = 0;
      final ob = _Ob(_rng.nextInt(_lanes), -0.12);
      _carFor[ob] = _cars[_rng.nextInt(_cars.length)];
      _obs.add(ob);
    }
    for (final o in _obs) {
      o.y += _speed;
      if (!o.passed && o.y > _playerY + 0.06) {
        o.passed = true;
        _dodged++;
        _speed = (_speed + 0.0006).clamp(0.018, 0.055);
      }
      if (o.lane == _player && (o.y - _playerY).abs() < 0.07) {
        _end();
        return;
      }
    }
    _obs.removeWhere((o) => o.y > 1.2);
    setState(() {});
  }

  void _move(bool left) {
    if (!_playing) return;
    setState(() => _player = (_player + (left ? -1 : 1)).clamp(0, _lanes - 1));
  }

  void _end() {
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
        emoji: '🏁',
        score: _dodged * 10,
        subtitle: isTamil ? '$_dodged கார்களைத் தவிர்த்தீர்கள்' : 'You dodged $_dodged cars',
        onFinish: widget.onFinish,
      );
    }
    return Column(
      children: [
        GameHud(
          left: isTamil ? 'தவிர்த்தது: $_dodged' : 'Dodged: $_dodged',
          right: isTamil ? '⬅️ தட்டு ➡️' : 'Tap ⬅️ / ➡️',
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) {
              final w = MediaQuery.of(context).size.width;
              _move(d.globalPosition.dx < w / 2);
            },
            child: LayoutBuilder(
              builder: (context, c) {
                final laneW = c.maxWidth / _lanes;
                Widget carAt(int lane, double y, String e, {bool player = false}) {
                  return Positioned(
                    left: lane * laneW + laneW / 2 - 22,
                    top: y * c.maxHeight - 22,
                    child: Text(e, style: const TextStyle(fontSize: 40)),
                  );
                }

                return Container(
                  color: const Color(0xFF334155),
                  child: Stack(
                    children: [
                      // lane dividers
                      for (int i = 1; i < _lanes; i++)
                        Positioned(
                          left: i * laneW - 2,
                          top: 0,
                          bottom: 0,
                          child: Container(width: 4, color: Colors.white.withValues(alpha: 0.25)),
                        ),
                      ..._obs.map((o) => carAt(o.lane, o.y, _carFor[o] ?? '🚗')),
                      carAt(_player, _playerY, '🏎️', player: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
