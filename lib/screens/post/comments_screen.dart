import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

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

      // Foydalanuvchi ma'lumotlari
      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Izoh qo'shish
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

      // commentsCount oshirish
      await db.collection('posts').doc(widget.postId).update({
        'commentsCount': FieldValue.increment(1),
      });

      // Bildirishnoma yuborish (o'ziga emas)
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
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text(
          'Izohlar',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.divider, height: 0.5),
        ),
      ),
      body: Column(
        children: [
          // Izohlar ro'yxati
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
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.blue),
                  );
                }

                final comments = snap.data?.docs ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.grey,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Birinchi izoh qoldiring',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fikrlaringizni baham ko\'ring',
                          style: TextStyle(color: AppTheme.grey, fontSize: 13),
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

          // Izoh yozish
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.black,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Column(
              children: [
                if (_replyToUsername != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: AppTheme.darkGrey,
                    child: Row(
                      children: [
                        Text(
                          '@$_replyToUsername ga javob',
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() => _replyToUsername = null);
                            _controller.clear();
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppTheme.grey,
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
                      _CurrentUserAvatar(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.darkGrey,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 14,
                            ),
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Izoh qo\'shing...',
                              hintStyle: TextStyle(color: AppTheme.grey),
                              border: InputBorder.none,
                            ),
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
                                  color: AppTheme.blue,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Yuborish',
                                style: TextStyle(
                                  color: AppTheme.blue,
                                  fontWeight: FontWeight.bold,
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

class _CurrentUserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.darkGrey,
      backgroundImage: (user?.photoURL?.isNotEmpty == true)
          ? NetworkImage(user!.photoURL!)
          : null,
      child: (user?.photoURL?.isNotEmpty != true)
          ? const Icon(Icons.person, color: AppTheme.grey, size: 16)
          : null,
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
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.darkGrey,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? const Icon(Icons.person, color: AppTheme.grey, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$username ',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: text,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTime(createdAt),
                      style: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => widget.onReply(username),
                      child: const Text(
                        'Javob',
                        style: TextStyle(
                          color: AppTheme.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _deleteComment,
                        child: const Text(
                          'O\'chirish',
                          style: TextStyle(color: AppTheme.grey, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Like
          GestureDetector(
            onTap: _toggleLike,
            child: Column(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? AppTheme.red : AppTheme.grey,
                  size: 14,
                ),
                if (_likesCount > 0)
                  Text(
                    '$_likesCount',
                    style: const TextStyle(color: AppTheme.grey, fontSize: 10),
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
