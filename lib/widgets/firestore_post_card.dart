import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../theme/app_theme.dart';
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

  Widget _buildImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        return Container(color: AppTheme.darkGrey);
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppTheme.darkGrey),
      errorWidget: (_, _, _) => Container(color: AppTheme.darkGrey),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Like saqlanmadi. Qayta urinib ko\'ring.'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Saqlash holati yangilanmadi.'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _doubleTapLike() async {
    if (!_isLiked) await _toggleLike();
    _showHeart = true;
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
    final userDisplayName = data['userDisplayName'] as String? ?? '';
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
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: _openAuthorProfile,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.darkGrey,
                  backgroundImage: userPhotoUrl.isNotEmpty
                      ? NetworkImage(userPhotoUrl)
                      : null,
                  child: userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.grey, size: 18)
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
                          child: Text(
                            username,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (userDisplayName.isNotEmpty)
                          Text(
                            '• Kuzatilmoqda',
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showMoreOptions(context, isOwner),
                icon: const Icon(Icons.more_vert, color: AppTheme.white),
              ),
            ],
          ),
        ),

        // Image
        GestureDetector(
          onDoubleTap: _doubleTapLike,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: imageUrls.isNotEmpty
                    ? _buildImage(imageUrls.first)
                    : Container(color: AppTheme.darkGrey),
              ),
              if (_showHeart)
                AnimatedBuilder(
                  animation: _heartAnimation,
                  builder: (_, _) => Transform.scale(
                    scale: _heartAnimation.value,
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 90,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? AppTheme.red : AppTheme.white,
                  size: 26,
                ),
              ),
              IconButton(
                onPressed: () => _openComments(context, '', postOwnerId),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.send_outlined,
                  color: AppTheme.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleBookmark,
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: AppTheme.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),

        // Likes
        if (_likesCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_likesCount ta like',
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

        // Caption
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: RichText(
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
                    text: caption,
                    style: const TextStyle(color: AppTheme.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

        // Izohlar soni
        if (commentsCount > 0)
          GestureDetector(
            onTap: () => _openComments(context, '', postOwnerId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Text(
                '$commentsCount ta izohni ko\'rish',
                style: const TextStyle(color: AppTheme.grey, fontSize: 13),
              ),
            ),
          ),

        // Time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            timeago.format(createdAt),
            style: const TextStyle(color: AppTheme.grey, fontSize: 11),
          ),
        ),
        const SizedBox(height: 4),
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
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.red),
                title: const Text(
                  'Postni o\'chirish',
                  style: TextStyle(color: AppTheme.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined, color: AppTheme.white),
              title: const Text(
                'Havolani nusxalash',
                style: TextStyle(color: AppTheme.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppTheme.white),
              title: const Text(
                'Shikoyat qilish',
                style: TextStyle(color: AppTheme.white),
              ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profilni ochib bo\'lmadi'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
