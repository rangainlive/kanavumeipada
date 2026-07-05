import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'post_detail_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadFeed();
    });
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      final s = ref.read(feedProvider);
      if (s.hasMore && !s.isLoading) ref.read(feedProvider.notifier).loadFeed();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openPost(FeedPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    final user = ref.watch(authProvider).user;

    final firstName = (user?.name ?? '').trim().split(' ').first;
    final exams = (user?.examTarget ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: _PostFab(onTap: () => context.push('/feed/create')),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            backgroundColor: const Color(0xFF4338CA),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            leading: const SizedBox.shrink(),
            leadingWidth: 0,
            title: Text(
              firstName.isEmpty ? 'KanavuMeipada' : 'Hey $firstName! 👋',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.2),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 22),
                onPressed: () =>
                    ref.read(feedProvider.notifier).loadFeed(refresh: true),
                tooltip: 'Refresh',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 16, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firstName.isEmpty
                                ? 'Good day! 👋'
                                : 'Hey $firstName! 👋',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3),
                          ),
                          if (exams.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: exams
                                  .map((e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35)),
                                        ),
                                        child: Text(e,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ))
                                  .toList(),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Text("What's on your mind today?",
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (feed.isLoading && feed.posts.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (feed.posts.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(onPost: () => context.push('/feed/create')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i == feed.posts.length) {
                      return feed.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(child: CircularProgressIndicator()))
                          : const SizedBox.shrink();
                    }
                    final post = feed.posts[i];
                    return _PostCard(
                      key: ValueKey(post.id),
                      post: post,
                      onTap: () => _openPost(post),
                      onLike: () =>
                          ref.read(feedProvider.notifier).likePost(post.id),
                      onUnlike: () =>
                          ref.read(feedProvider.notifier).unlikePost(post.id),
                      onComment: () => _openPost(post),
                    );
                  },
                  childCount: feed.posts.length + (feed.isLoading ? 1 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Floating action button ───────────────────────────────────────────────────

class _PostFab extends StatefulWidget {
  final VoidCallback onTap;
  const _PostFab({required this.onTap});

  @override
  State<_PostFab> createState() => _PostFabState();
}

class _PostFabState extends State<_PostFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4338CA), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('New Post',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyState({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.people_rounded,
                color: Colors.white, size: 46),
          ),
          const SizedBox(height: 24),
          const Text('No posts yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a study tip,\nMCQ question, or poll!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textHint, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Create First Post', onPressed: onPost),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Post Card — modern, clean, social-app feel
// ═══════════════════════════════════════════════════════════════════════════

class _PostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onTap, onLike, onUnlike, onComment;

  const _PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onLike,
    required this.onUnlike,
    required this.onComment,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _heartAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.45)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.45, end: 0.82)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.82, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 35),
    ]).animate(_heartCtrl);
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    if (!widget.post.isLikedByMe) {
      _heartCtrl.forward(from: 0);
      widget.onLike();
    } else {
      widget.onUnlike();
    }
  }

  void _share() {
    final post = widget.post;
    final content = post.parsedContent;
    String text;
    if (content != null) {
      switch (content['_t']) {
        case 'mcq':
          final opts = (content['opts'] as List?)?.cast<String>() ?? [];
          final ans = content['ans'] as int? ?? 0;
          text = '❓ ${content['q']}\n\n'
              '${List.generate(opts.length, (i) => '${['A', 'B', 'C', 'D'][i]}) ${opts[i]}').join('\n')}'
              '\n\n✅ Answer: ${['A', 'B', 'C', 'D'][ans]}\n\nShared via KanavuMeipada';
          break;
        case 'poll':
          final opts = (content['opts'] as List?)?.cast<String>() ?? [];
          text = '📊 ${content['q']}\n\n'
              '${opts.map((o) => '• $o').join('\n')}'
              '\n\nShared via KanavuMeipada';
          break;
        case 'score':
          text = '🏆 I scored ${content['marks']} in ${content['exam']}!'
              '${content['note'] != null ? '\n${content['note']}' : ''}'
              '\n\nShared via KanavuMeipada';
          break;
        default:
          text = '${post.bodyText ?? ''}\n\nShared via KanavuMeipada';
      }
    } else {
      text = '${post.bodyText ?? ''}\n\nShared via KanavuMeipada';
    }
    Share.share(text);
  }

  Color get _accent => _accentFor(widget.post);

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Author row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    _Avatar(
                        name: post.userName ?? '?',
                        size: 42,
                        color: _accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.userName ?? 'Anonymous',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppTheme.textPrimary)),
                          Row(children: [
                            Text(timeago.format(post.createdAt),
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textHint)),
                            const SizedBox(width: 6),
                            Container(
                              width: 3, height: 3,
                              decoration: const BoxDecoration(
                                  color: AppTheme.textHint,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(post.typeLabel,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: _accent)),
                          ]),
                        ],
                      ),
                    ),
                    Icon(Icons.more_horiz_rounded,
                        size: 20, color: AppTheme.textHint),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: _ContentWidget(post: post),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── Actions ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(children: [
                  // Like
                  _ActionBtn(
                    onTap: _toggleLike,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ScaleTransition(
                          scale: _heartAnim,
                          child: Icon(
                            post.isLikedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: post.isLikedByMe
                                ? Colors.redAccent
                                : AppTheme.textSecondary,
                          ),
                        ),
                        if (post.likesCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('${post.likesCount}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: post.isLikedByMe
                                      ? Colors.redAccent
                                      : AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ),

                  // Comment
                  _ActionBtn(
                    onTap: widget.onComment,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 19, color: AppTheme.textSecondary),
                        if (post.commentsCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Share — opens native share sheet
                  _ActionBtn(
                    onTap: _share,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.ios_share_rounded,
                            size: 18, color: AppTheme.textSecondary),
                        SizedBox(width: 5),
                        Text('Share',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _ActionBtn({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: child,
      ),
    );
  }
}

// ─── Content widget (feed card — truncated preview) ───────────────────────────

class _ContentWidget extends StatefulWidget {
  final FeedPost post;
  const _ContentWidget({required this.post});

  @override
  State<_ContentWidget> createState() => _ContentWidgetState();
}

class _ContentWidgetState extends State<_ContentWidget> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final content = post.parsedContent;
    if (content == null) {
      return Text(
        post.bodyText ?? '',
        style: const TextStyle(
            fontSize: 15.5,
            color: AppTheme.textPrimary,
            height: 1.6,
            letterSpacing: 0.1),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      );
    }
    final color = _accentFor(post);
    switch (content['_t'] as String?) {
      case 'mcq':
        return _MCQPreview(content: content, color: color);
      case 'poll':
        return _PollPreview(content: content, color: color);
      case 'score':
        return _ScorePreview(content: content);
      default:
        return Text(post.bodyText ?? '',
            style: const TextStyle(
                fontSize: 15.5,
                color: AppTheme.textPrimary,
                height: 1.6),
            maxLines: 6,
            overflow: TextOverflow.ellipsis);
    }
  }
}

// MCQ — tap to reveal inline in feed
class _MCQPreview extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color color;
  const _MCQPreview({required this.content, required this.color});

  @override
  State<_MCQPreview> createState() => _MCQPreviewState();
}

class _MCQPreviewState extends State<_MCQPreview> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final ans = widget.content['ans'] as int? ?? 0;
    final revealed = _selected != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q,
          style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.4)),
      const SizedBox(height: 12),
      ...List.generate(opts.length, (i) {
        final isCorrect = i == ans;
        final isSelected = _selected == i;
        Color bg, border;
        Color textC = AppTheme.textPrimary;
        if (revealed) {
          if (isCorrect) { bg = const Color(0xFFD1FAE5); border = AppTheme.accent; textC = const Color(0xFF065F46); }
          else if (isSelected) { bg = const Color(0xFFFEE2E2); border = AppTheme.error; textC = AppTheme.error; }
          else { bg = const Color(0xFFF8FAFC); border = const Color(0xFFE2E8F0); textC = AppTheme.textHint; }
        } else { bg = const Color(0xFFF8FAFC); border = const Color(0xFFE2E8F0); }

        return GestureDetector(
          onTap: revealed ? null : () => setState(() => _selected = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: revealed && isCorrect ? AppTheme.accent : revealed && isSelected ? AppTheme.error : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: border),
                ),
                child: Center(child: Text(['A','B','C','D'][i],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: revealed && (isCorrect || isSelected) ? Colors.white : AppTheme.textHint))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(opts[i],
                  style: TextStyle(fontSize: 13.5, color: textC,
                      fontWeight: revealed && isCorrect ? FontWeight.w700 : FontWeight.normal))),
              if (revealed && isCorrect) const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 16),
              if (revealed && isSelected && !isCorrect) Icon(Icons.cancel_rounded, color: AppTheme.error, size: 16),
            ]),
          ),
        );
      }),
      if (!revealed)
        Text('Tap an option to reveal answer',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textHint, fontStyle: FontStyle.italic)),
      if (revealed)
        Text('Answer: ${['A','B','C','D'][ans]}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.accent)),
    ]);
  }
}

