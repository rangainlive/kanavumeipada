import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';

/// Top HUD bar for a running game — shows a live label (time/score) row.
class GameHud extends StatelessWidget {
  final String left;
  final String right;
  final Color color;
  const GameHud({super.key, required this.left, required this.right, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(right,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Shared end-of-round result view with a Submit button that reports the score.
class GameResultView extends StatelessWidget {
  final bool isTamil;
  final String emoji;
  final int score;
  final String? subtitle;
  final int? timeTakenMs;
  final ValueChanged<MiniGameResult> onFinish;
  const GameResultView({
    super.key,
    required this.isTamil,
    required this.emoji,
    required this.score,
    required this.onFinish,
    this.subtitle,
    this.timeTakenMs,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              isTamil ? 'விளையாட்டு முடிந்தது!' : 'Round over!',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    isTamil ? 'மதிப்பெண்' : 'Score',
                    style: const TextStyle(color: AppTheme.primaryDim, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text('$score',
                      style: const TextStyle(
                          color: AppTheme.primaryDim, fontSize: 34, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: isTamil ? 'மதிப்பெண்ணை சமர்ப்பி' : 'Submit Score',
                icon: Icons.emoji_events_rounded,
                onPressed: () => onFinish(MiniGameResult(score: score, timeTakenMs: timeTakenMs)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 3-2-1 "Get ready" start countdown. Calls [onGo] when it hits 0.
class StartCountdown extends StatefulWidget {
  final bool isTamil;
  final VoidCallback onGo;
  const StartCountdown({super.key, required this.isTamil, required this.onGo});

  @override
  State<StartCountdown> createState() => _StartCountdownState();
}

class _StartCountdownState extends State<StartCountdown> {
  int _n = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_n <= 1) {
        widget.onGo();
      } else {
        setState(() => _n--);
        _tick();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$_n',
          style: const TextStyle(
              fontSize: 96, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}
