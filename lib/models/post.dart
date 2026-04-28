import 'user.dart';

class Post {
  final String id;
  final User user;
  final List<String> imageUrls;
  final String caption;
  int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  bool isLiked;
  bool isSaved;
  final String? location;

  Post({
    required this.id,
    required this.user,
    required this.imageUrls,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.isLiked = false,
    this.isSaved = false,
    this.location,
  });
}
