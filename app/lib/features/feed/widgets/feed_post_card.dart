import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/feed_provider.dart';
import '../../../core/theme/app_theme.dart';

class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onUnlike;
  final VoidCallback? onComment;

  const FeedPostCard({
    Key? key,
    required this.post,
    this.onLike,
    this.onUnlike,
    this.onComment,
  }) : super(key: key);

  void _share(BuildContext context) {
    final text = post.bodyText ?? post.getDisplayText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Post copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  backgroundImage: post.userAvatar != null
                      ? NetworkImage(post.userAvatar!)
                      : null,
                  child: post.userAvatar == null
                      ? Text(
                          (post.userName ?? '?')[0].toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName ?? 'Anonymous',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor(post.postType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.getDisplayText(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _typeColor(post.postType),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          if (post.bodyText != null && post.bodyText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Text(
                post.bodyText!,
                style: const TextStyle(
                    fontSize: 14.5,
                    color: AppTheme.textPrimary,
                    height: 1.45),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded,
                    size: 13, color: AppTheme.textHint),
                const SizedBox(width: 3),
                Text('${post.likesCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textHint)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 13, color: AppTheme.textHint),
                const SizedBox(width: 3),
                Text('${post.commentsCount}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textHint)),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),

          // Action bar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                _ActionBtn(
                  icon: post.isLikedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: post.isLikedByMe ? 'Liked' : 'Like',
                  color: post.isLikedByMe
                      ? Colors.redAccent
                      : AppTheme.textSecondary,
                  onTap: post.isLikedByMe ? onUnlike : onLike,
                ),
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comment',
                  color: AppTheme.textSecondary,
                  onTap: onComment,
                ),
                _ActionBtn(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  color: AppTheme.textSecondary,
                  onTap: () => _share(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _typeColor(String postType) {
    switch (postType) {
      case 'discussion':
        return AppTheme.primary;
      case 'test_published':
        return AppTheme.warning;
      case 'challenge_created':
        return const Color(0xFF7C3AED);
      case 'result_shared':
        return AppTheme.accent;
      case 'achievement_unlocked':
        return const Color(0xFFD97706);
      default:
        return AppTheme.textSecondary;
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
