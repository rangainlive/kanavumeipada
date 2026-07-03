import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const FeedPostCard({
    Key? key,
    required this.post,
    this.onLike,
    this.onUnlike,
    this.onComment,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? Text(post.userName?[0] ?? '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName ?? 'Anonymous',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Post title/type
            Row(
              children: [
                Text(
                  post.getDisplayText(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Post content
            if (post.bodyText != null && post.bodyText!.isNotEmpty) ...[
              Text(
                post.bodyText!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            // Engagement stats
            Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    post.likesCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '❤️',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 20,
                  child: Text(
                    post.commentsCount.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '💬',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: post.isLikedByMe ? onUnlike : onLike,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          post.isLikedByMe ? '❤️' : '🤍',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.isLikedByMe ? 'Liked' : 'Like',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: onComment,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Comment',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: onShare,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Text('📤', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Share',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
