import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  Feed Screen
// ═══════════════════════════════════════════════════════════════════════════

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      final s = ref.read(feedProvider);
      if (s.hasMore && !s.isLoading) ref.read(feedProvider.notifier).loadFeed();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _Header()),

          // ── Body ────────────────────────────────────────────────────────
          if (feed.isLoading && feed.posts.isEmpty)
            const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()))
          else if (feed.posts.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(onPost: () => context.push('/feed/create')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PostCard(
                        key: ValueKey(post.id),
                        post: post,
                        onLike: () =>
                            ref.read(feedProvider.notifier).likePost(post.id),
                        onUnlike: () =>
                            ref.read(feedProvider.notifier).unlikePost(post.id),
                        onComment: () => _openComments(ctx, post),
                      ),
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

  void _openComments(BuildContext ctx, FeedPost post) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _CommentsSheet(post: post),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Community',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text('Share • Discuss • Grow',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5)),
                ],
              ),
              const Spacer(),
              // Refresh
              IconButton(
                onPressed: () =>
                    ref.read(feedProvider.notifier).loadFeed(refresh: true),
                icon: const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 22),
              ),
              // Create post
              GestureDetector(
                onTap: () => context.push('/feed/create'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(children: [
                    Icon(Icons.edit_rounded,
                        color: AppTheme.primary, size: 15),
                    SizedBox(width: 5),
                    Text('Post',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onPost;
  const _EmptyState({required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.people_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('No posts yet',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 6),
            Text('Be the first to share a study tip, MCQ,\nor poll with fellow aspirants!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textHint, fontSize: 13.5)),
            const SizedBox(height: 28),
            GradientButton(label: 'Create First Post', onPressed: onPost),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Post Card
// ═══════════════════════════════════════════════════════════════════════════

class _PostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback? onLike, onUnlike, onComment;

  const _PostCard({
    Key? key,
    required this.post,
    this.onLike, this.onUnlike, this.onComment,
  }) : super(key: key);

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;
  late Animation<double> _likeAnim;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _likeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.85)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_likeCtrl);
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _handleLike() {
    if (!widget.post.isLikedByMe) {
      _likeCtrl.forward(from: 0);
      widget.onLike?.call();
    } else {
      widget.onUnlike?.call();
    }
  }

  void _handleShare(BuildContext ctx) {
    final post = widget.post;
    final content = post.parsedContent;
    String text;
    if (content != null && content['q'] != null) {
      text = content['q'] as String;
    } else {
      text = post.bodyText ?? post.typeLabel;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
        SizedBox(width: 8),
        Text('Copied to clipboard!'),
      ]),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.accent,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Color get _accentColor {
    final t = widget.post.contentType;
    switch (t) {
      case 'mcq': return const Color(0xFF7C3AED);
      case 'poll': return const Color(0xFF0EA5E9);
      case 'score': return AppTheme.accent;
      default: break;
    }
    switch (widget.post.postType) {
      case 'result_shared': return AppTheme.accent;
      case 'challenge_created': return const Color(0xFF7C3AED);
      case 'test_published': return AppTheme.warning;
      case 'achievement_unlocked': return const Color(0xFFD97706);
      default: return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final initials = (post.userName ?? '?')[0].toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 16, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured top bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.userName ?? 'Anonymous',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                    Text(timeago.format(post.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textHint)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(post.typeLabel,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _accentColor)),
              ),
            ]),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: _buildContent(post),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(children: [
              const Icon(Icons.favorite_rounded, size: 12, color: AppTheme.textHint),
              const SizedBox(width: 3),
              Text('${post.likesCount}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textHint)),
              const SizedBox(width: 10),
              const Icon(Icons.chat_bubble_rounded, size: 12, color: AppTheme.textHint),
              const SizedBox(width: 3),
              Text('${post.commentsCount}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textHint)),
            ]),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(children: [
              // Like (animated)
              Expanded(
                child: GestureDetector(
                  onTap: _handleLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _likeAnim,
                            child: Icon(
                              post.isLikedByMe
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 18,
                              color: post.isLikedByMe
                                  ? Colors.redAccent
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(post.isLikedByMe ? 'Liked' : 'Like',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: post.isLikedByMe
                                      ? Colors.redAccent
                                      : AppTheme.textSecondary)),
                        ]),
                  ),
                ),
              ),
              // Comment
              Expanded(
                child: InkWell(
                  onTap: widget.onComment,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 17, color: AppTheme.textSecondary),
                          SizedBox(width: 5),
                          Text('Comment',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                        ]),
                  ),
                ),
              ),
              // Share
              Expanded(
                child: InkWell(
                  onTap: () => _handleShare(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.ios_share_rounded,
                              size: 17, color: AppTheme.textSecondary),
                          SizedBox(width: 5),
                          Text('Share',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FeedPost post) {
    final content = post.parsedContent;
    if (content == null) {
      // Plain text post
      return Text(
        post.bodyText ?? '',
        style: const TextStyle(
            fontSize: 15, color: AppTheme.textPrimary, height: 1.55),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      );
    }

    final type = content['_t'] as String?;
    switch (type) {
      case 'mcq':
        return _MCQContent(content: content, accentColor: _accentColor);
      case 'poll':
        return _PollContent(content: content, accentColor: _accentColor);
      case 'score':
        return _ScoreContent(content: content);
      default:
        return Text(post.bodyText ?? '',
            style: const TextStyle(
                fontSize: 15, color: AppTheme.textPrimary, height: 1.55),
            maxLines: 6, overflow: TextOverflow.ellipsis);
    }
  }
}

// ─── MCQ Content ──────────────────────────────────────────────────────────────

class _MCQContent extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color accentColor;
  const _MCQContent({required this.content, required this.accentColor});

  @override
  State<_MCQContent> createState() => _MCQContentState();
}

class _MCQContentState extends State<_MCQContent> {
  int? _selected;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final ans = widget.content['ans'] as int? ?? 0;
    final color = widget.accentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.4)),
        const SizedBox(height: 12),
        ...List.generate(opts.length, (i) {
          final isCorrect = i == ans;
          final isSelected = _selected == i;
          final showResult = _revealed;

          Color bg = AppTheme.bgLight;
          Color border = const Color(0xFFE2E8F0);
          Color textC = AppTheme.textPrimary;

          if (showResult) {
            if (isCorrect) {
              bg = AppTheme.accent.withValues(alpha: 0.1);
              border = AppTheme.accent;
              textC = const Color(0xFF065F46);
            } else if (isSelected && !isCorrect) {
              bg = AppTheme.error.withValues(alpha: 0.08);
              border = AppTheme.error.withValues(alpha: 0.4);
              textC = AppTheme.error;
            }
          } else if (isSelected) {
            bg = color.withValues(alpha: 0.1);
            border = color.withValues(alpha: 0.5);
          }

          return GestureDetector(
            onTap: _revealed
                ? null
                : () => setState(() {
                      _selected = i;
                      _revealed = true;
                    }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Row(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: showResult && isCorrect ? AppTheme.accent : (isSelected ? color : Colors.white),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: showResult && isCorrect ? AppTheme.accent : border),
                  ),
                  child: Center(
                    child: Text(['A', 'B', 'C', 'D'][i],
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: (isSelected || (showResult && isCorrect))
                                ? Colors.white
                                : AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(opts[i],
                      style: TextStyle(
                          fontSize: 13.5,
                          color: textC,
                          fontWeight: isSelected || (showResult && isCorrect)
                              ? FontWeight.w600
                              : FontWeight.normal)),
                ),
                if (showResult && isCorrect)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.accent, size: 18),
                if (showResult && isSelected && !isCorrect)
                  Icon(Icons.cancel_rounded,
                      color: AppTheme.error.withValues(alpha: 0.7), size: 18),
              ]),
            ),
          );
        }),
        if (!_revealed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Tap an option to reveal the answer',
                style: TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textHint,
                    fontStyle: FontStyle.italic)),
          ),
        if (_revealed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Correct answer: ${['A', 'B', 'C', 'D'][ans]}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent),
            ),
          ),
      ],
    );
  }
}

