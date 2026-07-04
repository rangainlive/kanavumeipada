import 'package:flutter/material.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({Key? key}) : super(key: key);

  static const _examTypes = [
    ('UPSC', '🏛️', Color(0xFF6366F1)),
    ('TNPSC', '🌴', Color(0xFF0EA5E9)),
    ('SSC', '📋', Color(0xFF10B981)),
    ('Banking', '🏦', Color(0xFFF59E0B)),
    ('NEET', '🧬', Color(0xFFEF4444)),
    ('JEE', '⚙️', Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Tests'),
            floating: true,
            snap: true,
          ),

          SliverToBoxAdapter(
            child: _DailyQuizBanner(context: context),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('By Exam',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final exam = _examTypes[i];
                  return _ExamCard(
                    emoji: exam.$2,
                    name: exam.$1,
                    color: exam.$3,
                    onTap: () => _showComingSoon(context, exam.$1),
                  );
                },
                childCount: _examTypes.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  Icon(Icons.construction_rounded,
                      size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(height: 8),
                  Text(
                    'Full mock tests with instant analysis\nand national leaderboard — coming soon!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$exam tests coming soon! We\'re adding questions now.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DailyQuizBanner extends StatelessWidget {
  final BuildContext context;
  const _DailyQuizBanner({required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Quiz',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('10 questions · 5 minutes\nEarn 50 coins on completion',
                      style: Theme.of(ctx)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF10B981),
                    ),
                    onPressed: () => _showComingSoon(ctx),
                    child: const Text('Start Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text('🎯', style: TextStyle(fontSize: 56)),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(
        content: Text('Daily quiz launching soon — stay tuned!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final String emoji, name;
  final Color color;
  final VoidCallback onTap;
  const _ExamCard({required this.emoji, required this.name, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              Text(name,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 15, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
