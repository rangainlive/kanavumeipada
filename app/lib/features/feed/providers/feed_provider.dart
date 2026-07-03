import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedPost {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String postType;
  final String? bodyText;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByMe;
  final DateTime createdAt;
  final String? refId;
  final String? refType;

  FeedPost({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.postType,
    this.bodyText,
    required this.likesCount,
    required this.commentsCount,
    this.isLikedByMe = false,
    required this.createdAt,
    this.refId,
    this.refType,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'],
      userId: json['userId'],
      userName: json['user']?['name'],
      userAvatar: json['user']?['avatarUrl'],
      postType: json['postType'],
      bodyText: json['bodyText'],
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      isLikedByMe: json['isLikedByMe'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      refId: json['refId'],
      refType: json['refType'],
    );
  }

  String getDisplayText() {
    switch (postType) {
      case 'test_published':
        return '📝 New Test Published';
      case 'challenge_created':
        return '🏆 Challenge Created';
      case 'result_shared':
        return '✅ Shared their score';
      case 'achievement_unlocked':
        return '🎉 Achievement Unlocked';
      default:
        return 'Posted';
    }
  }
}

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int offset;

  FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.offset = 0,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? offset,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      offset: offset ?? this.offset,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final String apiUrl = 'http://localhost:3000/api';
  final String? token;

  FeedNotifier(this.token) : super(FeedState());

  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      state = FeedState();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/feed?limit=20&offset=${state.offset}'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load feed');
      }

      final data = jsonDecode(response.body);
      final newPosts = (data['posts'] as List)
          .map((p) => FeedPost.fromJson(p as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: data['hasMore'] ?? false,
        offset: state.offset + newPosts.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/feed/posts/$postId/like'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        // Update local state
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return FeedPost(
              id: post.id,
              userId: post.userId,
              userName: post.userName,
              userAvatar: post.userAvatar,
              postType: post.postType,
              bodyText: post.bodyText,
              likesCount: post.likesCount + 1,
              commentsCount: post.commentsCount,
              isLikedByMe: true,
              createdAt: post.createdAt,
              refId: post.refId,
              refType: post.refType,
            );
          }
          return post;
        }).toList();

        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      print('Error liking post: $e');
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/feed/posts/$postId/unlike'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );

      if (response.statusCode == 200) {
        // Update local state
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return FeedPost(
              id: post.id,
              userId: post.userId,
              userName: post.userName,
              userAvatar: post.userAvatar,
              postType: post.postType,
              bodyText: post.bodyText,
              likesCount: (post.likesCount - 1).clamp(0, post.likesCount),
              commentsCount: post.commentsCount,
              isLikedByMe: false,
              createdAt: post.createdAt,
              refId: post.refId,
              refType: post.refType,
            );
          }
          return post;
        }).toList();

        state = state.copyWith(posts: updatedPosts);
      }
    } catch (e) {
      print('Error unliking post: $e');
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final authState = ref.watch(authProvider);
  return FeedNotifier(authState.token);
});

// Import the auth provider
import '../../auth/providers/auth_provider.dart';
