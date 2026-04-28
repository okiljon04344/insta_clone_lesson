import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran ochilib ko'rildi — hammasi o'qildi
    NotificationService().markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Text(
          context.tr('notifications_title'),
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService().notificationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            );
          }

          final notifications = snap.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.notifications_none,
                    color: AppTheme.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('notifications_empty_title'),
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('notifications_empty_subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Guruhlashtirish: Bugun / Bu hafta / Kechagi
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final notif = notifications[i];
              return _NotificationTile(notification: notif);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Container(
      color: isUnread
          ? AppTheme.blue.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        onTap: () => _openNotifierProfile(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.darkGrey,
              backgroundImage: notification.fromPhotoUrl.isNotEmpty
                  ? NetworkImage(notification.fromPhotoUrl)
                  : null,
              child: notification.fromPhotoUrl.isEmpty
                  ? const Icon(Icons.person, color: AppTheme.grey)
                  : null,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _iconColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.black, width: 2),
                ),
                child: Icon(_iconData, color: Colors.white, size: 11),
              ),
            ),
          ],
        ),
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: notification.fromUsername,
                style: const TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: _actionText(context),
                style: const TextStyle(color: AppTheme.white, fontSize: 13),
              ),
              if (notification.text != null) ...[
                const TextSpan(text: ': '),
                TextSpan(
                  text: '"${notification.text}"',
                  style: const TextStyle(color: AppTheme.grey, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _formatTime(notification.createdAt),
            style: const TextStyle(color: AppTheme.grey, fontSize: 11),
          ),
        ),
        trailing: notification.postImageUrl?.isNotEmpty == true
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _buildPostImage(notification.postImageUrl!),
              )
            : notification.type == NotificationType.follow
            ? _FollowBackButton(uid: notification.fromUid)
            : null,
      ),
    );
  }

  Future<void> _openNotifierProfile(BuildContext context) async {
    final uid = notification.fromUid;
    if (uid.isEmpty) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!context.mounted || !snap.exists) return;

    final user = UserModel.fromMap(snap.data()!);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(user: user, isCurrentUser: user.uid == myUid),
      ),
    );
  }

  String _actionText(BuildContext context) {
    switch (notification.type) {
      case NotificationType.like:
        return context.tr('notif_like');
      case NotificationType.comment:
        return context.tr('notif_comment');
      case NotificationType.follow:
        return context.tr('notif_follow');
      case NotificationType.mention:
        return context.tr('notif_mention');
      case NotificationType.message:
        return context.tr('notif_message');
      case NotificationType.call:
        return context.tr('notif_call');
      case NotificationType.missedCall:
        return context.tr('notif_missed_call');
    }
  }

  IconData get _iconData {
    switch (notification.type) {
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.chat_bubble;
      case NotificationType.follow:
        return Icons.person;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.message:
        return Icons.send;
      case NotificationType.call:
        return Icons.call;
      case NotificationType.missedCall:
        return Icons.call_missed;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.like:
        return AppTheme.red;
      case NotificationType.comment:
        return AppTheme.blue;
      case NotificationType.follow:
        return Colors.purple;
      case NotificationType.mention:
        return Colors.orange;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.call:
        return AppTheme.blue;
      case NotificationType.missedCall:
        return AppTheme.red;
    }
  }

  Widget _buildPostImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover);
      } catch (_) {
        return Container(color: AppTheme.darkGrey, width: 44, height: 44);
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 44,
      height: 44,
      fit: BoxFit.cover,
      placeholder: (_, _) =>
          Container(color: AppTheme.darkGrey, width: 44, height: 44),
      errorWidget: (_, _, _) =>
          Container(color: AppTheme.darkGrey, width: 44, height: 44),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} son';
    if (diff.inMinutes < 60) return '${diff.inMinutes} daq';
    if (diff.inHours < 24) return '${diff.inHours} soat';
    if (diff.inDays < 7) return '${diff.inDays} kun';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _FollowBackButton extends StatefulWidget {
  final String uid;

  const _FollowBackButton({required this.uid});

  @override
  State<_FollowBackButton> createState() => _FollowBackButtonState();
}

class _FollowBackButtonState extends State<_FollowBackButton> {
  bool _isFollowing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('following')
        .doc(widget.uid)
        .get();
    if (mounted) {
      setState(() {
        _isFollowing = doc.exists;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _isFollowing ? AppTheme.darkGrey : AppTheme.blue,
          borderRadius: BorderRadius.circular(8),
          border: _isFollowing ? Border.all(color: AppTheme.divider) : null,
        ),
        child: _loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppTheme.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _isFollowing
                    ? context.tr('following_state')
                    : context.tr('follow_back'),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _toggle() async {
    setState(() => _loading = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      if (_isFollowing) {
        batch.delete(
          db
              .collection('users')
              .doc(myUid)
              .collection('following')
              .doc(widget.uid),
        );
        batch.delete(
          db
              .collection('users')
              .doc(widget.uid)
              .collection('followers')
              .doc(myUid),
        );
        batch.update(db.collection('users').doc(myUid), {
          'followingCount': FieldValue.increment(-1),
        });
        batch.update(db.collection('users').doc(widget.uid), {
          'followersCount': FieldValue.increment(-1),
        });
      } else {
        batch.set(
          db
              .collection('users')
              .doc(myUid)
              .collection('following')
              .doc(widget.uid),
          {'uid': widget.uid, 'createdAt': FieldValue.serverTimestamp()},
        );
        batch.set(
          db
              .collection('users')
              .doc(widget.uid)
              .collection('followers')
              .doc(myUid),
          {'uid': myUid, 'createdAt': FieldValue.serverTimestamp()},
        );
        batch.update(db.collection('users').doc(myUid), {
          'followingCount': FieldValue.increment(1),
        });
        batch.update(db.collection('users').doc(widget.uid), {
          'followersCount': FieldValue.increment(1),
        });
      }
      await batch.commit();
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
