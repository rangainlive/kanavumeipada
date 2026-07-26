import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Cave Escape — watch the glowing path light up, then retrace it from memory.
/// Each round the path grows by one. Score = rounds cleared.
class CavePuzzleGame extends ConsumerStatefulWidget {
  final String challengeId;
  final Map<String, dynamic>? config;
  final ValueChanged<MiniGameResult> onFinish;
  const CavePuzzleGame({super.key, required this.challengeId, this.config, required this.onFinish});

  @override
  ConsumerState<CavePuzzleGame> createState() => _CavePuzzleGameState();
}

class _CavePuzzleGameState extends ConsumerState<CavePuzzleGame> {
  static const _cells = 9; // 3x3
  final _rng = Random();
  final List<int> _seq = [];
  int _inputPos = 0;
  int _round = 0;
  int _lit = -1; // currently highlighted cell during show
  bool _showing = true;
  bool _done = false;
  Timer? _t;
  Timer? _idleTimer;

  // Safety net: nothing else ends the round if the player stops tapping
  // mid-retrace, so re-arm a timeout on every successful advance.
  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(seconds: 50), () {
      if (mounted && !_done) setState(() => _done = true);
    });
  }

  @override
  void initState() {
    super.initState();
    _extendAndShow();
  }

  void _extendAndShow() {
    int next = _rng.nextInt(_cells);
    if (_seq.isNotEmpty && next == _seq.last) next = (next + 1) % _cells;
    _seq.add(next);
    _showSequence();
  }

  void _showSequence() {
    _showing = true;
    _inputPos = 0;
    int i = 0;
    setState(() => _lit = -1);
    void step() {
      _t = Timer(const Duration(milliseconds: 480), () {
        if (!mounted) return;
        if (i >= _seq.length) {
          setState(() {
            _lit = -1;
            _showing = false;
          });
          _armIdleTimer();
          return;
        }
        setState(() => _lit = _seq[i]);
        i++;
        _t = Timer(const Duration(milliseconds: 280), () {
          if (!mounted) return;
          setState(() => _lit = -1);
          step();
        });
      });
    }

    step();
  }

  void _tap(int cell) {
    if (_showing || _done) return;
    if (cell == _seq[_inputPos]) {
      setState(() {
        _lit = cell;
        _inputPos++;
      });
      _armIdleTimer();
      Timer(const Duration(milliseconds: 140), () {
        if (mounted) setState(() => _lit = -1);
      });
      if (_inputPos >= _seq.length) {
        _round++;
        _idleTimer?.cancel();
        Timer(const Duration(milliseconds: 400), () {
          if (mounted) _extendAndShow();
        });
      }
    } else {
      setState(() => _done = true);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (_done) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '🕳️',
        score: _round * 25,
        subtitle: isTamil ? '$_round சுற்றுகளை கடந்தீர்கள்' : 'You cleared $_round rounds',
        onFinish: widget.onFinish,
      );
    }
    return Container(
      color: const Color(0xFF1A1425),
      child: Column(
        children: [
          GameHud(
            left: isTamil ? 'சுற்று: ${_round + 1}' : 'Round: ${_round + 1}',
            right: _showing
                ? (isTamil ? 'பாதையை பார்!' : 'Watch the path!')
                : (isTamil ? 'மீண்டும் தட்டு' : 'Retrace it'),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  children: List.generate(_cells, (i) {
                    final on = _lit == i;
                    return GestureDetector(
                      onTap: () => _tap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          gradient: on ? AppTheme.brandGradient : null,
                          color: on ? null : const Color(0xFF2A2340),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: on
                              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.6), blurRadius: 18)]
                              : null,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Center(
                          child: Text('💎',
                              style: TextStyle(
                                  fontSize: 26,
                                  color: on ? Colors.white : Colors.white.withValues(alpha: 0.12))),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
