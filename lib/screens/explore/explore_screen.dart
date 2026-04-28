import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../services/follow_service.dart';
import '../../models/user_model.dart';
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
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.darkGrey,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            style: const TextStyle(color: AppTheme.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: context.tr('explore_search_users'),
              hintStyle: const TextStyle(color: AppTheme.grey),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.grey,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  child: Text(
                    context.tr('cancel'),
                    style: const TextStyle(color: AppTheme.white),
                  ),
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
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.blue),
          );
        }

        final posts = snap.data?.docs ?? [];
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.explore_outlined,
                  color: AppTheme.grey,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('explore_empty'),
                  style: const TextStyle(color: AppTheme.grey, fontSize: 14),
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
            return GestureDetector(onTap: () {}, child: _postImage(imageUrl));
          },
        );
      },
    );
  }

  Widget _postImage(String url) {
    if (url.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          fit: BoxFit.cover,
        );
      } catch (_) {
        return Container(color: AppTheme.darkGrey);
      }
    }
    if (url.isEmpty) return Container(color: AppTheme.darkGrey);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppTheme.darkGrey),
      errorWidget: (_, _, _) => Container(color: AppTheme.darkGrey),
    );
  }

  Widget _buildSearchView() {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (_searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, color: AppTheme.grey, size: 64),
            const SizedBox(height: 12),
            Text(
              context.tr('explore_enter_username'),
              style: const TextStyle(color: AppTheme.grey, fontSize: 14),
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
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.blue),
          );
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
                const Icon(Icons.person_search, color: AppTheme.grey, size: 64),
                const SizedBox(height: 12),
                Text(
                  context
                      .tr('explore_not_found')
                      .replaceAll('{query}', _searchQuery),
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
        backgroundColor: AppTheme.darkGrey,
        backgroundImage: user.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        child: user.photoUrl.isEmpty
            ? const Icon(Icons.person, color: AppTheme.grey)
            : null,
      ),
      title: Row(
        children: [
          Text(
            user.username,
            style: const TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: AppTheme.blue, size: 14),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.displayName,
            style: const TextStyle(color: AppTheme.grey, fontSize: 12),
          ),
          Text(
            '${user.followersCount} ${context.tr('followers_count_suffix')}',
            style: const TextStyle(color: AppTheme.grey, fontSize: 11),
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
                  icon: const Icon(
                    Icons.send_outlined,
                    color: AppTheme.white,
                    size: 20,
                  ),
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
    return GestureDetector(
      onTap: _isLoading ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: widget.isFollowing ? AppTheme.darkGrey : AppTheme.blue,
          borderRadius: BorderRadius.circular(8),
          border: widget.isFollowing
              ? Border.all(color: AppTheme.divider)
              : null,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: AppTheme.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.isFollowing
                    ? context.tr('following_state')
                    : context.tr('follow'),
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
