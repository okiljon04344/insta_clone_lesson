import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';
import 'post_image.dart';
import '../services/notification_service.dart';
import '../screens/post/comments_screen.dart';
import '../screens/profile/profile_screen.dart';

class FirestorePostCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String postId;

  const FirestorePostCard({
    super.key,
    required this.data,
    required this.postId,
  });

  @override
  State<FirestorePostCard> createState() => _FirestorePostCardState();
}

class _FirestorePostCardState extends State<FirestorePostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  bool _isLiked = false;
  bool _isBookmarked = false;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likedBy = List<String>.from(widget.data['likedBy'] ?? []);
    _isLiked = likedBy.contains(uid);
    _likesCount = widget.data['likesCount'] ?? 0;
    _loadBookmark();

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FirestorePostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likedBy = List<String>.from(widget.data['likedBy'] ?? []);
    _isLiked = likedBy.contains(uid);
    _likesCount = widget.data['likesCount'] ?? _likesCount;
  }

  Future<void> _loadBookmark() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved')
        .doc(widget.postId)
        .get();
    if (mounted) setState(() => _isBookmarked = doc.exists);
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final postOwnerId = widget.data['uid'] as String? ?? '';
    final db = FirebaseFirestore.instance;
    final ref = db.collection('posts').doc(widget.postId);
    final wasLiked = _isLiked;
    final previousLikesCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await ref.update({
          'likedBy': FieldValue.arrayUnion([uid]),
          'likesCount': FieldValue.increment(1),
        });
        if (postOwnerId.isNotEmpty && postOwnerId != uid) {
          await NotificationService().sendLikeNotification(
            toUid: postOwnerId,
            postId: widget.postId,
            postImageUrl: '',
          );
        }
      } else {
        await ref.update({
          'likedBy': FieldValue.arrayRemove([uid]),
          'likesCount': FieldValue.increment(-1),
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likesCount = previousLikesCount;
      });
      showAppSnackBar(
        context,
        'Like saqlanmadi. Qayta urinib ko\'ring.',
        isError: true,
      );
    }
  }

  Future<void> _toggleBookmark() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved')
        .doc(widget.postId);
    final wasBookmarked = _isBookmarked;

    setState(() => _isBookmarked = !_isBookmarked);

    try {
      if (_isBookmarked) {
        await ref.set({
          'postId': widget.postId,
          'postOwnerId': widget.data['uid'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await ref.delete();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBookmarked = wasBookmarked);
      showAppSnackBar(context, 'Saqlash holati yangilanmadi.', isError: true);
    }
  }

  Future<void> _doubleTapLike() async {
    if (!_isLiked) await _toggleLike();
    if (!mounted) return;
    setState(() => _showHeart = true);
    _heartController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showHeart = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final caption = data['caption'] as String? ?? '';
    final username = data['username'] as String? ?? '';
    final userPhotoUrl = data['userPhotoUrl'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final postOwnerId = data['uid'] as String? ?? '';
    final commentsCount = data['commentsCount'] as int? ?? 0;
    final timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = postOwnerId == myUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openAuthorProfile,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.surfaceMuted,
                  backgroundImage: userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: AppTheme.muted,
                          size: 18,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openAuthorProfile,
                          child: Text(username, style: AppTheme.labelStyle),
                        ),
                      ],
                    ),
                    if (location.isNotEmpty)
                      Text(location, style: AppTheme.captionStyle),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showMoreOptions(context, isOwner),
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
        ),

        GestureDetector(
          onDoubleTap: _doubleTapLike,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: imageUrls.isNotEmpty
                    ? PostImage(url: imageUrls.first)
                    : Container(color: AppTheme.surfaceMuted),
              ),
              if (_showHeart)
                AnimatedBuilder(
                  animation: _heartAnimation,
                  builder: (_, _) => Transform.scale(
                    scale: _heartAnimation.value,
                    child: const Icon(
                      Icons.favorite,
                      color: AppTheme.onAccent,
                      size: 90,
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? AppTheme.accent : AppTheme.ink,
                ),
              ),
              IconButton(
                onPressed: () => _openComments(context, '', postOwnerId),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.send_outlined),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleBookmark,
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? AppTheme.accent : AppTheme.ink,
                ),
              ),
            ],
          ),
        ),

        if (_likesCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_likesCount ta like', style: AppTheme.labelStyle),
          ),

        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$username ', style: AppTheme.labelStyle),
                  TextSpan(text: caption, style: AppTheme.bodyStyle),
                ],
              ),
            ),
          ),

        if (commentsCount > 0)
          GestureDetector(
            onTap: () => _openComments(context, '', postOwnerId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(
                '$commentsCount ta izohni ko\'rish',
                style: const TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(timeago.format(createdAt), style: AppTheme.captionStyle),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _openComments(
    BuildContext context,
    String imageUrl,
    String postOwnerId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommentsScreen(
          postId: widget.postId,
          postOwnerId: postOwnerId,
          postImageUrl: imageUrl,
        ),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, bool isOwner) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.danger,
                ),
                title: const Text(
                  'Postni o\'chirish',
                  style: TextStyle(color: AppTheme.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Havolani nusxalash'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Shikoyat qilish'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAuthorProfile() async {
    final uid = widget.data['uid'] as String? ?? '';
    if (uid.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted || !snap.exists) return;

      final user = UserModel.fromMap(snap.data()!);
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileScreen(user: user, isCurrentUser: user.uid == myUid),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, 'Profilni ochib bo\'lmadi', isError: true);
    }
  }

  Future<void> _deletePost() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = FirebaseFirestore.instance;
    await db.collection('posts').doc(widget.postId).delete();
    await db.collection('users').doc(myUid).update({
      'postsCount': FieldValue.increment(-1),
    });
  }
}
