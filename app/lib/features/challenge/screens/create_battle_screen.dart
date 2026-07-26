import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../../auth/providers/auth_provider.dart';
import '../../content/models/subject_model.dart';
import '../../../core/theme/app_theme.dart';
import '../minigames/minigame_registry.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class CreateBattleScreen extends ConsumerStatefulWidget {
  const CreateBattleScreen({super.key});

  @override
  ConsumerState<CreateBattleScreen> createState() => _CreateBattleScreenState();
}

const List<({String label, Duration duration})> _deadlinePresets = [
  (label: '1h', duration: Duration(hours: 1)),
  (label: '6h', duration: Duration(hours: 6)),
  (label: '1d', duration: Duration(days: 1)),
  (label: '3d', duration: Duration(days: 3)),
  (label: '1w', duration: Duration(days: 7)),
];

class _CreateBattleScreenState extends ConsumerState<CreateBattleScreen> {
  String? _minigameKey;
  int _entryFee = 50;
  int _minParticipants = 3;
  int? _maxParticipants;
  Duration _deadline = const Duration(days: 1);
  bool _isPublic = true;
  int _dealRounds = 5;
  bool _submitting = false;
  String? _error;

  static const _dealTotalCases = 25;

  List<int> get _dealRoundBreakdown {
    final base = (_dealTotalCases - 1) ~/ _dealRounds;
    final remainder = (_dealTotalCases - 1) % _dealRounds;
    return List.generate(
      _dealRounds,
      (i) => base + (i < remainder ? 1 : 0),
    );
  }

