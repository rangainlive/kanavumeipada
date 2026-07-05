import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final FeedPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  final _replyCtrl = TextEditingController();
  final _listKey = GlobalKey<AnimatedListState>();
  final List<FeedComment> _comments = [];
  bool _loadingComments = true;
  bool _submitting = false;
  late AnimationController _sendPulse;
  late FeedPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _sendPulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _replyCtrl.addListener(() => setState(() {}));
    _fetchComments();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _replyCtrl.dispose();
    _sendPulse.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    final list =
        await ref.read(feedProvider.notifier).fetchComments(_post.id);
    if (!mounted) return;
    setState(() => _loadingComments = false);
    for (final c in list) {
      _comments.add(c);
      _listKey.currentState?.insertItem(
        _comments.length - 1,
        duration: const Duration(milliseconds: 280),
      );
    }
  }

  Future<void> _submit() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    _sendPulse.forward(from: 0);
    final ok =
        await ref.read(feedProvider.notifier).addComment(_post.id, text);
    if (ok && mounted) {
      _replyCtrl.clear();
      final all =
          await ref.read(feedProvider.notifier).fetchComments(_post.id);
      final newest = all.lastOrNull;
      if (newest != null &&
          (_comments.isEmpty || _comments.last.id != newest.id)) {
        _comments.add(newest);
        _listKey.currentState?.insertItem(
          _comments.length - 1,
          duration: const Duration(milliseconds: 350),
        );
        // Scroll to the new comment
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent + 80,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
      setState(() {
        _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
      });
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _handleLike() {
    if (!_post.isLikedByMe) {
      ref.read(feedProvider.notifier).likePost(_post.id);
      setState(() {
        _post = _post.copyWith(
            likesCount: _post.likesCount + 1, isLikedByMe: true);
      });
    } else {
      ref.read(feedProvider.notifier).unlikePost(_post.id);
      setState(() {
        _post = _post.copyWith(
            likesCount: (_post.likesCount - 1).clamp(0, _post.likesCount),
            isLikedByMe: false);
      });
    }
  }

  void _share() {
    final content = _post.parsedContent;
    String text;
    if (content != null) {
      switch (content['_t']) {
        case 'mcq':
          final opts = (content['opts'] as List?)?.cast<String>() ?? [];
          final ans = content['ans'] as int? ?? 0;
          text = '❓ ${content['q']}\n\n'
              '${List.generate(opts.length, (i) => '${['A','B','C','D'][i]}) ${opts[i]}').join('\n')}'
              '\n\n✅ Answer: ${['A','B','C','D'][ans]}\n\nShared via KanavuMeipada';
          break;
        case 'poll':
          final opts = (content['opts'] as List?)?.cast<String>() ?? [];
          text = '📊 ${content['q']}\n\n'
              '${opts.map((o) => '• $o').join('\n')}'
              '\n\nShared via KanavuMeipada';
          break;
        case 'score':
          text = '🏆 I scored ${content['marks']} in ${content['exam']}!\n'
              '${content['note'] != null ? '\n${content['note']}\n' : ''}'
              '\nShared via KanavuMeipada';
          break;
        default:
          text = '${_post.bodyText ?? ''}\n\nShared via KanavuMeipada';
      }
    } else {
      text = '${_post.bodyText ?? ''}\n\nShared via KanavuMeipada';
    }
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _replyCtrl.text.trim().isNotEmpty;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Full post ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _FullPostCard(
                      post: _post,
                      onLike: _handleLike,
                      onShare: _share,
                    ),
                  ),
                ),

                // ── Comments header ───────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(children: [
                      const Text('Comments',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const SizedBox(width: 8),
                      if (!_loadingComments && _comments.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_comments.length}',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                    ]),
                  ),
                ),

                // ── Comments list ─────────────────────────────────
                if (_loadingComments)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_comments.isEmpty)
                  SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 48,
                              color: AppTheme.textHint.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          const Text('No comments yet',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          Text('Be the first to reply!',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textHint)),
                        ]),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverAnimatedList(
                      key: _listKey,
                      initialItemCount: _comments.length,
                      itemBuilder: (ctx, i, anim) =>
                          _CommentBubble(_comments[i], anim),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),

          // ── Sticky reply bar ──────────────────────────────────────
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottom),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        color: const Color(0xFFE2E8F0), width: 1)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrl,
                    maxLength: 280,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      fillColor: const Color(0xFFF1F5F9),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: const BorderSide(
                            color: AppTheme.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.25).animate(
                      CurvedAnimation(
                          parent: _sendPulse, curve: Curves.elasticOut)),
                  child: GestureDetector(
                    onTap: hasText ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient:
                            hasText ? AppTheme.brandGradient : null,
                        color: hasText ? null : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(23),
                        boxShadow: hasText
                            ? [
                                BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3))
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : Icon(Icons.send_rounded,
                                color: hasText
                                    ? Colors.white
                                    : AppTheme.textHint,
                                size: 20),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppTheme.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,
      title: Row(children: [
        _Avatar(name: _post.userName ?? '?', size: 34, color: _accentFor(_post)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_post.userName ?? 'Anonymous',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text(timeago.format(_post.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
      ]),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share_rounded,
              size: 20, color: AppTheme.textSecondary),
          onPressed: _share,
        ),
      ],
    );
  }
}

