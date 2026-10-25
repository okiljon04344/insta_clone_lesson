import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postImageUrl;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.postOwnerId,
    required this.postImageUrl,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  String? _replyToUsername;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final commentRef = db
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc();
      await commentRef.set({
        'id': commentRef.id,
        'uid': user.uid,
        'username': userData['username'] ?? user.displayName ?? '',
        'userPhotoUrl': userData['photoUrl'] ?? user.photoURL ?? '',
        'text': text,
        'likesCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db.collection('posts').doc(widget.postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Don't notify the author about their own comment.
      if (widget.postOwnerId != user.uid) {
        await NotificationService().sendCommentNotification(
          toUid: widget.postOwnerId,
          postId: widget.postId,
          postImageUrl: widget.postImageUrl,
          comment: text,
        );
      }

      setState(() => _replyToUsername = null);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Izohlar'),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snap.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.muted,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Birinchi izoh qoldiring',
                          style: AppTheme.titleStyle,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Fikrlaringizni baham ko\'ring',
                          style: TextStyle(color: AppTheme.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, i) {
                    final data = comments[i].data() as Map<String, dynamic>;
                    return _CommentTile(
                      data: data,
                      commentId: comments[i].id,
                      postId: widget.postId,
                      onReply: (username) {
                        setState(() => _replyToUsername = username);
                        _controller.text = '@$username ';
                        _focusNode.requestFocus();
                      },
                    );
                  },
                );
              },
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              children: [
                if (_replyToUsername != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppTheme.surfaceMuted,
                    child: Row(
                      children: [
                        Text(
                          '@$_replyToUsername ga javob',
                          style: AppTheme.captionStyle,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() => _replyToUsername = null);
                            _controller.clear();
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.muted,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        photoUrl:
                            FirebaseAuth.instance.currentUser?.photoURL ?? '',
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          style: AppTheme.bodyStyle,
                          maxLines: null,
                          decoration: const InputDecoration(
                            hintText: 'Izoh qo\'shing...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendComment,
                        child: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Yuborish',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
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

class _CommentTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final String commentId;
  final String postId;
  final void Function(String username) onReply;

  const _CommentTile({
    required this.data,
    required this.commentId,
    required this.postId,
    required this.onReply,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likedBy = List<String>.from(widget.data['likedBy'] ?? []);
    _isLiked = likedBy.contains(myUid);
    _likesCount = widget.data['likesCount'] ?? 0;
  }

  Future<void> _toggleLike() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId);

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    if (_isLiked) {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([myUid]),
        'likesCount': FieldValue.increment(1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([myUid]),
        'likesCount': FieldValue.increment(-1),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.data['username'] as String? ?? '';
    final photoUrl = widget.data['userPhotoUrl'] as String? ?? '';
    final text = widget.data['text'] as String? ?? '';
    final ts = widget.data['createdAt'] as Timestamp?;
    final createdAt = ts?.toDate() ?? DateTime.now();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = widget.data['uid'] == myUid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(photoUrl: photoUrl, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '$username ', style: AppTheme.labelStyle),
                      TextSpan(text: text, style: AppTheme.bodyStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_formatTime(createdAt), style: AppTheme.captionStyle),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => widget.onReply(username),
                      child: const Text(
                        'Javob',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _deleteComment,
                        child: const Text(
                          'O\'chirish',
                          style: AppTheme.captionStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLike,
            child: Column(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? AppTheme.accent : AppTheme.muted,
                  size: 16,
                ),
                if (_likesCount > 0)
                  Text(
                    '$_likesCount',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment() async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(widget.commentId)
        .delete();
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'commentsCount': FieldValue.increment(-1)});
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}son';
    if (diff.inMinutes < 60) return '${diff.inMinutes}daq';
    if (diff.inHours < 24) return '${diff.inHours}soat';
    if (diff.inDays < 7) return '${diff.inDays}kun';
    return '${dt.day}.${dt.month}';
  }
}
