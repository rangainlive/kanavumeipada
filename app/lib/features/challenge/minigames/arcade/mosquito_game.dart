import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Mosquito Swat — tap the mosquitoes before they fly away. 20s round.
class MosquitoGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const MosquitoGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<MosquitoGame> createState() => _MosquitoGameState();
}

class _Bug {
  final int id;
  final double x; // 0..1 fraction of width
  final double y; // 0..1 fraction of height
  final double size;
  _Bug(this.id, this.x, this.y, this.size);
}

class _MosquitoGameState extends ConsumerState<MosquitoGame> {
  static const _durationSec = 20;
  final _rng = Random();
  final List<_Bug> _bugs = [];
  final Map<int, Timer> _bugTimers = {};
  Timer? _spawnTimer;
  Timer? _countdown;
  int _timeLeft = _durationSec;
  int _swats = 0;
  int _nextId = 0;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 650), (_) => _spawn());
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _end();
    });
  }

  void _spawn() {
    if (!mounted || !_playing) return;
    final id = _nextId++;
    final bug = _Bug(id, 0.08 + _rng.nextDouble() * 0.84, 0.10 + _rng.nextDouble() * 0.78,
        38 + _rng.nextDouble() * 20);
    setState(() => _bugs.add(bug));
    _bugTimers[id] = Timer(const Duration(milliseconds: 1400), () => _remove(id));
  }

  void _remove(int id) {
    _bugTimers.remove(id)?.cancel();
    if (!mounted) return;
    setState(() => _bugs.removeWhere((b) => b.id == id));
  }

  void _swat(int id) {
    if (!_playing) return;
    setState(() => _swats++);
    _remove(id);
  }

  void _end() {
    _playing = false;
    _spawnTimer?.cancel();
    _countdown?.cancel();
    for (final t in _bugTimers.values) {
      t.cancel();
    }
    _bugTimers.clear();
    setState(() => _bugs.clear());
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _countdown?.cancel();
    for (final t in _bugTimers.values) {
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
        emoji: '🦟',
        score: _swats * 10,
        subtitle: isTamil ? '$_swats கொசுக்களை அடித்தீர்கள்' : 'You swatted $_swats mosquitoes',
        onFinish: widget.onFinish,
      );
    }
    return Container(
      color: const Color(0xFF0B3B2E),
      child: Column(
        children: [
          GameHud(
            left: isTamil ? '⏱ $_timeLeft வி' : '⏱ ${_timeLeft}s',
            right: isTamil ? 'அடி: $_swats' : 'Swats: $_swats',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                return Stack(
                  children: _bugs.map((b) {
                    return Positioned(
                      left: b.x * c.maxWidth - b.size / 2,
                      top: b.y * c.maxHeight - b.size / 2,
                      child: GestureDetector(
                        onTap: () => _swat(b.id),
                        child: Text('🦟', style: TextStyle(fontSize: b.size)),
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
