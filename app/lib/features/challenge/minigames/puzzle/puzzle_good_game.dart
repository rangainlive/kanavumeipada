import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

class _Q {
  final String prompt;
  final List<String> options;
  final int correct;
  const _Q(this.prompt, this.options, this.correct);
}

const _pool = <_Q>[
  _Q('2, 4, 8, 16, ?', ['24', '32', '30', '20'], 1),
  _Q('1, 1, 2, 3, 5, ?', ['7', '8', '9', '6'], 1),
  _Q('100, 81, 64, 49, ?', ['36', '40', '32', '25'], 0),
  _Q('7, 14, 28, ?, 112', ['48', '56', '64', '42'], 1),
  _Q('3, 6, 11, 18, ?', ['25', '27', '29', '24'], 1),
  _Q('12 ÷ 4 + 3 × 2 = ?', ['9', '12', '7', '18'], 0),
  _Q('Odd one out: 3, 5, 9, 11', ['3', '5', '9', '11'], 2),
  _Q('5, 10, 20, 40, ?', ['60', '80', '70', '50'], 1),
  _Q('Next: 1, 4, 9, 16, ?', ['20', '24', '25', '30'], 2),
  _Q('9, 7, 10, 8, 11, ?', ['9', '12', '13', '10'], 0),
  _Q('If A=1, C=3, E=5, then G=?', ['6', '7', '8', '9'], 1),
  _Q('Half of 3/4 of 80 = ?', ['30', '40', '20', '60'], 0),
];

/// How Smart Are You — 5 quick brain-teasers, 4 options each.
class PuzzleGoodGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const PuzzleGoodGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<PuzzleGoodGame> createState() => _PuzzleGoodGameState();
}

class _PuzzleGoodGameState extends ConsumerState<PuzzleGoodGame> {
  static const _rounds = 5;
  late final List<_Q> _qs;
  int _i = 0;
  int _correct = 0;
  int? _picked;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _qs = (_pool.toList()..shuffle(Random())).take(_rounds).toList();
  }

  void _pick(int idx) {
    if (_picked != null) return;
    setState(() => _picked = idx);
    if (idx == _qs[_i].correct) _correct++;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (_i + 1 >= _qs.length) {
        setState(() => _done = true);
      } else {
        setState(() {
          _i++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (_done) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '🧠',
        score: _correct * 20,
        subtitle: isTamil ? '$_correct / $_rounds சரி' : '$_correct / $_rounds correct',
        onFinish: widget.onFinish,
      );
    }
    final q = _qs[_i];
    return Container(
      color: AppTheme.bg,
      child: Column(
        children: [
          GameHud(
            left: isTamil ? 'கேள்வி ${_i + 1}/$_rounds' : 'Q ${_i + 1}/$_rounds',
            right: isTamil ? 'சரி: $_correct' : 'Correct: $_correct',
            color: AppTheme.textPrimary,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              q.prompt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(q.options.length, (idx) {
                Color bg = AppTheme.surface;
                Color fg = AppTheme.textPrimary;
                if (_picked != null) {
                  if (idx == q.correct) {
                    bg = AppTheme.success;
                    fg = Colors.white;
                  } else if (idx == _picked) {
                    bg = AppTheme.error;
                    fg = Colors.white;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _pick(idx),
                      style: FilledButton.styleFrom(
                        backgroundColor: bg,
                        foregroundColor: fg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        side: const BorderSide(color: AppTheme.border),
                      ),
                      child: Text(q.options[idx]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
