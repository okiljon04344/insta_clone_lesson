import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/follow_service.dart';
import '../../models/user_model.dart';
import '../../widgets/follow_chip.dart';
import '../../widgets/post_image.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: AppTheme.bodyStyle,
            decoration: InputDecoration(
              hintText: context.tr('explore_search_users'),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.muted,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onTap: () => setState(() => _isSearching = true),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        actions: _isSearching
            ? [
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _focusNode.unfocus();
                    setState(() {
                      _isSearching = false;
                      _searchQuery = '';
                    });
                  },
                  child: Text(context.tr('cancel')),
                ),
              ]
            : null,
      ),
      body: _isSearching ? _buildSearchView() : _buildExploreGrid(),
    );
  }

  Widget _buildExploreGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(60)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snap.data?.docs ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_outlined,
                  color: AppTheme.muted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('explore_empty'),
                  style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
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

  Widget _buildSearchView() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, color: AppTheme.muted, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr('explore_enter_username'),
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
          .where(
            'username',
            isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff',
          )
          .limit(20)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        final users = docs
            .where((d) => d.id != myUid)
            .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>))
            .toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_search,
                  color: AppTheme.muted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  context
                      .tr('explore_not_found')
                      .replaceAll('{query}', _searchQuery),
                  style: AppTheme.labelStyle,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) =>
              _UserSearchTile(user: users[i], myUid: myUid),
        );
      },
    );
  }
}

class _UserSearchTile extends StatelessWidget {
  final UserModel user;
  final String myUid;

  const _UserSearchTile({required this.user, required this.myUid});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ProfileScreen(user: user, isCurrentUser: user.uid == myUid),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppTheme.surfaceMuted,
        backgroundImage: user.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        child: user.photoUrl.isEmpty
            ? const Icon(Icons.person, color: AppTheme.muted)
            : null,
      ),
      title: Row(
        children: [
          Text(user.username, style: AppTheme.labelStyle),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppTheme.accent, size: 14),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.displayName, style: AppTheme.captionStyle),
          Text(
            '${user.followersCount} ${context.tr('followers_count_suffix')}',
            style: AppTheme.captionStyle,
          ),
        ],
      ),
      trailing: StreamBuilder<bool>(
        stream: FollowService().isFollowingStream(user.uid),
        builder: (context, snap) {
          final isFollowing = snap.data ?? false;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFollowing)
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(otherUser: user),
                    ),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 20),
                ),
              _FollowButton(uid: user.uid, isFollowing: isFollowing),
            ],
          );
        },
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final String uid;
  final bool isFollowing;

  const _FollowButton({required this.uid, required this.isFollowing});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isLoading = false;

  Future<void> _toggle() async {
    setState(() => _isLoading = true);
    try {
      if (widget.isFollowing) {
        await FollowService().unfollow(widget.uid);
      } else {
        await FollowService().follow(widget.uid);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FollowChip(
      label: widget.isFollowing
          ? context.tr('following_state')
          : context.tr('follow'),
      isActive: widget.isFollowing,
      isLoading: _isLoading,
      onTap: _toggle,
    );
  }
}
