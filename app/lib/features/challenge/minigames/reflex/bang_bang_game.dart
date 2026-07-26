import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';

enum _Phase { waiting, draw, falseStart, result }

/// Quickdraw reaction game — the Wave 0 plumbing validator.
/// Random delay, then "DRAW!"; score rewards a faster tap.
class BangBangGame extends ConsumerStatefulWidget {
  final String challengeId;
  final Map<String, dynamic>? config;
  final ValueChanged<MiniGameResult> onFinish;
  const BangBangGame({super.key, required this.challengeId, this.config, required this.onFinish});

  @override
  ConsumerState<BangBangGame> createState() => _BangBangGameState();
}

class _BangBangGameState extends ConsumerState<BangBangGame> {
  _Phase _phase = _Phase.waiting;
  Timer? _drawTimer;
  final Stopwatch _stopwatch = Stopwatch();
  int _reactionMs = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _scheduleDraw();
  }

  void _scheduleDraw() {
    final delayMs = 1200 + Random().nextInt(2800); // 1.2s - 4.0s
    _drawTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() => _phase = _Phase.draw);
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _onTap() {
    if (_phase == _Phase.waiting) {
      _drawTimer?.cancel();
      setState(() => _phase = _Phase.falseStart);
      return;
    }
    if (_phase != _Phase.draw) return;

    _stopwatch.stop();
    _reactionMs = _stopwatch.elapsedMilliseconds;
    _score = (1000 - _reactionMs).clamp(0, 1000);
    setState(() => _phase = _Phase.result);
  }

  @override
  void dispose() {
    _drawTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);

    return GestureDetector(
      onTap: _phase == _Phase.result ? null : _onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: _backgroundColor(),
        alignment: Alignment.center,
        child: switch (_phase) {
          _Phase.waiting => _WaitingView(isTamil: isTamil),
          _Phase.draw => _DrawView(isTamil: isTamil),
          _Phase.falseStart => _FalseStartView(
              isTamil: isTamil,
              onFinish: () => widget.onFinish(const MiniGameResult(score: 0)),
            ),
          _Phase.result => _ResultView(
              isTamil: isTamil,
              reactionMs: _reactionMs,
              score: _score,
              onFinish: () => widget.onFinish(
                  MiniGameResult(score: _score, timeTakenMs: _reactionMs)),
            ),
        },
      ),
    );
  }

  Color _backgroundColor() {
    switch (_phase) {
      case _Phase.waiting:
        return const Color(0xFF7F1D1D);
      case _Phase.draw:
        return const Color(0xFF166534);
      case _Phase.falseStart:
        return const Color(0xFF7F1D1D);
      case _Phase.result:
        return AppTheme.bgLight;
    }
  }
}

class _WaitingView extends StatelessWidget {
  final bool isTamil;
  const _WaitingView({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔫', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          isTamil ? 'காத்திருங்கள்...' : 'Wait for it...',
          style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DrawView extends StatelessWidget {
  final bool isTamil;
  const _DrawView({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Text(
      isTamil ? 'இப்போது தாக்கு!' : 'DRAW!',
      style: const TextStyle(
          color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
    );
  }
}

class _FalseStartView extends StatelessWidget {
  final bool isTamil;
  final VoidCallback onFinish;
  const _FalseStartView({required this.isTamil, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isTamil ? 'மிக விரைவு!' : 'Too soon!',
          style: const TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          isTamil ? 'மதிப்பெண்: 0' : 'Score: 0',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onFinish,
          child: Text(isTamil ? 'முடிந்தது' : 'Done'),
        ),
      ],
    );
  }
}

class _ResultView extends StatelessWidget {
  final bool isTamil;
  final int reactionMs;
  final int score;
  final VoidCallback onFinish;
  const _ResultView({
    required this.isTamil,
    required this.reactionMs,
    required this.score,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🎯', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Text(
          isTamil ? '${reactionMs}ms இல் தாக்கினீர்கள்' : 'Reacted in ${reactionMs}ms',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          isTamil ? 'மதிப்பெண்: $score' : 'Score: $score',
          style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: onFinish,
          child: Text(isTamil ? 'சமர்ப்பி' : 'Submit'),
        ),
      ],
    );
  }
}