// ─── Poll Content ─────────────────────────────────────────────────────────────

class _PollContent extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color accentColor;
  const _PollContent({required this.content, required this.accentColor});

  @override
  State<_PollContent> createState() => _PollContentState();
}

class _PollContentState extends State<_PollContent> {
  int? _voted;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final color = widget.accentColor;
    // Simulate vote counts (no backend vote storage yet)
    final fakeCounts = List.generate(opts.length, (i) => i == 0 ? 3 : (i == 1 ? 5 : 2));
    final total = fakeCounts.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.4)),
        const SizedBox(height: 12),
        ...List.generate(opts.length, (i) {
          final pct = _voted != null ? fakeCounts[i] / total : 0.0;
          final isVoted = _voted == i;
          return GestureDetector(
            onTap: _voted != null ? null : () => setState(() => _voted = i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isVoted
                      ? color.withValues(alpha: 0.1)
                      : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isVoted
                          ? color.withValues(alpha: 0.5)
                          : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(opts[i],
                            style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isVoted
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isVoted ? color : AppTheme.textPrimary)),
                      ),
                      if (_voted != null)
                        Text('${(pct * 100).round()}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isVoted ? color : AppTheme.textHint)),
                    ]),
                    if (_voted != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (_, v, _w) => LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                isVoted
                                    ? color
                                    : color.withValues(alpha: 0.35)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        if (_voted == null)
          Text('Tap to vote',
              style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textHint,
                  fontStyle: FontStyle.italic)),
        if (_voted != null)
          Text('${fakeCounts.fold(0, (a, b) => a + b)} votes',
              style: const TextStyle(
                  fontSize: 11.5, color: AppTheme.textHint)),
      ],
    );
  }
}

