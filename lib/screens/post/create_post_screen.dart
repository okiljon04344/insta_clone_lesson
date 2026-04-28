import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';

/// Instagram kabi 2 bosqichli post yaratish:
/// Step 1 → Rasm tanlash / ko'rish (Keyingi)
/// Step 2 → Caption, joylashuv, sozlamalar (Ulashish)
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
  int _step = 1; // 1 = rasm tanlash, 2 = detallar
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
    if (_selectedImage == null || _selectedImageBytes == null) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final db = FirebaseFirestore.instance;

      // Foydalanuvchi ma'lumotlarini olish
      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data()!;

      final postId = db.collection('posts').doc().id;
      final imageUrl = await SupabaseStorageService().uploadPostImage(
        uid: user.uid,
        postId: postId,
        image: _selectedImage!,
      );

      // Firestore ga post yozish
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

      // Foydalanuvchining postsCount ni oshirish
      await db.collection('users').doc(user.uid).update({
        'postsCount': FieldValue.increment(1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post muvaffaqiyatli ulashildi!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Xatolik: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        leading: _step == 1
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppTheme.white),
              )
            : IconButton(
                onPressed: _isLoading ? null : () => setState(() => _step = 1),
                icon: const Icon(Icons.arrow_back, color: AppTheme.white),
              ),
        title: Text(
          _step == 1 ? 'Yangi post' : 'Post yaratish',
          style: const TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_step == 1)
            TextButton(
              onPressed: _selectedImage == null
                  ? null
                  : () => setState(() => _step = 2),
              child: const Text(
                'Keyingi',
                style: TextStyle(
                  color: AppTheme.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _publish,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppTheme.blue,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Ulashish',
                      style: TextStyle(
                        color: AppTheme.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _step == 1 ? _buildStep1() : _buildStep2(),
    );
  }

  // STEP 1: Rasm tanlash va ko'rish
  Widget _buildStep1() {
    if (_isLoadingGallery) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.blue),
      );
    }

    return Column(
      children: [
        // Rasm ko'rinishi
        Expanded(
          flex: 6,
          child: _selectedImage != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
                    // Nisbat tugmalari (Instagram kabi)
                    Positioned(left: 8, bottom: 8, child: _aspectRatioButton()),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _mediaSourceButtons(),
                    ),
                  ],
                )
              : Container(
                  color: AppTheme.darkGrey,
                  child: const Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.grey,
                      size: 48,
                    ),
                  ),
                ),
        ),

        // Galereya / Kamera tanlash
        Container(
          color: AppTheme.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.darkGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: AppTheme.white,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Galereya',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _pickFromCamera,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.darkGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          color: AppTheme.white,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Kamera',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: Caption va detallar
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Caption qatori
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
                    style: const TextStyle(color: AppTheme.white, fontSize: 14),
                    maxLines: 6,
                    minLines: 1,
                    maxLength: 2200,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Caption yozing...',
                      hintStyle: TextStyle(color: AppTheme.grey),
                      border: InputBorder.none,
                      counterStyle: TextStyle(
                        color: AppTheme.grey,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    _selectedImageBytes!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.divider, height: 1),

          // Joylashuv
          ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
              color: AppTheme.white,
            ),
            title: TextField(
              controller: _locationController,
              style: const TextStyle(color: AppTheme.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Joylashuvni qo\'shing',
                hintStyle: TextStyle(color: AppTheme.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          const Divider(color: AppTheme.divider, height: 1),

          // Odamlarni belgilash
          _optionTile(Icons.person_outline_rounded, 'Odamlarni belgilash'),
          const Divider(color: AppTheme.divider, height: 1),

          // Musiqa
          _optionTile(Icons.music_note_outlined, 'Musiqa qo\'shish'),
          const Divider(color: AppTheme.divider, height: 1),

          // Ko'rish sozlamalari
          _optionTile(Icons.lock_outline, 'Ko\'rish sozlamalari'),
          const Divider(color: AppTheme.divider, height: 1),

          // Ilg'or sozlamalar
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppTheme.white),
            title: const Text(
              'Kengaytirilgan sozlamalar',
              style: TextStyle(color: AppTheme.white, fontSize: 14),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.grey,
              size: 14,
            ),
            onTap: () {},
          ),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _aspectRatioButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text('Nisbat', style: TextStyle(color: Colors.white, fontSize: 12)),
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
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.collections_outlined, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Galereya',
                  style: TextStyle(color: Colors.white, fontSize: 12),
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
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _userAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.darkGrey,
      backgroundImage: (user?.photoURL?.isNotEmpty == true)
          ? NetworkImage(user!.photoURL!)
          : null,
      child: (user?.photoURL?.isNotEmpty != true)
          ? const Icon(Icons.person, color: AppTheme.grey, size: 18)
          : null,
    );
  }

  Widget _optionTile(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.white),
      title: Text(
        label,
        style: const TextStyle(color: AppTheme.white, fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.grey,
        size: 14,
      ),
      onTap: () {},
    );
  }
}