// ─── Full post card (inside detail screen) ────────────────────────────────────

class _FullPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onLike, onShare;

  const _FullPostCard({
    required this.post,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final color = _accentFor(post);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type pill
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(post.typeLabel,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _ContentWidget(post: post, full: true),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Action row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(children: [
              _IconAction(
                icon: post.isLikedByMe
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${post.likesCount}',
                color: post.isLikedByMe ? Colors.redAccent : AppTheme.textSecondary,
                onTap: onLike,
              ),
              const SizedBox(width: 4),
              _IconAction(
                icon: Icons.chat_bubble_rounded,
                label: '${post.commentsCount}',
                color: AppTheme.textSecondary,
                onTap: () {},
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded,
                    size: 16, color: AppTheme.primary),
                label: const Text('Share',
                    style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      ),
    );
  }
}

// ─── Comment bubble ───────────────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  final FeedComment comment;
  final Animation<double> animation;
  const _CommentBubble(this.comment, this.animation);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                name: comment.userName ?? '?',
                size: 36,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.userName ?? 'Anonymous',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text(comment.text,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  height: 1.45)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(timeago.format(comment.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textHint)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
          colors: [color, color.withValues(alpha: 0.7)],
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

// ─── Content widget (shared by both feed card and detail screen) ──────────────

class _ContentWidget extends StatefulWidget {
  final FeedPost post;
  final bool full;
  const _ContentWidget({required this.post, this.full = false});

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
        maxLines: widget.full ? null : 7,
        overflow: widget.full ? null : TextOverflow.ellipsis,
      );
    }
    final type = content['_t'] as String?;
    final color = _accentFor(post);
    switch (type) {
      case 'mcq':
        return _MCQWidget(content: content, color: color);
      case 'poll':
        return _PollWidget(content: content, color: color);
      case 'score':
        return _ScoreWidget(content: content);
      default:
        return Text(post.bodyText ?? '',
            style: const TextStyle(
                fontSize: 15.5,
                color: AppTheme.textPrimary,
                height: 1.6),
            maxLines: widget.full ? null : 7,
            overflow: widget.full ? null : TextOverflow.ellipsis);
    }
  }
}

class _MCQWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color color;
  const _MCQWidget({required this.content, required this.color});

  @override
  State<_MCQWidget> createState() => _MCQWidgetState();
}

