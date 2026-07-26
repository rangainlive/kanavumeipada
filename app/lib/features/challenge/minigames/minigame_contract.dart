import 'package:flutter/widgets.dart';

class MiniGameResult {
  final int score;
  final int? timeTakenMs;
  const MiniGameResult({required this.score, this.timeTakenMs});
}

/// Every mini-game is a widget matching this shape: given a challenge id and
/// an optional creator-set config (e.g. deal_or_no_deal's case count/round
/// pacing), play a single round and call [onFinish] exactly once when it
/// ends. Games with nothing to configure just ignore [config].
typedef MiniGameBuilder = Widget Function(
  String challengeId,
  Map<String, dynamic>? config,
  ValueChanged<MiniGameResult> onFinish,
);