// Poll — tap to vote inline
class _PollPreview extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color color;
  const _PollPreview({required this.content, required this.color});

  @override
  State<_PollPreview> createState() => _PollPreviewState();
}

class _PollPreviewState extends State<_PollPreview> {
  int? _voted;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final fakeCounts = List.generate(opts.length, (i) => [3,5,2,1][i % 4]);
    final total = fakeCounts.fold(0, (a, b) => a + b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.4)),
      const SizedBox(height: 12),
      ...List.generate(opts.length, (i) {
        final pct = _voted != null ? fakeCounts[i] / total : 0.0;
        final isVoted = _voted == i;
        return GestureDetector(
          onTap: _voted != null ? null : () => setState(() => _voted = i),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: isVoted ? widget.color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isVoted ? widget.color : const Color(0xFFE2E8F0), width: isVoted ? 1.5 : 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(opts[i], style: TextStyle(fontSize: 13.5, fontWeight: isVoted ? FontWeight.w700 : FontWeight.normal, color: isVoted ? widget.color : AppTheme.textPrimary))),
                  if (_voted != null) Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isVoted ? widget.color : AppTheme.textHint)),
                ]),
                if (_voted != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => LinearProgressIndicator(
                        value: v, minHeight: 5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(isVoted ? widget.color : widget.color.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
        );
      }),
      if (_voted == null) Text('Tap to vote', style: TextStyle(fontSize: 11.5, color: AppTheme.textHint, fontStyle: FontStyle.italic)),
      if (_voted != null) Text('${fakeCounts.fold(0,(a,b)=>a+b)} votes', style: const TextStyle(fontSize: 11.5, color: AppTheme.textHint)),
    ]);
  }
}

// Score — clean gradient display
class _ScorePreview extends StatelessWidget {
  final Map<String, dynamic> content;
  const _ScorePreview({required this.content});

  @override
  Widget build(BuildContext context) {
    final exam = content['exam'] as String? ?? '';
    final marks = content['marks'] as String? ?? '';
    final note = content['note'] as String?;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5, fontWeight: FontWeight.w600)),
            Text(marks, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ]),
        ]),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text(note, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 13, height: 1.45)),
          ),
        ],
      ]),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Color _accentFor(FeedPost post) {
  switch (post.contentType) {
    case 'mcq': return const Color(0xFF7C3AED);
    case 'poll': return const Color(0xFF0EA5E9);
    case 'score': return AppTheme.accent;
    default: break;
  }
  switch (post.postType) {
    case 'result_shared': return AppTheme.accent;
    case 'challenge_created': return const Color(0xFF7C3AED);
    case 'test_published': return AppTheme.warning;
    default: return AppTheme.primary;
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const _Avatar({required this.name, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38)),
      ),
    );
  }
}
