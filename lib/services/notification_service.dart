import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum NotificationType {
  like,
  comment,
  follow,
  mention,
  message,
  call,
  missedCall,
}

class AppNotification {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String fromPhotoUrl;
  final NotificationType type;
  final String? postId;
  final String? postImageUrl;
  final String? text;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.fromPhotoUrl,
    required this.type,
    this.postId,
    this.postImageUrl,
    this.text,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      fromUid: map['fromUid'] ?? '',
      fromUsername: map['fromUsername'] ?? '',
      fromPhotoUrl: map['fromPhotoUrl'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'like'),
        orElse: () => NotificationType.like,
      ),
      postId: map['postId'],
      postImageUrl: map['postImageUrl'],
      text: map['text'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _db = FirebaseFirestore.instance;
  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _send({
    required String toUid,
    required NotificationType type,
    String? postId,
    String? postImageUrl,
    String? text,
  }) async {
    if (toUid == _myUid) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await _db.collection('users').doc(_myUid).get();
    final userData = userDoc.data() ?? {};

    await _db.collection('notifications').doc(toUid).collection('items').add({
      'fromUid': _myUid,
      'fromUsername': userData['username'] ?? user.displayName ?? '',
      'fromPhotoUrl': userData['photoUrl'] ?? user.photoURL ?? '',
      'type': type.name,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'text': text,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendLikeNotification({
    required String toUid,
    required String postId,
    required String postImageUrl,
  }) => _send(
    toUid: toUid,
    type: NotificationType.like,
    postId: postId,
    postImageUrl: postImageUrl,
  );

  Future<void> sendCommentNotification({
    required String toUid,
    required String postId,
    required String postImageUrl,
    required String comment,
  }) => _send(
    toUid: toUid,
    type: NotificationType.comment,
    postId: postId,
    postImageUrl: postImageUrl,
    text: comment,
  );

  Future<void> sendFollowNotification(String toUid) =>
      _send(toUid: toUid, type: NotificationType.follow);

  Future<void> sendMessageNotification({
    required String toUid,
    required String messageText,
  }) => _send(toUid: toUid, type: NotificationType.message, text: messageText);

  Future<void> sendCallNotification({
    required String toUid,
    required bool isVideo,
  }) => _send(
    toUid: toUid,
    type: NotificationType.call,
    text: isVideo ? 'Video qo\'ng\'iroq' : 'Ovozli qo\'ng\'iroq',
  );

  Future<void> sendMissedCallNotification({
    required String toUid,
    required bool isVideo,
  }) => _send(
    toUid: toUid,
    type: NotificationType.missedCall,
    text: isVideo
        ? 'O\'tkazib yuborilgan video qo\'ng\'iroq'
        : 'O\'tkazib yuborilgan qo\'ng\'iroq',
  );

  Stream<List<AppNotification>> notificationsStream() {
    return _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (q) => q.docs
              .map((d) => AppNotification.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<int> unreadCountStream() {
    return _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((q) => q.docs.length);
  }

  Future<void> markAllRead() async {
    final batch = _db.batch();
    final snap = await _db
        .collection('notifications')
        .doc(_myUid)
        .collection('items')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
