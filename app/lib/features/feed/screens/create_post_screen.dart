import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/providers/auth_provider.dart';
import '../providers/feed_provider.dart';

const _apiUrl = 'https://kanavumeipada-production.up.railway.app/api';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  String _postType = 'discussion';
  bool _isSubmitting = false;
  String? _error;

  static const _types = [
    ('discussion', 'Share a Tip', Icons.lightbulb_outline),
    ('result_shared', 'Share Score', Icons.bar_chart),
    ('achievement_unlocked', 'Achievement', Icons.emoji_events_outlined),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() { _isSubmitting = true; _error = null; });

    final token = ref.read(authProvider).token;
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/feed/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'postType': _postType, 'bodyText': text}),
      );

      if (response.statusCode == 201) {
        ref.read(feedProvider.notifier).loadFeed(refresh: true);
        if (mounted) context.pop();
      } else {
        final data = jsonDecode(response.body);
        setState(() { _error = data['error'] ?? 'Failed to post'; });
      }
    } catch (e) {
      setState(() { _error = 'Network error. Try again.'; });
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _controller.text.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _isSubmitting || charCount == 0 ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: _types.map((t) {
              final selected = _postType == t.$1;
              return ChoiceChip(
                avatar: Icon(t.$3, size: 16),
                label: Text(t.$2),
                selected: selected,
                onSelected: (_) => setState(() => _postType = t.$1),
              );
            }).toList(),
          ).paddedAll(12),

          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 500,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Share a study tip, question, or achievement…',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                counterText: '',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          if (_error != null)
            Container(
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 16),
                const SizedBox(width: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ]),
            ),

          Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$charCount / 500', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget paddedAll(double v) => Padding(padding: EdgeInsets.all(v), child: this);
}
