import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Counting Stars — a burst of stars flashes; count them, then pick the right
/// number. 5 rounds.
class CountingStarsGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const CountingStarsGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<CountingStarsGame> createState() => _CountingStarsGameState();
}

class _CountingStarsGameState extends ConsumerState<CountingStarsGame> {
  static const _rounds = 5;
  final _rng = Random();
  int _round = 0;
  int _correct = 0;
  int _count = 0;
  List<Offset> _stars = [];
  List<int> _choices = [];
  bool _showing = true;
  bool _done = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _count = 5 + _rng.nextInt(13); // 5..17
    _stars = List.generate(
        _count, (_) => Offset(0.08 + _rng.nextDouble() * 0.84, 0.08 + _rng.nextDouble() * 0.84));
    final opts = <int>{_count};
    while (opts.length < 4) {
      final d = _count + (_rng.nextInt(7) - 3);
      if (d > 0 && d != _count) opts.add(d);
    }
    _choices = opts.toList()..shuffle();
    _showing = true;
    setState(() {});
    _t = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _showing = false);
    });
  }

  void _answer(int v) {
    if (_showing) return;
    if (v == _count) _correct++;
    _round++;
    if (_round >= _rounds) {
      setState(() => _done = true);
    } else {
      _next();
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (_done) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '⭐',
        score: _correct * 20,
        subtitle: isTamil ? '$_correct / $_rounds சரி' : '$_correct / $_rounds correct',
        onFinish: widget.onFinish,
      );
    }
    return Container(
      color: const Color(0xFF0B1030),
      child: Column(
        children: [
          GameHud(
            left: isTamil ? 'சுற்று ${_round + 1}/$_rounds' : 'Round ${_round + 1}/$_rounds',
            right: isTamil ? 'சரி: $_correct' : 'Correct: $_correct',
          ),
          Expanded(
            child: _showing
                ? LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: _stars
                          .map((o) => Positioned(
                                left: o.dx * c.maxWidth - 16,
                                top: o.dy * c.maxHeight - 16,
                                child: const Text('⭐', style: TextStyle(fontSize: 30)),
                              ))
                          .toList(),
                    ),
                  )
                : Center(
                    child: Text(
                      isTamil ? 'எத்தனை நட்சத்திரங்கள்?' : 'How many stars?',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          if (!_showing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.4,
                physics: const NeverScrollableScrollPhysics(),
                children: _choices
                    .map((v) => FilledButton(
                          onPressed: () => _answer(v),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.surface,
                            foregroundColor: AppTheme.textPrimary,
                            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          child: Text('$v'),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
