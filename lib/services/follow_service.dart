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

  // Follow
  Future<void> follow(String targetUid) async {
    final batch = _db.batch();
    // Send a notification (no need to await)
    unawaited(NotificationService().sendFollowNotification(targetUid));

    // I am following: myFollowing += targetUid
    batch.set(
      _db
          .collection('users')
          .doc(_myUid)
          .collection('following')
          .doc(targetUid),
      {'uid': targetUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    // Target gains a follower: targetFollowers += myUid
    batch.set(
      _db
          .collection('users')
          .doc(targetUid)
          .collection('followers')
          .doc(_myUid),
      {'uid': _myUid, 'createdAt': FieldValue.serverTimestamp()},
    );

    // Update the counters
    batch.update(_db.collection('users').doc(_myUid), {
      'followingCount': FieldValue.increment(1),
    });
    batch.update(_db.collection('users').doc(targetUid), {
      'followersCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Unfollow
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

  // Am I following?
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

  // Followers list
  Stream<List<String>> followersStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toList());
  }

  // Following list
  Stream<List<String>> followingStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('following')
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toList());
  }
}
