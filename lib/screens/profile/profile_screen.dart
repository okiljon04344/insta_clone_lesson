import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/follow_service.dart';
import '../../widgets/post_image.dart';
import '../chat/chat_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_posts_screen.dart';
import 'follow_list_screen.dart';
import 'language_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  final bool isCurrentUser;

  const ProfileScreen({
    super.key,
    required this.user,
    this.isCurrentUser = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _followService = FollowService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.user.username, style: AppTheme.titleStyle),
            if (widget.user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: AppTheme.accent, size: 16),
            ],
          ],
        ),
        actions: widget.isCurrentUser
            ? [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_box_outlined),
                ),
                IconButton(
                  onPressed: () => _showMenuSheet(),
                  icon: const Icon(Icons.menu),
                ),
              ]
            : [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: widget.user.photoUrl.isNotEmpty
                                      ? widget.user.photoUrl
                                      : 'https://ui-avatars.com/api/?name=${widget.user.displayName}&background=f5f5f4&color=1c1917',
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      Container(color: AppTheme.surfaceMuted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(widget.user.uid)
                                  .snapshots(),
                              builder: (ctx, snap) {
                                int posts = widget.user.postsCount;
                                int followers = widget.user.followersCount;
                                int following = widget.user.followingCount;
                                if (snap.hasData && snap.data!.exists) {
                                  final d =
                                      snap.data!.data() as Map<String, dynamic>;
                                  posts = d['postsCount'] ?? posts;
                                  followers = d['followersCount'] ?? followers;
                                  following = d['followingCount'] ?? following;
                                }
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _statColumn(
                                      _formatCount(posts),
                                      context.tr('posts'),
                                    ),
                                    _statColumn(
                                      _formatCount(followers),
                                      context.tr('followers'),
                                      onTap: () => _openFollowList(
                                        FollowListType.followers,
                                      ),
                                    ),
                                    _statColumn(
                                      _formatCount(following),
                                      context.tr('following'),
                                      onTap: () => _openFollowList(
                                        FollowListType.following,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(widget.user.displayName, style: AppTheme.labelStyle),
                      const SizedBox(height: 4),
                      Text(widget.user.bio, style: AppTheme.bodyStyle),
                      const SizedBox(height: 12),
                      widget.isCurrentUser
                          ? Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    context.tr('edit_profile'),
                                    onTap: () async {
                                      final updated =
                                          await Navigator.push<UserModel>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditProfileScreen(
                                                user: widget.user,
                                              ),
                                            ),
                                          );
                                      if (updated != null && mounted) {
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _actionButton(
                                    context.tr('share_profile'),
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _actionButton(
                                  '',
                                  icon: Icons.person_add_outlined,
                                  onTap: () {},
                                ),
                              ],
                            )
                          : StreamBuilder<bool>(
                              stream: _followService.isFollowingStream(
                                widget.user.uid,
                              ),
                              builder: (ctx, snap) {
                                final isFollowing = snap.data ?? false;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: _actionButton(
                                        isFollowing
                                            ? context.tr('following_state')
                                            : context.tr('follow'),
                                        color: isFollowing
                                            ? null
                                            : AppTheme.accent,
                                        onTap: () async {
                                          if (isFollowing) {
                                            await _followService.unfollow(
                                              widget.user.uid,
                                            );
                                          } else {
                                            await _followService.follow(
                                              widget.user.uid,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _actionButton(
                                        context.tr('message'),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              otherUser: widget.user,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _actionButton(
                                      '',
                                      icon: Icons.keyboard_arrow_down,
                                      onTap: () {},
                                    ),
                                  ],
                                );
                              },
                            ),
                    ],
                  ),
                ),
                // Highlights are placeholders for now.
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (_, i) => Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl:
                                  'https://picsum.photos/seed/highlight${widget.user.uid}$i/100/100',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            'Sayohat',
                            'Oziq-ovqat',
                            'Ish',
                            'Sport',
                            'Do\'stlar',
                          ][i],
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on, size: 22)),
                    Tab(icon: Icon(Icons.person_pin_outlined, size: 22)),
                  ],
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsGrid(),
            GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 6,
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl:
                    'https://picsum.photos/seed/tagged${widget.user.uid}$i/300/300',
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppTheme.surfaceMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.user.uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = [...(snap.data?.docs ?? [])];
        posts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aAt =
              (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bAt =
              (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bAt.compareTo(aAt);
        });
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.grid_on, color: AppTheme.muted, size: 40),
                SizedBox(height: 12),
                Text('Hali postlar yo\'q', style: AppTheme.titleStyle),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(1),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final data = posts[i].data() as Map<String, dynamic>;
            final imageUrls = List<String>.from(data['imageUrls'] ?? []);
            final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
            return GestureDetector(
              onTap: () {},
              child: PostImage(url: imageUrl),
            );
          },
        );
      },
    );
  }

  Widget _statColumn(String value, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: AppTheme.titleStyle),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.captionStyle),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label, {
    IconData? icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        decoration: BoxDecoration(
          color: color ?? AppTheme.background,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: color == null ? Border.all(color: AppTheme.border) : null,
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, color: AppTheme.ink, size: 20)
            : Text(
                label,
                style: TextStyle(
                  color: color == null ? AppTheme.ink : AppTheme.onAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _menuItem(
            Icons.settings_outlined,
            context.tr('settings'),
            onTap: () => Navigator.pop(context),
          ),
          _menuItem(
            Icons.bookmark_border,
            context.tr('saved'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedPostsScreen()),
              );
            },
          ),
          _menuItem(
            Icons.language,
            context.tr('language_settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),
          _menuItem(
            Icons.archive_outlined,
            'Arxiv',
            onTap: () => Navigator.pop(context),
          ),
          _menuItem(
            Icons.qr_code,
            'QR kod',
            onTap: () => Navigator.pop(context),
          ),
          _menuItem(
            Icons.bar_chart,
            'Statistika',
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          _menuItem(
            Icons.logout,
            context.tr('logout'),
            color: AppTheme.danger,
            onTap: () async {
              Navigator.pop(context);
              await AuthService().signOut();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.ink),
      title: Text(
        label,
        style: TextStyle(color: color ?? AppTheme.ink, fontSize: 15),
      ),
      onTap: onTap,
    );
  }

  void _openFollowList(FollowListType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListScreen(
          userId: widget.user.uid,
          username: widget.user.username,
          initialType: type,
        ),
      ),
    );
  }
}
