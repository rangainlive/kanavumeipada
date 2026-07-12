import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/subject_model.dart';

class CategoryScreen extends ConsumerWidget {
  final String category;
  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final colors = colorsFor(category);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors[0], colors[1]],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            )),
                        const SizedBox(height: 4),
                        Text('Choose your exam group',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: colors[0],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            sliver: subjectsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
                      const SizedBox(height: 12),
                      const Text('Could not load',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.refresh(subjectsProvider),
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                ),
              ),
              data: (subjects) {
                final filtered = subjects
                    .where((s) => s.examCategory == category)
                    .toList();

                final items = <_GroupItem>[];

                if (category == 'TNPSC') {
                  // Group 1 — use DB subject if available, else show as active placeholder
                  final g1 = filtered.firstWhere(
                    (s) => s.name.contains('Group 1'),
                    orElse: () => Subject(
                      id: '', name: 'TNPSC Group 1',
                      icon: '📋', examCategory: 'TNPSC',
                    ),
                  );
                  items.add(_GroupItem(
                    label: 'Group 1',
                    subtitle: 'TNPSC Group 1',
                    icon: g1.icon ?? '📋',
                    isLocked: false,
                    subject: g1.id.isNotEmpty ? g1 : null,
                  ));
                  // Group 2 placeholder
                  if (!filtered.any((s) => s.name.contains('Group 2'))) {
                    items.add(const _GroupItem(
                      label: 'Group 2', subtitle: 'TNPSC Group 2',
                      icon: '📗', isLocked: true,
                    ));
                  }
                  // Group 4 placeholder
                  if (!filtered.any((s) => s.name.contains('Group 4'))) {
                    items.add(const _GroupItem(
                      label: 'Group 4', subtitle: 'TNPSC Group 4',
                      icon: '📘', isLocked: true,
                    ));
                  }
                } else {
                  items.addAll(filtered.map((s) {
                    final displayName = s.name
                        .replaceFirst('$category ', '')
                        .trim();
                    return _GroupItem(
                      label: displayName,
                      subtitle: s.name,
                      icon: s.icon ?? '📖',
                      isLocked: false,
                      subject: s,
                    );
                  }));
                }

                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('📂', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No exams found for $category',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151))),
                      ]),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _GroupCard(
                      item: items[i],
                      accentColor: colors[0],
                      onTap: items[i].isLocked || items[i].subject == null
                          ? null
                          : () => ctx.push(
                                '/study/subject/${items[i].subject!.id}/hub',
                                extra: items[i].subject,
                              ),
                    ),
                    childCount: items.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupItem {
  final String label;
  final String subtitle;
  final String icon;
  final bool isLocked;
  final Subject? subject;
  const _GroupItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isLocked,
    this.subject,
  });
}

class _GroupCard extends StatelessWidget {
  final _GroupItem item;
  final Color accentColor;
  final VoidCallback? onTap;
  const _GroupCard({
    required this.item,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: item.isLocked ? 0.55 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.isLocked
                  ? const Color(0xFFE5E7EB)
                  : accentColor.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: item.isLocked
                    ? Colors.black.withValues(alpha: 0.04)
                    : accentColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.isLocked
                        ? const Color(0xFFF3F4F6)
                        : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(item.icon,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: item.isLocked
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827),
                          )),
                      const SizedBox(height: 3),
                      Text(
                        item.isLocked ? 'Coming soon' : 'Tap to explore',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: item.isLocked
                              ? const Color(0xFFD1D5DB)
                              : accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow or lock
                item.isLocked
                    ? const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFD1D5DB), size: 20)
                    : Icon(Icons.arrow_forward_ios_rounded,
                        color: accentColor, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
