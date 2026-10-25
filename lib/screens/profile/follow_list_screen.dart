import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/follow_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/follow_chip.dart';
import '../../widgets/user_avatar.dart';
import 'profile_screen.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String username;
  final FollowListType initialType;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.initialType,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == FollowListType.followers ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: context.tr('followers')),
            Tab(text: context.tr('following')),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TextField(
              controller: _searchController,
              style: AppTheme.bodyStyle,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: context.tr('search'),
                prefixIcon: const Icon(Icons.search, color: AppTheme.muted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, color: AppTheme.muted),
                      ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FollowUsersList(
                  userId: widget.userId,
                  type: FollowListType.followers,
                  query: _query,
                ),
                _FollowUsersList(
                  userId: widget.userId,
                  type: FollowListType.following,
                  query: _query,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowUsersList extends StatelessWidget {
  final String userId;
  final FollowListType type;
  final String query;

  const _FollowUsersList({
    required this.userId,
    required this.type,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final collection = type == FollowListType.followers
        ? 'followers'
        : 'following';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(collection)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              type == FollowListType.followers
                  ? context.tr('followers_empty')
                  : context.tr('following_empty'),
              style: const TextStyle(color: AppTheme.muted, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final uid = docs[index].id;
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const ListTile(
                    leading: UserAvatar(photoUrl: '', radius: 24),
                    title: Text('...', style: TextStyle(color: AppTheme.muted)),
                  );
                }

                final data = userSnap.data?.data();
                if (data == null) return const SizedBox.shrink();
                final user = UserModel.fromMap(data);
                final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final searchText = '${user.username} ${user.displayName}'
                    .toLowerCase();
                if (query.isNotEmpty && !searchText.contains(query)) {
                  return const SizedBox.shrink();
                }

                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(
                          user: user,
                          isCurrentUser: user.uid == myUid,
                        ),
                      ),
                    );
                  },
                  leading: UserAvatar(photoUrl: user.photoUrl, radius: 24),
                  title: Row(
                    children: [
                      Text(user.username, style: AppTheme.labelStyle),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppTheme.accent,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    user.displayName,
                    style: AppTheme.captionStyle,
                  ),
                  trailing: user.uid == myUid
                      ? null
                      : _FollowActionButton(userId: user.uid),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FollowActionButton extends StatefulWidget {
  final String userId;

  const _FollowActionButton({required this.userId});

  @override
  State<_FollowActionButton> createState() => _FollowActionButtonState();
}

class _FollowActionButtonState extends State<_FollowActionButton> {
  bool _isLoading = false;

  Future<void> _toggle(bool isFollowing) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (isFollowing) {
        await FollowService().unfollow(widget.userId);
      } else {
        await FollowService().follow(widget.userId);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: FollowService().isFollowingStream(widget.userId),
      builder: (context, snap) {
        final isFollowing = snap.data ?? false;
        return FollowChip(
          label: isFollowing
              ? context.tr('following_state')
              : context.tr('follow'),
          isActive: isFollowing,
          isLoading: _isLoading,
          onTap: () => _toggle(isFollowing),
        );
      },
    );
  }
}
