import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../content/models/subject_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../minigame_contract.dart';
import '../common/game_common.dart';

/// Deal or No Deal — pick your case, open the rest, take the banker's offer or
/// risk it. Score = coins you walk away with.
class DealOrNoDealGame extends ConsumerStatefulWidget {
  final String challengeId;
  final ValueChanged<MiniGameResult> onFinish;
  const DealOrNoDealGame({super.key, required this.challengeId, required this.onFinish});

  @override
  ConsumerState<DealOrNoDealGame> createState() => _DealOrNoDealGameState();
}

class _Case {
  final int value;
  bool opened = false;
  _Case(this.value);
}

class _DealOrNoDealGameState extends ConsumerState<DealOrNoDealGame> {
  static const _values = [25, 75, 150, 300, 600, 1200];
  late final List<_Case> _cases;
  int? _own;
  int _offer = 0;
  bool _offering = false;
  bool _done = false;
  int _finalScore = 0;

  @override
  void initState() {
    super.initState();
    final vals = _values.toList()..shuffle(Random());
    _cases = vals.map((v) => _Case(v)).toList();
  }

  List<_Case> get _inPlay => _cases.where((c) => !c.opened).toList();

  void _tap(int i) {
    if (_done || _offering) return;
    if (_own == null) {
      setState(() => _own = i); // pick own case (stays closed)
      return;
    }
    if (i == _own || _cases[i].opened) return;
    setState(() => _cases[i].opened = true);
    final othersLeft = _inPlay.where((c) => c != _cases[_own!]).length;
    if (othersLeft == 0) {
      _finish(_cases[_own!].value); // only own case left
      return;
    }
    // banker offer
    final avg = _inPlay.map((c) => c.value).reduce((a, b) => a + b) / _inPlay.length;
    setState(() {
      _offer = (avg * 0.85).round();
      _offering = true;
    });
  }

  void _deal() => _finish(_offer);
  void _noDeal() => setState(() => _offering = false);

  void _finish(int score) {
    setState(() {
      _finalScore = score;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    if (_done) {
      return GameResultView(
        isTamil: isTamil,
        emoji: '💼',
        score: _finalScore,
        subtitle: isTamil ? '$_finalScore நாணயங்கள் வென்றீர்கள்' : 'You walked away with $_finalScore coins',
        onFinish: widget.onFinish,
      );
    }
    return Container(
      color: AppTheme.bg,
      child: Column(
        children: [
          GameHud(
            left: _own == null
                ? (isTamil ? 'உங்கள் பெட்டியை தேர்வு செய்' : 'Pick your case')
                : (isTamil ? 'ஒரு பெட்டியை திற' : 'Open a case'),
            right: _own == null ? '' : (isTamil ? 'உங்கள் பெட்டி #${_own! + 1}' : 'Yours: #${_own! + 1}'),
            color: AppTheme.textPrimary,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: List.generate(_cases.length, (i) {
                  final c = _cases[i];
                  final isOwn = _own == i;
                  return GestureDetector(
                    onTap: () => _tap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.opened ? AppTheme.surface2 : (isOwn ? AppTheme.primary : AppTheme.surface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isOwn ? AppTheme.primaryDeep : AppTheme.border, width: isOwn ? 2 : 1),
                        boxShadow: c.opened ? null : AppTheme.cardShadow,
                      ),
                      child: Center(
                        child: c.opened
                            ? Text('${c.value}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textHint))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(isOwn ? '🎁' : '💼', style: const TextStyle(fontSize: 34)),
                                  Text('#${i + 1}',
                                      style: TextStyle(
                                          color: isOwn ? Colors.white : AppTheme.textHint,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (_offering)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              color: AppTheme.surface,
              child: Column(
                children: [
                  Text(
                    isTamil ? 'வங்கியாளர் வாய்ப்பு' : 'Banker\'s offer',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  Text('💰 $_offer',
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900, color: AppTheme.primaryDim)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _noDeal,
                          child: Text(isTamil ? 'வேண்டாம்' : 'No Deal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _deal,
                          child: Text(isTamil ? 'சம்மதம்!' : 'Deal!'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
