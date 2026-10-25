import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  XFile? _newProfileImage;
  Uint8List? _newProfileImageBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.user.displayName,
    );
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 600,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newProfileImage = picked;
        _newProfileImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final db = FirebaseFirestore.instance;

      final newUsername = _usernameController.text.trim().toLowerCase();
      if (newUsername != widget.user.username) {
        final q = await db
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .limit(1)
            .get();
        if (!mounted) return;
        if (q.docs.isNotEmpty) {
          showAppSnackBar(
            context,
            'Bu foydalanuvchi nomi allaqachon band',
            isError: true,
          );
          return;
        }
      }

      String photoUrl = widget.user.photoUrl;
      final newImage = _newProfileImage;
      if (newImage != null) {
        photoUrl = await SupabaseStorageService().uploadAvatar(
          uid: uid,
          image: newImage,
        );
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(photoUrl);
      }

      final newDisplayName = _displayNameController.text.trim();
      await FirebaseAuth.instance.currentUser!.updateDisplayName(
        newDisplayName,
      );

      await db.collection('users').doc(uid).update({
        'displayName': newDisplayName,
        'username': newUsername,
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
      });

      final updatedUser = widget.user.copyWith(
        displayName: newDisplayName,
        username: newUsername,
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );

      if (mounted) {
        showAppSnackBar(context, 'Profil muvaffaqiyatli yangilandi');
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Xatolik: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newImageBytes = _newProfileImageBytes;
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Bekor',
            style: TextStyle(color: AppTheme.ink, fontSize: 14),
          ),
        ),
        leadingWidth: 80,
        title: const Text('Profilni tahrirlash', style: AppTheme.labelStyle),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Saqlash'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.surfaceMuted,
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: ClipOval(
                              child: newImageBytes != null
                                  ? Image.memory(
                                      newImageBytes,
                                      fit: BoxFit.cover,
                                    )
                                  : widget.user.photoUrl.isNotEmpty
                                  ? Image.network(
                                      widget.user.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _avatarFallback(),
                                    )
                                  : _avatarFallback(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: AppTheme.onAccent,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: const Text(
                        'Profil rasmini o\'zgartirish',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const FieldLabel('To\'liq ism'),
                  TextFormField(
                    controller: _displayNameController,
                    style: AppTheme.bodyStyle,
                    decoration: const InputDecoration(hintText: 'Ism Familiya'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ismingizni kiriting';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Foydalanuvchi nomi'),
                  TextFormField(
                    controller: _usernameController,
                    style: AppTheme.bodyStyle,
                    decoration: const InputDecoration(
                      hintText: 'foydalanuvchi_nomi',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Username kiriting';
                      }
                      if (v.trim().length < 3) return 'Kamida 3 ta belgi';
                      if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v.trim())) {
                        return 'Faqat harf, raqam, nuqta va _ bo\'lishi mumkin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const FieldLabel('Bio'),
                  TextFormField(
                    controller: _bioController,
                    style: AppTheme.bodyStyle,
                    maxLines: 4,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      hintText: 'O\'zingiz haqingizda...',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return const Center(
      child: Icon(Icons.person, color: AppTheme.muted, size: 48),
    );
  }
}
