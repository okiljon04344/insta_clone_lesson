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

  // Kuzatish
  Future<void> follow(String targetUid) async {
    final batch = _db.batch();
    // Bildirishnoma yuborish (await kerak emas)
    unawaited(NotificationService().sendFollowNotification(targetUid));

    // Men kuzatmoqdaman: myFollowing += targetUid
    batch.set(
      _db
          .collection('users')
          .doc(_myUid)
          .collection('following')
          .doc(targetUid),
      {'uid': targetUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    // Target menga ega: targetFollowers += myUid
    batch.set(
      _db
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(_myUid),
      {'uid': _myUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    // Sanalarni yangilash
    batch.update(_db.collection('users').doc(_myUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Kuzatishni to'xtatish
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

  // Kuzatyapmanmi?
  Future<bool> isFollowing(String targetUid) async {
    final doc = await _db
        .collection('users')
        .doc(_myUid)
        .collection('following')
        .doc(targetUid)
        .get();
    return doc.exists;
  }

  // Real-time stream
  Stream<bool> isFollowingStream(String targetUid) {
    return _db
        .collection('users')
        .doc(_myUid)
        .collection('following')
        .doc(targetUid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Kuzatuvchilar ro'yxati
  Stream<List<String>> followersStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toList());
  }

  // Kuzatilayotganlar ro'yxati
  Stream<List<String>> followingStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toList());
  }
}
