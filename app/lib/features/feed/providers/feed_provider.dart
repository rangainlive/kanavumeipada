import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

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

  FeedPost copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLikedByMe,
  }) {
    return FeedPost(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      postType: postType,
      bodyText: bodyText,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt,
      refId: refId,
      refType: refType,
    );
  }

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
      case 'discussion':
        return '💬 Discussion';
      case 'test_published':
        return '📝 New Test Published';
      case 'challenge_created':
        return '🏆 Challenge Created';
      case 'result_shared':
        return '✅ Shared Score';
      case 'achievement_unlocked':
        return '🎉 Achievement';
      default:
        return '💬 Post';
    }
  }
}

class FeedComment {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String text;
  final DateTime createdAt;

  FeedComment({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
  });

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'],
      userId: json['userId'],
      userName: json['user']?['name'],
      userAvatar: json['user']?['avatarUrl'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
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
  final String? token;

  FeedNotifier(this.token) : super(FeedState());

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) state = FeedState();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final endpoint = token != null ? '/feed' : '/feed/global';
      final response = await http.get(
        Uri.parse('$_apiUrl$endpoint?limit=20&offset=${state.offset}'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (response.statusCode != 200) throw Exception('Failed to load feed');
      final data = jsonDecode(response.body);
      final newPosts = (data['posts'] as List)
          .map((p) => FeedPost.fromJson(p as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        posts: refresh ? newPosts : [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: data['hasMore'] ?? false,
        offset: state.offset + newPosts.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> likePost(String postId) async {
    if (token == null) return;
    _updatePost(postId, (p) => p.copyWith(
          likesCount: p.likesCount + 1, isLikedByMe: true));
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/feed/posts/$postId/like'),
        headers: _headers,
      );
      if (r.statusCode != 200) {
        _updatePost(postId, (p) => p.copyWith(
              likesCount: p.likesCount - 1, isLikedByMe: false));
      }
    } catch (_) {
      _updatePost(postId, (p) => p.copyWith(
            likesCount: p.likesCount - 1, isLikedByMe: false));
    }
  }

  Future<void> unlikePost(String postId) async {
    if (token == null) return;
    _updatePost(postId, (p) => p.copyWith(
          likesCount: (p.likesCount - 1).clamp(0, p.likesCount),
          isLikedByMe: false));
    try {
      await http.post(
        Uri.parse('$_apiUrl/feed/posts/$postId/unlike'),
        headers: _headers,
      );
    } catch (_) {}
  }

  Future<List<FeedComment>> fetchComments(String postId) async {
    try {
      final r = await http.get(
        Uri.parse('$_apiUrl/feed/posts/$postId/comments'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body);
      return (data['comments'] as List)
          .map((c) => FeedComment.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> addComment(String postId, String text) async {
    if (token == null) return false;
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/feed/posts/$postId/comments'),
        headers: _headers,
        body: jsonEncode({'text': text}),
      );
      if (r.statusCode == 201) {
        _updatePost(postId, (p) => p.copyWith(
              commentsCount: p.commentsCount + 1));
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _updatePost(String postId, FeedPost Function(FeedPost) update) {
    state = state.copyWith(
      posts: state.posts
          .map((p) => p.id == postId ? update(p) : p)
          .toList(),
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final authState = ref.watch(authProvider);
  return FeedNotifier(authState.token);
});
