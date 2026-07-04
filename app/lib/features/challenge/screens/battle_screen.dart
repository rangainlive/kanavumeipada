import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

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
    this.title,
    this.creatorName,
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
        participantCount: int.tryParse(j['participantCount']?.toString() ?? '0') ?? 0,
        status: j['status'] ?? 'active',
        endAt: j['endAt'] != null ? DateTime.tryParse(j['endAt']) : null,
      );
}

final _challengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final response = await http.get(Uri.parse('$_apiUrl/challenges'));
  if (response.statusCode != 200) throw Exception('Failed to load challenges');
  final data = jsonDecode(response.body);
  final list = data['challenges'] as List? ?? [];
  return list.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

final _myChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) return [];
  final response = await http.get(
    Uri.parse('$_apiUrl/challenges/user/my'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body);
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
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            title: const Text('Battle Arena'),
            floating: true,
            snap: true,
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Arena'),
                Tab(text: 'My Battles'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ArenaTab(ref: ref),
            _MyBattlesTab(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _ArenaTab extends StatelessWidget {
  final WidgetRef ref;
  const _ArenaTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(_challengesProvider);

    return challengesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorState(
        message: 'Could not load challenges',
        onRetry: () => ref.refresh(_challengesProvider),
      ),
      data: (challenges) {
        if (challenges.isEmpty) {
          return const _EmptyBattles();
        }
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(_challengesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _ChallengeCard(
              challenge: challenges[i],
              onJoin: () => _confirmJoin(ctx, challenges[i], ref),
            ),
          ),
        );
      },
    );
  }

  void _confirmJoin(BuildContext context, Challenge c, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Battle?'),
        content: Text(
          'Entry fee: ${c.entryFeeCoins} coins\n'
          'Prize pool: ${c.prizePoolCoins} coins\n\n'
          'You\'ll need to complete the test to compete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _joinChallenge(context, c.id, ref);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinChallenge(BuildContext context, String id, WidgetRef ref) async {
    final token = ref.read(authProvider).token;
    final response = await http.post(
      Uri.parse('$_apiUrl/challenges/$id/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (!context.mounted) return;
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Joined! Complete the test to enter the leaderboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.invalidate(_myChallengesProvider);
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['error'] ?? 'Failed to join'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _MyBattlesTab extends StatelessWidget {
  final WidgetRef ref;
  const _MyBattlesTab({required this.ref});

  @override
  Widget build(BuildContext context) {
    final myAsync = ref.watch(_myChallengesProvider);
    return myAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _EmptyBattles(message: 'No battles yet.'),
      data: (challenges) {
        if (challenges.isEmpty) return const _EmptyBattles();
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) => _ChallengeCard(challenge: challenges[i]),
        );
      },
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onJoin;
  const _ChallengeCard({required this.challenge, this.onJoin});

  @override
  Widget build(BuildContext context) {
    final isActive = challenge.status == 'active';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  challenge.title ?? 'Battle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  challenge.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (challenge.creatorName != null)
              Text('by ${challenge.creatorName}',
                  style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(children: [
              _Stat(
                icon: Icons.monetization_on_rounded,
                color: Colors.orange,
                label: '${challenge.entryFeeCoins} entry',
              ),
              const SizedBox(width: 16),
              _Stat(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFF6366F1),
                label: '${challenge.prizePoolCoins} prize',
              ),
              const SizedBox(width: 16),
              _Stat(
                icon: Icons.people_outline,
                color: Colors.grey,
                label: '${challenge.participantCount} joined',
              ),
            ]),
            if (onJoin != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Join Battle'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _Stat({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.labelSmall),
    ]);
  }
}

class _EmptyBattles extends StatelessWidget {
  final String? message;
  const _EmptyBattles({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            message ?? 'No active battles yet.\nCreate one to challenge others!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
