import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../widgets/feed_post_card.dart';
import '../../../core/theme/app_theme.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadFeed();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(feedProvider);
      if (s.hasMore && !s.isLoading) {
        ref.read(feedProvider.notifier).loadFeed();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openComments(BuildContext context, FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(feedProvider.notifier).loadFeed(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/feed/create'),
        tooltip: 'Create Post',
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      body: feedState.isLoading && feedState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.read(feedProvider.notifier).loadFeed(refresh: true),
              child: feedState.posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline,
                              size: 72,
                              color: AppTheme.textHint),
                          const SizedBox(height: 12),
                          const Text('No posts yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Be the first to share a study tip!',
                              style: TextStyle(
                                  color: AppTheme.textHint, fontSize: 14)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.push('/feed/create'),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Create Post'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: feedState.posts.length +
                          (feedState.isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == feedState.posts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final post = feedState.posts[index];
                        return FeedPostCard(
                          post: post,
                          onLike: () =>
                              ref.read(feedProvider.notifier).likePost(post.id),
                          onUnlike: () =>
                              ref.read(feedProvider.notifier).unlikePost(post.id),
                          onComment: () => _openComments(context, post),
                        );
                      },
                    ),
            ),
    );
  }
}

// ---------- Comments bottom sheet ----------

class _CommentsSheet extends ConsumerStatefulWidget {
  final FeedPost post;
  const _CommentsSheet({required this.post});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _textController = TextEditingController();
  List<FeedComment> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final comments =
        await ref.read(feedProvider.notifier).fetchComments(widget.post.id);
    if (mounted) setState(() { _comments = comments; _loading = false; });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final ok = await ref
        .read(feedProvider.notifier)
        .addComment(widget.post.id, text);
    if (ok) {
      _textController.clear();
      await _load();
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${widget.post.commentsCount}',
                  style: const TextStyle(
                      color: AppTheme.textHint, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Comment list
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 40, color: AppTheme.textHint),
                            const SizedBox(height: 10),
                            Text('No comments yet. Be the first!',
                                style: TextStyle(
                                    color: AppTheme.textHint, fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        itemBuilder: (_, i) => _CommentTile(_comments[i]),
                      ),
          ),

          const Divider(height: 1),

          // Input
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLength: 280,
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _submit,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: _submitting
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final FeedComment comment;
  const _CommentTile(this.comment);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
            child: Text(
              (comment.userName ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName ?? 'Anonymous',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(comment.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.text,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
