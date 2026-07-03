import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        title: const Text('Community Feed'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: feedState.isLoading && feedState.posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(feedProvider.notifier).loadFeed(refresh: true);
              },
              child: feedState.posts.isEmpty
                  ? const Center(
                      child: Text('No posts yet. Follow users to see their activity!'),
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