class _MCQWidgetState extends State<_MCQWidget> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final ans = widget.content['ans'] as int? ?? 0;
    final revealed = _selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q,
            style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.45)),
        const SizedBox(height: 14),
        ...List.generate(opts.length, (i) {
          final isCorrect = i == ans;
          final isSelected = _selected == i;

          Color bg, border;
          Color textC = AppTheme.textPrimary;
          if (revealed) {
            if (isCorrect) {
              bg = const Color(0xFFD1FAE5);
              border = AppTheme.accent;
              textC = const Color(0xFF065F46);
            } else if (isSelected) {
              bg = const Color(0xFFFEE2E2);
              border = AppTheme.error;
              textC = AppTheme.error;
            } else {
              bg = const Color(0xFFF8FAFC);
              border = const Color(0xFFE2E8F0);
              textC = AppTheme.textSecondary;
            }
          } else {
            bg = const Color(0xFFF8FAFC);
            border = const Color(0xFFE2E8F0);
          }

          return GestureDetector(
            onTap: revealed ? null : () => setState(() => _selected = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: revealed && isCorrect
                        ? AppTheme.accent
                        : revealed && isSelected
                            ? AppTheme.error
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                    child: Text(['A', 'B', 'C', 'D'][i],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: (revealed && (isCorrect || isSelected))
                                ? Colors.white
                                : AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(opts[i],
                      style: TextStyle(
                          fontSize: 14,
                          color: textC,
                          fontWeight: isCorrect && revealed
                              ? FontWeight.w700
                              : FontWeight.normal)),
                ),
                if (revealed && isCorrect)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.accent, size: 18),
                if (revealed && isSelected && !isCorrect)
                  Icon(Icons.cancel_rounded,
                      color: AppTheme.error, size: 18),
              ]),
            ),
          );
        }),
        if (!revealed)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('Tap an option to reveal the answer',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                    fontStyle: FontStyle.italic)),
          ),
        if (revealed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Answer: ${['A', 'B', 'C', 'D'][ans]}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent)),
          ),
      ],
    );
  }
}

class _PollWidget extends StatefulWidget {
  final Map<String, dynamic> content;
  final Color color;
  const _PollWidget({required this.content, required this.color});

  @override
  State<_PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<_PollWidget> {
  int? _voted;

  @override
  Widget build(BuildContext context) {
    final q = widget.content['q'] as String? ?? '';
    final opts = (widget.content['opts'] as List?)?.cast<String>() ?? [];
    final fakeCounts = List.generate(opts.length, (i) => [3, 5, 2, 1][i % 4]);
    final total = fakeCounts.fold(0, (a, b) => a + b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q,
            style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                height: 1.45)),
        const SizedBox(height: 14),
        ...List.generate(opts.length, (i) {
          final pct = _voted != null ? fakeCounts[i] / total : 0.0;
          final isVoted = _voted == i;
          return GestureDetector(
            onTap: _voted != null ? null : () => setState(() => _voted = i),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isVoted
                      ? widget.color.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVoted
                        ? widget.color
                        : const Color(0xFFE2E8F0),
                    width: isVoted ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(opts[i],
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: isVoted
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                color: isVoted
                                    ? widget.color
                                    : AppTheme.textPrimary)),
                      ),
                      if (_voted != null)
                        Text('${(pct * 100).round()}%',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isVoted
                                    ? widget.color
                                    : AppTheme.textHint)),
                    ]),
                    if (_voted != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (_, v, child) => LinearProgressIndicator(
                            value: v,
                            minHeight: 6,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                isVoted
                                    ? widget.color
                                    : widget.color.withValues(alpha: 0.3)),
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
                  fontSize: 12,
                  color: AppTheme.textHint,
                  fontStyle: FontStyle.italic)),
        if (_voted != null)
          Text('${fakeCounts.fold(0, (a, b) => a + b)} votes total',
              style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
      ],
    );
  }
}

class _ScoreWidget extends StatelessWidget {
  final Map<String, dynamic> content;
  const _ScoreWidget({required this.content});

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
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('🏆', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Text(marks,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
            ]),
          ]),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(note,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}
