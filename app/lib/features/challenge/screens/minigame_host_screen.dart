import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/providers/auth_provider.dart';
import '../../content/models/subject_model.dart';
import '../../../core/theme/app_theme.dart';
import '../minigames/minigame_contract.dart';
import '../minigames/minigame_registry.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

enum _Stage { intro, playing, submitting, done, error }

class MiniGameHostScreen extends ConsumerStatefulWidget {
  final String challengeId;
  final String minigameKey;
  const MiniGameHostScreen({
    super.key,
    required this.challengeId,
    required this.minigameKey,
  });

  @override
  ConsumerState<MiniGameHostScreen> createState() => _MiniGameHostScreenState();
}

class _MiniGameHostScreenState extends ConsumerState<MiniGameHostScreen> {
  _Stage _stage = _Stage.intro;
  MiniGameResult? _result;
  String? _errorMessage;
  Map<String, dynamic>? _gameConfig;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  // Best-effort: if this fails, games just fall back to their own defaults.
  Future<void> _loadConfig() async {
    try {
      final r = await http.get(Uri.parse('$_apiUrl/challenges/${widget.challengeId}'));
      if (r.statusCode != 200) return;
      final data = jsonDecode(r.body);
      final cfg = data['challenge']?['gameConfig'];
      if (cfg is Map<String, dynamic> && mounted) {
        setState(() => _gameConfig = cfg);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _submitScore(MiniGameResult result) async {
    setState(() {
      _result = result;
      _stage = _Stage.submitting;
    });
    final token = ref.read(authProvider).token;
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/challenges/${widget.challengeId}/submit-minigame-score'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'score': result.score,
          if (result.timeTakenMs != null) 'timeTakenMs': result.timeTakenMs,
        }),
      );
      if (!mounted) return;
      if (r.statusCode == 200) {
        setState(() => _stage = _Stage.done);
      } else {
        final data = jsonDecode(r.body);
        setState(() {
          _errorMessage = data['message'] ?? 'Failed to submit score';
          _stage = _Stage.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _stage = _Stage.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    final meta = kMiniGameMeta[widget.minigameKey];
    final builder = kMiniGameRegistry[widget.minigameKey];

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(meta?.label(isTamil) ?? widget.minigameKey),
      ),
      body: SafeArea(
        child: switch (_stage) {
          _Stage.intro => _IntroView(
              isTamil: isTamil,
              meta: meta,
              available: builder != null,
              onStart: () => setState(() => _stage = _Stage.playing),
            ),
          _Stage.playing => builder != null
              ? builder(widget.challengeId, _gameConfig, _submitScore)
              : _ComingSoonView(isTamil: isTamil),
          _Stage.submitting => const Center(child: CircularProgressIndicator()),
          _Stage.done => _DoneView(isTamil: isTamil, result: _result),
          _Stage.error => _ErrorView(
              isTamil: isTamil,
              message: _errorMessage,
              onBack: () => Navigator.of(context).pop(),
            ),
        },
      ),
    );
  }
}

class _IntroView extends StatelessWidget {
  final bool isTamil;
  final MiniGameMeta? meta;
  final bool available;
  final VoidCallback onStart;
  const _IntroView({
    required this.isTamil,
    required this.meta,
    required this.available,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(meta?.emoji ?? '🎮', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              meta?.label(isTamil) ?? '',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'உங்கள் சிறந்த மதிப்பெண்ணுக்காக விளையாடுங்கள். ஒரு முறை மட்டும் சமர்ப்பிக்க முடியும்!'
                  : 'Play for your best score. You can only submit once!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            if (available)
              GradientButton(
                label: isTamil ? 'தொடங்கு' : 'Start',
                onPressed: onStart,
              )
            else
              Text(
                isTamil ? 'விரைவில் வருகிறது' : 'Coming soon',
                style: const TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonView extends StatelessWidget {
  final bool isTamil;
  const _ComingSoonView({required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        isTamil ? 'விரைவில் வருகிறது' : 'Coming soon',
        style: const TextStyle(color: AppTheme.textHint, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  final bool isTamil;
  final MiniGameResult? result;
  const _DoneView({required this.isTamil, required this.result});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              isTamil ? 'மதிப்பெண் சமர்ப்பிக்கப்பட்டது!' : 'Score submitted!',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            if (result != null) ...[
              const SizedBox(height: 4),
              Text(
                isTamil ? 'மதிப்பெண்: ${result!.score}' : 'Score: ${result!.score}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              isTamil
                  ? 'மற்ற வீரர்கள் விளையாடி முடித்ததும் பரிசு தொகை பகிரப்படும்.'
                  : 'Prizes are distributed once other players finish.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isTamil ? 'போர் அரங்கத்திற்குச் செல்' : 'Back to Battle Arena'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final bool isTamil;
  final String? message;
  final VoidCallback onBack;
  const _ErrorView({required this.isTamil, required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              isTamil ? 'மதிப்பெண்ணை சமர்ப்பிக்க முடியவில்லை' : 'Could not submit score',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textHint, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: onBack, child: Text(isTamil ? 'திரும்பு' : 'Go Back')),
          ],
        ),
      ),
    );
  }
}
