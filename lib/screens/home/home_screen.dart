import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_strings.dart';
import '../../data/sample_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/story_widget.dart';
import '../../widgets/firestore_post_card.dart';
import '../../services/notification_service.dart';
import '../chat/inbox_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTheme.appName, style: AppTheme.wordmarkStyle),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService().unreadCountStream(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                    icon: Icon(
                      count > 0 ? Icons.favorite : Icons.favorite_border,
                      color: count > 0 ? AppTheme.accent : AppTheme.ink,
                      size: 26,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            count > 9 ? '9+' : '$count',
                            style: const TextStyle(
                              color: AppTheme.onAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InboxScreen()),
            ),
            icon: const Icon(
              Icons.send_outlined,
              color: AppTheme.ink,
              size: 26,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            // Stories are still sample data.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: sampleStories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) =>
                          StoryWidget(story: sampleStories[i]),
                    ),
                  ),
                  const Divider(),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .limit(30)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.photo_camera_outlined,
                            color: AppTheme.muted,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('home_no_posts_title'),
                            style: AppTheme.titleStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('home_no_posts_subtitle'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        FirestorePostCard(postId: doc.id, data: data),
                        const Divider(),
                      ],
                    );
                  }, childCount: docs.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
