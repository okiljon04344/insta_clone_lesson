import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/post_image.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Saqlanganlar')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('saved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final saved = snap.data?.docs ?? [];
          if (saved.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, color: AppTheme.muted, size: 48),
                  SizedBox(height: 16),
                  Text('Saqlangan postlar yo\'q', style: AppTheme.titleStyle),
                  SizedBox(height: 8),
                  Text(
                    'Postlardagi bookmark tugmasi bilan saqlang',
                    style: TextStyle(color: AppTheme.muted, fontSize: 14),
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
            itemCount: saved.length,
            itemBuilder: (context, index) {
              final data = saved[index].data() as Map<String, dynamic>;
              final postId = data['postId'] as String? ?? saved[index].id;
              return _SavedPostTile(postId: postId);
            },
          );
        },
      ),
    );
  }
}

class _SavedPostTile extends StatelessWidget {
  final String postId;

  const _SavedPostTile({required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snap) {
        if (!snap.hasData) return Container(color: AppTheme.surfaceMuted);
        final data = snap.data!.data() as Map<String, dynamic>?;
        final imageUrls = List<String>.from(data?['imageUrls'] ?? []);
        final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
        return PostImage(url: imageUrl);
      },
    );
  }
}
