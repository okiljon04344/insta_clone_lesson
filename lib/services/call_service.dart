import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

enum CallStatus { calling, accepted, declined, ended, missed }

class CallInfo {
  final String id;
  final String fromUid;
  final String toUid;
  final bool isVideo;
  final CallStatus status;
  final DateTime createdAt;
  final String callerUsername;
  final String callerDisplayName;
  final String callerPhotoUrl;

  CallInfo({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.isVideo,
    required this.status,
    required this.createdAt,
    this.callerUsername = '',
    this.callerDisplayName = '',
    this.callerPhotoUrl = '',
  });

  factory CallInfo.fromMap(Map<String, dynamic> map, String id) {
    final statusStr = map['status'] as String? ?? 'ended';
    final status = CallStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => CallStatus.ended,
    );
    return CallInfo(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      isVideo: map['isVideo'] as bool? ?? false,
      status: status,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      callerUsername: map['callerUsername'] as String? ?? '',
      callerDisplayName: map['callerDisplayName'] as String? ?? '',
      callerPhotoUrl: map['callerPhotoUrl'] as String? ?? '',
    );
  }
}

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final _db = FirebaseFirestore.instance;
  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  // Qo'ng'iroq boshlash - qaytadi callId
  Future<String> initiateCall({
    required String toUid,
    required bool isVideo,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await _db.collection('users').doc(_myUid).get();
    final userData = userDoc.data() ?? {};
    final doc = _db.collection('calls').doc();
    await doc.set({
      'fromUid': _myUid,
      'toUid': toUid,
      'isVideo': isVideo,
      'status': 'calling',
      'callerUsername': userData['username'] ?? user.displayName ?? '',
      'callerDisplayName': userData['displayName'] ?? user.displayName ?? '',
      'callerPhotoUrl': userData['photoUrl'] ?? user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    NotificationService()
        .sendCallNotification(toUid: toUid, isVideo: isVideo)
        .catchError((_) {});
    return doc.id;
  }

  // Qo'ng'iroq holatini stream'lash (chaqiruvchi uchun)
  Stream<CallStatus> callStatusStream(String callId) {
    return _db.collection('calls').doc(callId).snapshots().map((d) {
      final statusStr = d.data()?['status'] as String? ?? 'ended';
      return CallStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => CallStatus.ended,
      );
    });
  }

  // Qabul qilish
  Future<void> acceptCall(String callId) async {
    await _db.collection('calls').doc(callId).update({'status': 'accepted'});
  }

  // Rad etish
  Future<void> declineCall(String callId) async {
    await _db.collection('calls').doc(callId).update({'status': 'declined'});
  }

  // Tugatish
  Future<void> endCall(String callId) async {
    await _db.collection('calls').doc(callId).update({'status': 'ended'});
  }

  // Kiruvchi qo'ng'iroqlar (mening uchun)
  Stream<CallInfo?> incomingCallStream() {
    return _db
        .collection('calls')
        .where('toUid', isEqualTo: _myUid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .map((q) {
          if (q.docs.isEmpty) return null;
          return CallInfo.fromMap(q.docs.first.data(), q.docs.first.id);
        });
  }

  // Eskirgan qo'ng'iroqlarni missed deb belgilash (30 soniyadan keyin)
  Future<void> markMissedIfOld(String callId) async {
    final doc = await _db.collection('calls').doc(callId).get();
    if (!doc.exists) return;
    final status = doc.data()?['status'] as String?;
    if (status == 'calling') {
      final createdAt = (doc.data()?['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inSeconds > 30) {
        await _db.collection('calls').doc(callId).update({'status': 'missed'});
        final toUid = doc.data()?['toUid'] as String?;
        final isVideo = doc.data()?['isVideo'] as bool? ?? false;
        if (toUid != null && toUid.isNotEmpty) {
          NotificationService()
              .sendMissedCallNotification(toUid: toUid, isVideo: isVideo)
              .catchError((_) {});
        }
      }
    }
  }
}
