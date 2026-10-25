import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class FollowService {
  static final FollowService _instance = FollowService._internal();
  factory FollowService() => _instance;
  FollowService._internal();

  final _db = FirebaseFirestore.instance;
  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> follow(String targetUid) async {
    final batch = _db.batch();
    unawaited(NotificationService().sendFollowNotification(targetUid));

    batch.set(
      _db
          .collection('users')
          .doc(_myUid)
          .collection('following')
          .doc(targetUid),
      {'uid': targetUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    batch.set(
      _db
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(_myUid),
      {'uid': _myUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    batch.update(_db.collection('users').doc(_myUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> unfollow(String targetUid) async {
    final batch = _db.batch();

    batch.delete(
      _db
          .collection('users')
          .doc(_myUid)
          .collection('following')
          .doc(targetUid),
    );
    batch.delete(
      _db
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(_myUid),
    );

    batch.update(_db.collection('users').doc(_myUid), {
      'followingCount': FieldValue.increment(-1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  Stream<bool> isFollowingStream(String targetUid) {
    return _db
        .collection('users')
        .doc(_myUid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
