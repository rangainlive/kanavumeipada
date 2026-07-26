import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Apple Shootout — pop the falling apples before they land. 3 misses and out.
class AppleShootoutGame extends ConsumerStatefulWidget {
  final String challengeId;
  final Map<String, dynamic>? config;
  final ValueChanged<MiniGameResult> onFinish;
  const AppleShootoutGame({super.key, required this.challengeId, this.config, required this.onFinish});

  @override
  ConsumerState<AppleShootoutGame> createState() => _AppleShootoutGameState();
}

class _Apple {
  final int id;
  final double x; // 0..1
  bool falling = false;
  _Apple(this.id, this.x);
}

class _AppleShootoutGameState extends ConsumerState<AppleShootoutGame> {
  final _rng = Random();
  final List<_Apple> _apples = [];
  final Map<int, Timer> _timers = {};
  Timer? _spawn;
  int _hits = 0;
  int _lives = 3;
  int _nextId = 0;
  bool _playing = true;
  final Duration _fall = const Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _spawn = Timer.periodic(const Duration(milliseconds: 800), (_) => _add());
  }

  void _add() {
    if (!mounted || !_playing) return;
    final a = _Apple(_nextId++, 0.08 + _rng.nextDouble() * 0.84);
    setState(() => _apples.add(a));
    // begin fall next frame so AnimatedPositioned animates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => a.falling = true);
    });
    _timers[a.id] = Timer(_fall, () => _miss(a.id));
  }

  void _hit(int id) {
    if (!_playing) return;
    _timers.remove(id)?.cancel();
    setState(() {
      _hits++;
      _apples.removeWhere((a) => a.id == id);
    });
  }

  void _miss(int id) {
    _timers.remove(id)?.cancel();
    if (!mounted || !_playing) return;
    setState(() {
      _apples.removeWhere((a) => a.id == id);
      _lives--;
    });
    if (_lives <= 0) _end();
  }

  void _end() {
    _playing = false;
    _spawn?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    setState(() => _apples.clear());
  }

  @override
  void dispose() {
    _spawn?.cancel();
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (!_playing) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '🍎',
        score: _hits * 10,
        subtitle: isTamil ? '$_hits ஆப்பிள்களை சுட்டீர்கள்' : 'You popped $_hits apples',
        onFinish: widget.onFinish,
      );
    }
    return Container(
      color: const Color(0xFF1E3A5F),
      child: Column(
        children: [
          GameHud(
            left: '${'❤️' * _lives}${'🤍' * (3 - _lives)}',
            right: isTamil ? 'சுட்டது: $_hits' : 'Hits: $_hits',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  children: _apples.map((a) {
                    return AnimatedPositioned(
                      key: ValueKey(a.id),
                      duration: _fall,
                      curve: Curves.easeIn,
                      left: a.x * (c.maxWidth - 48),
                      top: a.falling ? c.maxHeight - 56 : -8,
                      child: GestureDetector(
                        onTap: () => _hit(a.id),
                        child: const Text('🍎', style: TextStyle(fontSize: 44)),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
