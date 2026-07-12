import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../../content/models/subject_model.dart';
import '../../content/widgets/lang_toggle_button.dart';
import '../../../core/theme/app_theme.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class Challenge {
  final String id;
  final String? title;
  final String? creatorName;
  final int entryFeeCoins;
  final int prizePoolCoins;
  final int participantCount;
  final String status;
  final DateTime? endAt;

  Challenge({
    required this.id,
    this.title, this.creatorName,
    required this.entryFeeCoins,
    required this.prizePoolCoins,
    required this.participantCount,
    required this.status,
    this.endAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'],
        title: j['title'],
        creatorName: j['creatorName'],
        entryFeeCoins: (j['entryFeeCoins'] as num?)?.toInt() ?? 0,
        prizePoolCoins: (j['prizePoolCoins'] as num?)?.toInt() ?? 0,
        participantCount:
            int.tryParse(j['participantCount']?.toString() ?? '0') ?? 0,
        status: j['status'] ?? 'active',
        endAt: j['endAt'] != null ? DateTime.tryParse(j['endAt']) : null,
      );
}

final _challengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final r = await http.get(Uri.parse('$_apiUrl/challenges'));
  if (r.statusCode != 200) throw Exception('Failed');
  final data = jsonDecode(r.body);
  final list = data['challenges'] as List? ?? [];
  return list.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

final _myChallengesProvider =
    FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) return [];
  final r = await http.get(Uri.parse('$_apiUrl/challenges/user/my'),
      headers: {'Authorization': 'Bearer $token'});
  if (r.statusCode != 200) return [];
  final data = jsonDecode(r.body);
  final list = data['challenges'] as List? ?? [];
  return list.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTamil = ref.watch(studyLangProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(isTamil ? 'போர் அரங்கம் ⚔️' : 'Battle Arena ⚔️',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                )),
                            const Spacer(),
                            const LangToggleButton(),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            isTamil
                                ? 'போட்டி. நாணயங்கள் வெல்லுங்கள். தலைமை வகியுங்கள்.'
                                : 'Compete. Win coins. Rule the board.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Prize pool banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              const Text('🏆', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isTamil ? 'உண்மையான நாணயங்கள் வெல்லுங்கள்!' : 'Win real coins!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isTamil
                                          ? 'போர்களில் சேரவும், எதிரிகளை வெல்லுங்கள், பரிசு நாணயங்கள் சேகரியுங்கள்'
                                          : 'Join battles, beat opponents, collect prize coins',
                                      style: const TextStyle(
                                        color: Color(0xFFBFDBFE),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.all(3),
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
                        dividerColor: Colors.transparent,
                        tabs: [
                          Tab(text: isTamil ? '⚔️  அரங்கம்' : '⚔️  Arena'),
                          Tab(text: isTamil ? '🛡️  என் போர்கள்' : '🛡️  My Battles'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ArenaTab(ref: ref, isTamil: isTamil),
            _MyBattlesTab(ref: ref, isTamil: isTamil),
          ],
        ),
      ),
    );
  }
}

