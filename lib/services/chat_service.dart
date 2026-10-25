import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'notification_service.dart';
import 'supabase_storage_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final String type; // 'text' | 'image'
  final bool seen;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.type,
    this.seen = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: map['type'] ?? 'text',
      seen: map['seen'] ?? false,
    );
  }
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _db = FirebaseFirestore.instance;
  String get _myUid => FirebaseAuth.instance.currentUser!.uid;

  String chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendMessage(String toUid, String text) async {
    final cid = chatId(_myUid, toUid);
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch();

    final msgRef = _db
        .collection('chats')
        .doc(cid)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'senderId': _myUid,
      'text': text,
      'type': 'text',
      'seen': false,
      'createdAt': now,
    });

    batch.set(_db.collection('chats').doc(cid), {
      'participants': [_myUid, toUid],
      'lastMessage': text,
      'lastMessageAt': now,
      'lastSenderId': _myUid,
      'seenBy': [_myUid],
    }, SetOptions(merge: true));

    await batch.commit();

    // Fire-and-forget: a failed notification must not fail the send.
    NotificationService()
        .sendMessageNotification(toUid: toUid, messageText: text)
        .catchError((_) {});
  }

  Future<void> sendImageMessage(String toUid, XFile image) async {
    final cid = chatId(_myUid, toUid);
    final now = FieldValue.serverTimestamp();
    final msgRef = _db
        .collection('chats')
        .doc(cid)
        .collection('messages')
        .doc();

    final imageUrl = await SupabaseStorageService().uploadChatImage(
      chatId: cid,
      messageId: msgRef.id,
      image: image,
    );

    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': _myUid,
      'text': imageUrl,
      'type': 'image',
      'seen': false,
      'createdAt': now,
    });
    batch.set(_db.collection('chats').doc(cid), {
      'participants': [_myUid, toUid],
      'lastMessage': 'Rasm',
      'lastMessageAt': now,
      'lastSenderId': _myUid,
      'seenBy': [_myUid],
    }, SetOptions(merge: true));

    await batch.commit();
    NotificationService()
        .sendMessageNotification(toUid: toUid, messageText: 'Rasm')
        .catchError((_) {});
  }

  Stream<List<ChatMessage>> messagesStream(String toUid) {
    final cid = chatId(_myUid, toUid);
    return _db
        .collection('chats')
        .doc(cid)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (q) =>
              q.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Marks the chat as seen and flags the other user's unread messages.
  Future<void> markSeen(String toUid) async {
    final cid = chatId(_myUid, toUid);

    await _db
        .collection('chats')
        .doc(cid)
        .update({
          'seenBy': FieldValue.arrayUnion([_myUid]),
        })
        .catchError((_) {});

    final unseen = await _db
        .collection('chats')
        .doc(cid)
        .collection('messages')
        .where('seen', isEqualTo: false)
        .limit(50)
        .get();

    if (unseen.docs.isNotEmpty) {
      final batch = _db.batch();
      var hasUpdates = false;
      for (final doc in unseen.docs) {
        if (doc.data()['senderId'] == _myUid) continue;
        batch.update(doc.reference, {'seen': true});
        hasUpdates = true;
      }
      if (hasUpdates) {
        await batch.commit();
      }
    }
  }

  Future<void> setTyping(String toUid, bool isTyping) async {
    final cid = chatId(_myUid, toUid);
    await _db
        .collection('chats')
        .doc(cid)
        .set({
          'typing': {_myUid: isTyping},
        }, SetOptions(merge: true))
        .catchError((_) {});
  }

  Stream<bool> typingStream(String otherUid) {
    final cid = chatId(_myUid, otherUid);
    return _db.collection('chats').doc(cid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return false;
      final typing = data['typing'] as Map<String, dynamic>?;
      return typing?[otherUid] == true;
    });
  }

  Future<void> setOnline(bool isOnline) async {
    await _db
        .collection('users')
        .doc(_myUid)
        .update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        })
        .catchError((_) {});
  }

  Stream<Map<String, dynamic>> onlineStatusStream(String otherUid) {
    return _db.collection('users').doc(otherUid).snapshots().map((snap) {
      final data = snap.data() ?? {};
      return {
        'isOnline': data['isOnline'] ?? false,
        'lastSeen': (data['lastSeen'] as Timestamp?)?.toDate(),
      };
    });
  }

  Stream<List<Map<String, dynamic>>> conversationsStream() {
    return _db
        .collection('chats')
        .where('participants', arrayContains: _myUid)
        .snapshots()
        .map((q) {
          final docs = q.docs.map((d) {
            final data = d.data();
            data['chatId'] = d.id;
            return data;
          }).toList();
          // Sorted in memory to avoid needing a composite index.
          docs.sort((a, b) {
            final aAt =
                (a['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bAt =
                (b['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bAt.compareTo(aAt);
          });
          return docs;
        });
  }
}
