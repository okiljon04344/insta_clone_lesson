import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instagram_clone/models/user_model.dart';

void main() {
  test('UserModel maps Firestore data without losing counters', () {
    final createdAt = DateTime(2026, 4, 28, 10, 30);
    final user = UserModel.fromMap({
      'uid': 'u1',
      'email': 'user@example.com',
      'username': 'photofan',
      'displayName': 'Photo Fan',
      'photoUrl': 'https://example.com/avatar.jpg',
      'bio': 'Sharing moments',
      'phoneNumber': '+998901234567',
      'postsCount': 7,
      'followersCount': 42,
      'followingCount': 11,
      'isVerified': true,
      'createdAt': Timestamp.fromDate(createdAt),
    });

    expect(user.uid, 'u1');
    expect(user.username, 'photofan');
    expect(user.postsCount, 7);
    expect(user.followersCount, 42);
    expect(user.followingCount, 11);
    expect(user.isVerified, isTrue);
    expect(user.toMap()['createdAt'], isA<Timestamp>());
  });
}