class _ArenaTab extends StatelessWidget {
  final WidgetRef ref;
  final bool isTamil;
  const _ArenaTab({required this.ref, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_challengesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
          isTamil: isTamil, onRetry: () => ref.refresh(_challengesProvider)),
      data: (challenges) => challenges.isEmpty
          ? _EmptyArena(isTamil: isTamil)
          : RefreshIndicator(
              onRefresh: () async => ref.refresh(_challengesProvider),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: challenges.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ChallengeCard(
                    challenge: challenges[i],
                    isTamil: isTamil,
                    onJoin: () => _confirmJoin(ctx, challenges[i]),
                  ),
                ),
              ),
            ),
    );
  }

  void _confirmJoin(BuildContext context, Challenge c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('⚔️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(c.title ?? (isTamil ? 'போரில் சேர்' : 'Join Battle'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _BattleStat(
                    label: isTamil ? 'நுழைவு கட்டணம்' : 'Entry Fee',
                    value: '${c.entryFeeCoins} 🪙',
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BattleStat(
                    label: isTamil ? 'பரிசுத் தொகை' : 'Prize Pool',
                    value: '${c.prizePoolCoins} 🪙',
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isTamil
                    ? 'தரவரிசையில் இடம் பெற தேர்வை முடிக்கவும். வென்றவர் பரிசுத் தொகை பெறுவார்!'
                    : 'Complete the test to appear on the leaderboard. Winner takes the prize pool!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: isTamil
                  ? 'போரில் சேர் — ${c.entryFeeCoins} 🪙'
                  : 'Join Battle — ${c.entryFeeCoins} 🪙',
              onPressed: () {
                Navigator.pop(context);
                _doJoin(context, c.id);
              },
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTamil ? 'ரத்து செய்' : 'Cancel',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doJoin(BuildContext context, String id) async {
    final token = ref.read(authProvider).token;
    final r = await http.post(
      Uri.parse('$_apiUrl/challenges/$id/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (!context.mounted) return;
    if (r.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Joined! Complete the test to compete.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      ref.invalidate(_myChallengesProvider);
    } else {
      final data = jsonDecode(r.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['error'] ?? 'Failed to join'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _MyBattlesTab extends StatelessWidget {
  final WidgetRef ref;
  final bool isTamil;
  const _MyBattlesTab({required this.ref, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_myChallengesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _EmptyArena(
          isTamil: isTamil,
          message: isTamil ? 'அரங்கம் தாவலில் இருந்து ஒரு போரில் சேரவும்!' : 'Join a battle from the Arena tab!'),
      data: (challenges) => challenges.isEmpty
          ? _EmptyArena(
              isTamil: isTamil,
              message: isTamil ? 'இன்னும் போர்கள் இல்லை. அரங்கத்தில் இருந்து ஒன்றில் சேரவும்!' : 'No battles yet. Join one from the Arena!')
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: challenges.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ChallengeCard(challenge: challenges[i], isTamil: isTamil),
              ),
            ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isTamil;
  final VoidCallback? onJoin;
  const _ChallengeCard({required this.challenge, required this.isTamil, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final isActive = challenge.status == 'active';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFF1E1B4B), const Color(0xFF4F46E5)]
                    : [const Color(0xFF374151), const Color(0xFF6B7280)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(children: [
              const Text('⚔️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  challenge.title ?? 'Battle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  challenge.status.toUpperCase(),
                  style: TextStyle(
                    color: isActive ? const Color(0xFF6EE7B7) : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (challenge.creatorName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${isTamil ? 'உருவாக்கியவர்' : 'Created by'} ${challenge.creatorName}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textHint),
                    ),
                  ),
                Row(children: [
                  _StatPill(
                      '🪙 ${challenge.entryFeeCoins}', isTamil ? 'நுழைவு' : 'Entry',
                      AppTheme.warning.withValues(alpha: 0.12),
                      AppTheme.warning),
                  const SizedBox(width: 8),
                  _StatPill(
                      '🏆 ${challenge.prizePoolCoins}', isTamil ? 'பரிசு' : 'Prize',
                      AppTheme.accent.withValues(alpha: 0.12),
                      AppTheme.accent),
                  const SizedBox(width: 8),
                  _StatPill(
                      '👥 ${challenge.participantCount}', isTamil ? 'சேர்ந்தவர்கள்' : 'Joined',
                      AppTheme.primary.withValues(alpha: 0.1),
                      AppTheme.primary),
                ]),
                if (onJoin != null) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8, offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextButton.icon(
                        onPressed: onJoin,
                        icon: const Icon(Icons.flash_on_rounded,
                            color: Colors.white, size: 16),
                        label: Text(isTamil ? 'போரில் சேர்' : 'Join Battle',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color bg, fg;
  const _StatPill(this.value, this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: fg)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textHint)),
        ],
      ),
    );
  }
}

class _BattleStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _BattleStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyArena extends StatelessWidget {
  final String? message;
  final bool isTamil;
  const _EmptyArena({this.message, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('⚔️', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(isTamil ? 'இன்னும் போர்கள் இல்லை' : 'No battles yet',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        Text(
          message ?? (isTamil
              ? 'போர்கள் உருவாக்கப்பட்டதும் இங்கே தோன்றும்.'
              : 'Battles will appear here once they\'re created.'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textHint, fontSize: 13),
        ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isTamil;
  const _ErrorView({required this.onRetry, required this.isTamil});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 52, color: AppTheme.textHint),
        const SizedBox(height: 12),
        Text(isTamil ? 'போர்களை ஏற்ற முடியவில்லை' : 'Could not load battles',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onRetry,
          child: Text(isTamil ? 'மீண்டும் முயற்சி' : 'Retry'),
        ),
      ]),
    );
  }
}
