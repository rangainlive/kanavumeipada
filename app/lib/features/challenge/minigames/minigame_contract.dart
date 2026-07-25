import 'package:flutter/widgets.dart';

class MiniGameResult {
  final int score;
  final int? timeTakenMs;
  const MiniGameResult({required this.score, this.timeTakenMs});
}

/// Every mini-game is a widget matching this shape: given a challenge id,
/// play a single round and call [onFinish] exactly once when it ends.
typedef MiniGameBuilder = Widget Function(
  String challengeId,
  ValueChanged<MiniGameResult> onFinish,
);
