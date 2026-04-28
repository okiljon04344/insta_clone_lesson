import 'user.dart';

class Story {
  final String id;
  final User user;
  final bool isSeen;
  final bool isOwn;

  const Story({
    required this.id,
    required this.user,
    this.isSeen = false,
    this.isOwn = false,
  });
}
