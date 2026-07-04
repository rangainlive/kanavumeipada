import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/feed_provider.dart';
import '../widgets/feed_post_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadFeed();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final feedState = ref.read(feedProvider);
      if (feedState.hasMore && !feedState.isLoading) {
        ref.read(feedProvider.notifier).loadFeed();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/feed/create'),
        tooltip: 'Create Post',
        child: const Icon(Icons.edit_rounded),
      ),
      body: feedState.isLoading && feedState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(feedProvider.notifier).loadFeed(refresh: true);
              },
              child: feedState.posts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No posts yet.',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Be the first to share a study tip!',
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 16),
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
                        );
                      },
                    ),
            ),
    );
  }
}
