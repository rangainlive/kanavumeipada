import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

// ─── Models ──────────────────────────────────────────────────────────────────

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

  // Parse structured content from bodyText (MCQ / Poll / Score encoded as JSON)
  Map<String, dynamic>? get parsedContent {
    if (bodyText == null) return null;
    final trimmed = bodyText!.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // '_t' key: 'mcq' | 'poll' | 'score' | null → 'text'
  String get contentType => parsedContent?['_t'] as String? ?? 'text';

  FeedPost copyWith({int? likesCount, int? commentsCount, bool? isLikedByMe}) {
    return FeedPost(
      id: id, userId: userId, userName: userName, userAvatar: userAvatar,
      postType: postType, bodyText: bodyText,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      createdAt: createdAt, refId: refId, refType: refType,
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

  String get typeLabel {
    switch (contentType) {
      case 'mcq': return '❓ MCQ';
      case 'poll': return '📊 Poll';
      case 'score': return '🏆 Score';
      default:
        switch (postType) {
          case 'result_shared': return '✅ Score';
          case 'challenge_created': return '⚔️ Battle';
          case 'test_published': return '📝 Test';
          case 'achievement_unlocked': return '🎉 Achievement';
          default: return '💬 Post';
        }
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
    required this.id, required this.userId,
    this.userName, this.userAvatar,
    required this.text, required this.createdAt,
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

// ─── State ───────────────────────────────────────────────────────────────────

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int offset;

  FeedState({
    this.posts = const [], this.isLoading = false,
    this.hasMore = true, this.error, this.offset = 0,
  });

  FeedState copyWith({
    List<FeedPost>? posts, bool? isLoading,
    bool? hasMore, String? error, int? offset,
  }) {
    return FeedState(
      posts: posts ?? this.posts, isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore, error: error ?? this.error,
      offset: offset ?? this.offset,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class FeedNotifier extends StateNotifier<FeedState> {
  final String? token;
  FeedNotifier(this.token) : super(FeedState());

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<void> loadFeed({bool refresh = false}) async {
    if (!mounted) return;
    if (refresh) state = FeedState();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final endpoint = token != null ? '/feed' : '/feed/global';
      final offset = state.offset;
      final r = await http.get(
        Uri.parse('$_apiUrl$endpoint?limit=20&offset=$offset'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      );
      if (!mounted) return;
      if (r.statusCode != 200) throw Exception('Failed to load feed');
      final data = jsonDecode(r.body);
      final newPosts = (data['posts'] as List)
          .map((p) => FeedPost.fromJson(p as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      state = state.copyWith(
        posts: refresh ? newPosts : [...state.posts, ...newPosts],
        isLoading: false,
        hasMore: data['hasMore'] ?? false,
        offset: offset + newPosts.length,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> likePost(String postId) async {
    if (token == null || !mounted) return;
    _patch(postId, (p) => p.copyWith(likesCount: p.likesCount + 1, isLikedByMe: true));
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/feed/posts/$postId/like'), headers: _authHeaders);
      if (!mounted) return;
      if (r.statusCode != 200) {
        _patch(postId, (p) => p.copyWith(likesCount: p.likesCount - 1, isLikedByMe: false));
      }
    } catch (_) {
      if (!mounted) return;
      _patch(postId, (p) => p.copyWith(likesCount: p.likesCount - 1, isLikedByMe: false));
    }
  }

  Future<void> unlikePost(String postId) async {
    if (token == null || !mounted) return;
    _patch(postId, (p) => p.copyWith(
        likesCount: (p.likesCount - 1).clamp(0, p.likesCount), isLikedByMe: false));
    try {
      await http.post(Uri.parse('$_apiUrl/feed/posts/$postId/unlike'), headers: _authHeaders);
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
    } catch (_) { return []; }
  }

  Future<bool> addComment(String postId, String text) async {
    if (token == null || !mounted) return false;
    try {
      final r = await http.post(
        Uri.parse('$_apiUrl/feed/posts/$postId/comments'),
        headers: _authHeaders,
        body: jsonEncode({'text': text}),
      );
      if (!mounted) return false;
      if (r.statusCode == 201) {
        _patch(postId, (p) => p.copyWith(commentsCount: p.commentsCount + 1));
        return true;
      }
      return false;
    } catch (_) { return false; }
  }

  void _patch(String postId, FeedPost Function(FeedPost) fn) {
    if (!mounted) return;
    state = state.copyWith(
      posts: state.posts.map((p) => p.id == postId ? fn(p) : p).toList(),
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.watch(authProvider).token);
});
