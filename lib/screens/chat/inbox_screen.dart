import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: Text(
          context.tr('messages_title'),
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.white),
            tooltip: context.tr('new_message'),
            onPressed: () => _showNewChatDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService().conversationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            );
          }

          final convs = snap.data ?? [];

          if (convs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('messages_empty_title'),
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('messages_empty_subtitle'),
                    style: const TextStyle(color: AppTheme.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showNewChatDialog(context),
                    icon: const Icon(Icons.send),
                    label: Text(context.tr('send_message_button')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: convs.length,
            itemBuilder: (context, i) {
              final conv = convs[i];
              final participants = List<String>.from(
                conv['participants'] ?? [],
              );
              final otherUid = participants.firstWhere(
                (u) => u != myUid,
                orElse: () => '',
              );
              final seenBy = List<String>.from(conv['seenBy'] ?? []);
              final isSeen = seenBy.contains(myUid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.darkGrey,
                        child: Icon(Icons.person, color: AppTheme.grey),
                      ),
                      title: SizedBox(
                        height: 14,
                        width: 100,
                        child: ColoredBox(color: AppTheme.darkGrey),
                      ),
                    );
                  }

                  final otherUser = UserModel.fromMap(
                    userSnap.data!.data() as Map<String, dynamic>,
                  );

                  final lastMsg = conv['lastMessage'] as String? ?? '';
                  final lastAt = (conv['lastMessageAt'] as Timestamp?)
                      ?.toDate();
                  final isFromMe = conv['lastSenderId'] == myUid;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.darkGrey,
                          backgroundImage: otherUser.photoUrl.isNotEmpty
                              ? NetworkImage(otherUser.photoUrl)
                              : null,
                          child: otherUser.photoUrl.isEmpty
                              ? const Icon(Icons.person, color: AppTheme.grey)
                              : null,
                        ),
                        // Online dot
                        StreamBuilder<Map<String, dynamic>>(
                          stream: ChatService().onlineStatusStream(
                            otherUser.uid,
                          ),
                          builder: (ctx, onlineSnap) {
                            final isOnline =
                                onlineSnap.data?['isOnline'] == true;
                            if (!isOnline) return const SizedBox.shrink();
                            return Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    title: Row(
                      children: [
                        Text(
                          otherUser.username,
                          style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: isSeen
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (otherUser.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: AppTheme.blue,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isFromMe
                                ? '${context.tr('you_prefix')}: $lastMsg'
                                : lastMsg,
                            style: TextStyle(
                              color: isSeen ? AppTheme.grey : AppTheme.white,
                              fontSize: 13,
                              fontWeight: isSeen
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastAt != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(context, lastAt),
                            style: const TextStyle(
                              color: AppTheme.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: !isSeen && !isFromMe
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppTheme.blue,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUser: otherUser),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _NewChatSheet(),
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return context.tr('now_short');
    if (diff.inHours < 1) {
      return '${diff.inMinutes} ${context.tr('minutes_ago')}';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} ${context.tr('hours_ago')}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ${context.tr('days_ago')}';
    }
    return '${dt.day}.${dt.month}';
  }
}

class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: q.toLowerCase())
        .where('username', isLessThanOrEqualTo: '${q.toLowerCase()}\uf8ff')
        .limit(20)
        .get();
    if (mounted) {
      setState(() {
        _results = snap.docs
            .map((d) => UserModel.fromMap(d.data()))
            .where((u) => u.uid != myUid)
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            context.tr('new_message'),
            style: const TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.darkGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.white),
                decoration: InputDecoration(
                  hintText: context.tr('search_user'),
                  hintStyle: const TextStyle(color: AppTheme.grey),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: _search,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppTheme.divider, height: 1),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.blue),
                  )
                : _results.isEmpty
                ? Center(
                    child: Text(
                      context.tr('user_not_found'),
                      style: const TextStyle(color: AppTheme.grey),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final user = _results[i];
                      return ListTile(
                        leading: CircleAvatar(
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
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: AppTheme.blue,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          user.displayName,
                          style: const TextStyle(color: AppTheme.grey),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(otherUser: user),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