  Future<void> _create(bool isTamil) async {
    if (_minigameKey == null) {
      setState(() => _error = isTamil ? 'ஒரு விளையாட்டைத் தேர்ந்தெடுக்கவும்' : 'Pick a game first');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final token = ref.read(authProvider).token;
    final body = <String, dynamic>{
      'gameType': 'minigame',
      'minigameKey': _minigameKey,
      'entryFeeCoins': _entryFee,
      'minParticipants': _minParticipants,
      if (_maxParticipants != null) 'maxParticipants': _maxParticipants,
      'durationMinutes': _deadline.inMinutes,
      'isPublic': _isPublic,
      if (_minigameKey == 'deal_or_no_deal')
        'gameConfig': {
          'totalCases': _dealTotalCases,
          'rounds': _dealRoundBreakdown,
        },
    };

    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/challenges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (r.statusCode == 201) {
        final data = jsonDecode(r.body);
        final challenge = data['challenge'];
        final joinCode = challenge['joinCode'] as String?;
        setState(() => _submitting = false);
        if (!_isPublic && joinCode != null) {
          _showShareSheet(isTamil, joinCode);
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        final data = jsonDecode(r.body);
        setState(() {
          _submitting = false;
          _error = data['message'] ?? (isTamil ? 'போரை உருவாக்க முடியவில்லை' : 'Failed to create battle');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  void _showShareSheet(bool isTamil, String joinCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              isTamil ? 'தனியார் போர் உருவாக்கப்பட்டது!' : 'Private battle created!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isTamil ? 'இந்த குறியீட்டைப் பகிரவும்:' : 'Share this code to invite players:',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                joinCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: AppTheme.primaryDim,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: joinCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isTamil ? 'நகலெடுக்கப்பட்டது!' : 'Copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(isTamil ? 'நகலெடு' : 'Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final meta = kMiniGameMeta[_minigameKey];
                      Share.share(
                        isTamil
                            ? 'எனது ${meta?.labelTa ?? ''} போரில் சேரவும் — குறியீடு: $joinCode'
                            : 'Join my ${meta?.labelEn ?? ''} battle — code: $joinCode',
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(isTamil ? 'பகிர்' : 'Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                Navigator.of(context).pop(true); // close create screen
              },
              child: Text(isTamil ? 'முடிந்தது' : 'Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: Text(isTamil ? 'போரை உருவாக்கு' : 'Create Battle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _SectionLabel(isTamil ? 'விளையாட்டைத் தேர்ந்தெடு' : 'Pick a game'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: kMiniGameMeta.entries.map((e) {
                final selected = _minigameKey == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _minigameKey = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primarySoft : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppTheme.primary : AppTheme.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.value.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            e.value.label(isTamil),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _SectionLabel(isTamil ? 'நுழைவு கட்டணம் (நாணயங்கள்)' : 'Entry fee (coins)'),
            const SizedBox(height: 8),
            _Stepper(
              value: _entryFee,
              min: 10,
              max: 10000,
              step: 10,
              onChanged: (v) => setState(() => _entryFee = v),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isTamil
                    ? 'அதிகபட்ச பரிசுத் தொகை மதிப்பீடு: ${_entryFee * (_maxParticipants ?? 10)} 🪙'
                    : 'Est. max prize pool: ${_entryFee * (_maxParticipants ?? 10)} 🪙',
                style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 20),

            _SectionLabel(isTamil ? 'பங்கேற்பாளர்கள்' : 'Participants'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LabeledStepper(
                    label: isTamil ? 'குறைந்தபட்சம்' : 'Min',
                    value: _minParticipants,
                    min: 2,
                    max: _maxParticipants ?? 1000,
                    onChanged: (v) => setState(() => _minParticipants = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabeledStepper(
                    label: isTamil ? 'அதிகபட்சம்' : 'Max',
                    value: _maxParticipants ?? 10,
                    min: _minParticipants,
                    max: 1000,
                    onChanged: (v) => setState(() => _maxParticipants = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(isTamil ? 'சேரும் காலக்கெடு' : 'Join-by deadline'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _deadlinePresets.map((p) {
                final selected = _deadline == p.duration;
                return ChoiceChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _deadline = p.duration),
                  selectedColor: AppTheme.primarySoft,
                  labelStyle: TextStyle(
                    color: selected ? AppTheme.primaryDim : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
            ),

            if (_minigameKey == 'deal_or_no_deal') ...[
              const SizedBox(height: 20),
              _SectionLabel(isTamil ? 'ஒப்பந்த சுற்றுகள் (25 பெட்டிகள்)' : 'Deal rounds (25 cases)'),
              const SizedBox(height: 8),
              _Stepper(
                value: _dealRounds,
                min: 3,
                max: 9,
                step: 1,
                onChanged: (v) => setState(() => _dealRounds = v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  isTamil
                      ? '$_dealRounds சுற்றுகள் → ${_dealRoundBreakdown.join(", ")} பெட்டிகள் ஒவ்வொரு சலுகைக்கும் முன்'
                      : '$_dealRounds rounds → ${_dealRoundBreakdown.join(", ")} cases opened before each offer',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                ),
              ),
            ],

            const SizedBox(height: 20),
            _SectionLabel(isTamil ? 'யார் பார்க்கலாம்' : 'Visibility'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _VisibilityOption(
                    label: isTamil ? 'பொது' : 'Public',
                    subtitle: isTamil ? 'அரங்கத்தில் அனைவரும் காணலாம்' : 'Anyone browsing Arena can join',
                    icon: Icons.public_rounded,
                    selected: _isPublic,
                    onTap: () => setState(() => _isPublic = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _VisibilityOption(
                    label: isTamil ? 'தனியார்' : 'Private',
                    subtitle: isTamil ? 'குறியீடு மூலம் மட்டும்' : 'Code-only invite',
                    icon: Icons.lock_rounded,
                    selected: !_isPublic,
                    onTap: () => setState(() => _isPublic = false),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            ],

            const SizedBox(height: 28),
            GradientButton(
              label: isTamil ? 'போரை உருவாக்கு' : 'Create Battle',
              isLoading: _submitting,
              onPressed: _submitting ? null : () => _create(isTamil),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _LabeledStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _LabeledStepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _Stepper(value: value, min: min, max: max, step: 1, onChanged: onChanged),
      ],
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _VisibilityOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppTheme.primaryDim : AppTheme.textHint, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }
}
