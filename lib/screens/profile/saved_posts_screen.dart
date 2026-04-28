import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        title: const Text(
          'Saqlanganlar',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('saved')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.blue),
            );
          }

          final saved = snap.data?.docs ?? [];
          if (saved.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, color: AppTheme.grey, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'Saqlangan postlar yo\'q',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Postlardagi bookmark tugmasi bilan saqlang',
                    style: TextStyle(color: AppTheme.grey, fontSize: 13),
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
        if (!snap.hasData) return Container(color: AppTheme.darkGrey);
        final data = snap.data!.data() as Map<String, dynamic>?;
        final imageUrls = List<String>.from(data?['imageUrls'] ?? []);
        final imageUrl = imageUrls.isNotEmpty ? imageUrls.first : '';
        return _PostImage(imageUrl: imageUrl);
      },
    );
  }
}

class _PostImage extends StatelessWidget {
  final String imageUrl;

  const _PostImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.split(',').last),
          fit: BoxFit.cover,
        );
      } catch (_) {
        return Container(color: AppTheme.darkGrey);
      }
    }

    if (imageUrl.isEmpty) return Container(color: AppTheme.darkGrey);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppTheme.darkGrey),
      errorWidget: (_, _, _) => Container(color: AppTheme.darkGrey),
    );
  }
}
