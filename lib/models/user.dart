class User {
  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isVerified;

  const User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.bio,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.isVerified = false,
  });
}
