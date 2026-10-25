import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';

/// Two-step post creation: pick an image, then add caption and location.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  int _step = 1; // 1 = pick image, 2 = details
  bool _isLoadingGallery = false;

  @override
  void initState() {
    super.initState();
    _pickFromGallery();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoadingGallery = true);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _isLoadingGallery = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingGallery = false);
      Navigator.pop(context);
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 1600,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _publish() async {
    final image = _selectedImage;
    if (image == null || _selectedImageBytes == null) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;

      final postId = db.collection('posts').doc().id;
      final imageUrl = await SupabaseStorageService().uploadPostImage(
        uid: user.uid,
        postId: postId,
        image: image,
      );

      await db.collection('posts').doc(postId).set({
        'id': postId,
        'uid': user.uid,
        'username': userData['username'] ?? '',
        'userDisplayName': userData['displayName'] ?? '',
        'userPhotoUrl': userData['photoUrl'] ?? '',
        'imageUrls': [imageUrl],
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'likesCount': 0,
        'commentsCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      await db.collection('users').doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      if (mounted) {
        showAppSnackBar(context, 'Post muvaffaqiyatli ulashildi!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Xatolik: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step == 1
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              )
            : IconButton(
                onPressed: _isLoading ? null : () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(_step == 1 ? 'Yangi post' : 'Post yaratish'),
        centerTitle: true,
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: _selectedImage == null
                  ? null
                  : () => setState(() => _step = 2),
              child: const Text('Keyingi'),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _publish,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ulashish'),
            ),
        ],
      ),
      body: _step == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  Widget _buildStep1() {
    if (_isLoadingGallery) {
      return const Center(child: CircularProgressIndicator());
    }

    final bytes = _selectedImageBytes;
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: bytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.contain),
                    Positioned(left: 8, bottom: 8, child: _aspectRatioButton()),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _mediaSourceButtons(),
                    ),
                  ],
                )
              : Container(
                  color: AppTheme.surfaceMuted,
                  child: const Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.muted,
                      size: 48,
                    ),
                  ),
                ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('Galereya'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('Kamera'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    final bytes = _selectedImageBytes;
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _userAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    style: AppTheme.bodyStyle,
                    maxLines: 6,
                    minLines: 1,
                    maxLength: 2200,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Caption yozing...',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      counterStyle: AppTheme.captionStyle,
                    ),
                  ),
                ),
                if (bytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      bytes,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: TextField(
              controller: _locationController,
              style: AppTheme.bodyStyle,
              decoration: const InputDecoration(
                hintText: 'Joylashuvni qo\'shing',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const Divider(),

          _optionTile(Icons.person_outline_rounded, 'Odamlarni belgilash'),
          const Divider(),

          _optionTile(Icons.music_note_outlined, 'Musiqa qo\'shish'),
          const Divider(),

          _optionTile(Icons.lock_outline, 'Ko\'rish sozlamalari'),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Kengaytirilgan sozlamalar'),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.muted,
              size: 14,
            ),
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _aspectRatioButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop, color: AppTheme.onAccent, size: 16),
          SizedBox(width: 4),
          Text(
            'Nisbat',
            style: TextStyle(color: AppTheme.onAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _mediaSourceButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickFromGallery,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.ink.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.collections_outlined,
                  color: AppTheme.onAccent,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Galereya',
                  style: TextStyle(color: AppTheme.onAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _pickFromCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.ink.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: AppTheme.onAccent,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _userAvatar() {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.surfaceMuted,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? const Icon(Icons.person, color: AppTheme.muted, size: 18)
          : null,
    );
  }

  Widget _optionTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.muted,
        size: 14,
      ),
      onTap: () {},
    );
  }
}