// ─── Score Content ────────────────────────────────────────────────────────────

class _ScoreContent extends StatelessWidget {
  final Map<String, dynamic> content;
  const _ScoreContent({required this.content});

  @override
  Widget build(BuildContext context) {
    final exam = content['exam'] as String? ?? '';
    final marks = content['marks'] as String? ?? '';
    final note = content['note'] as String?;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              Text(marks,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
            ]),
          ]),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4)),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Comments Sheet (animated)
// ═══════════════════════════════════════════════════════════════════════════

class _CommentsSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _listKey = GlobalKey<AnimatedListState>();
  final List<FeedComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  late AnimationController _sendAnim;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _ctrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _sendAnim.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list =
        await ref.read(feedProvider.notifier).fetchComments(widget.post.id);
    if (!mounted) return;
    setState(() { _loading = false; });
    for (final c in list) {
      _comments.add(c);
      _listKey.currentState?.insertItem(
        _comments.length - 1,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    _sendAnim.forward(from: 0);

    final ok =
        await ref.read(feedProvider.notifier).addComment(widget.post.id, text);
    if (ok && mounted) {
      _ctrl.clear();
      // Re-fetch to get the server-generated comment with proper ID
      final all = await ref
          .read(feedProvider.notifier)
          .fetchComments(widget.post.id);
      if (mounted) {
        // Add only the newest comment
        final newComment = all.lastOrNull;
        if (newComment != null &&
            (_comments.isEmpty || _comments.last.id != newComment.id)) {
          _comments.add(newComment);
          _listKey.currentState?.insertItem(
            _comments.length - 1,
            duration: const Duration(milliseconds: 400),
          );
        }
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _ctrl.text.trim().isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2)),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('Comments',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              if (_comments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_comments.length}',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
            ]),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),

          // Comment list
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.46),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()))
                : _comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(36),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48, color: AppTheme.textHint),
                          const SizedBox(height: 12),
                          const Text('No comments yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Be the first to comment!',
                              style: TextStyle(
                                  color: AppTheme.textHint, fontSize: 13)),
                        ]),
                      )
                    : AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        initialItemCount: _comments.length,
                        itemBuilder: (_, i, animation) =>
                            _CommentItem(_comments[i], animation),
                      ),
          ),

          const Divider(height: 1),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  maxLength: 280,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    fillColor: AppTheme.bgLight,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                          color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.2).animate(CurvedAnimation(
                    parent: _sendAnim, curve: Curves.elasticOut)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: hasText ? AppTheme.brandGradient : null,
                    color: hasText ? null : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: hasText
                        ? [BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: hasText ? _submit : null,
                      borderRadius: BorderRadius.circular(22),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(Icons.send_rounded,
                                color: hasText ? Colors.white : AppTheme.textHint,
                                size: 18),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Comment item with slide+fade animation ───────────────────────────────────

class _CommentItem extends StatelessWidget {
  final FeedComment comment;
  final Animation<double> animation;
  const _CommentItem(this.comment, this.animation);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  (comment.userName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(comment.userName ?? 'Anonymous',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppTheme.textPrimary)),
                        const SizedBox(width: 6),
                        Text(timeago.format(comment.createdAt),
                            style: const TextStyle(
                                fontSize: 10.5, color: AppTheme.textHint)),
                      ]),
                      const SizedBox(height: 3),
                      Text(comment.text,
                          style: const TextStyle(
                              fontSize: 13.5,
                              color: AppTheme.textSecondary,
                              height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
