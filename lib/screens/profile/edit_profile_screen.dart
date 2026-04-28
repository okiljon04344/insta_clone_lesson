import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_theme.dart';

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

      // Yangi username band emasligini tekshirish (o'zidan boshqa)
      final newUsername = _usernameController.text.trim().toLowerCase();
      if (newUsername != widget.user.username) {
        final q = await db
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          _showError('Bu foydalanuvchi nomi allaqachon band');
          return;
        }
      }

      // Rasm yuklash (agar yangi tanlangan bo'lsa)
      String photoUrl = widget.user.photoUrl;
      if (_newProfileImage != null) {
        photoUrl = await SupabaseStorageService().uploadAvatar(
          uid: uid,
          image: _newProfileImage!,
        );

        // Firebase Auth profilini ham yangilash
        await FirebaseAuth.instance.currentUser!.updatePhotoURL(photoUrl);
      }

      final newDisplayName = _displayNameController.text.trim();
      await FirebaseAuth.instance.currentUser!.updateDisplayName(
        newDisplayName,
      );

      // Firestore yangilash
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil muvaffaqiyatli yangilandi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) _showError('Xatolik: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
        leading: TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Bekor',
            style: TextStyle(color: AppTheme.white, fontSize: 16),
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          'Profilni tahrirlash',
          style: TextStyle(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
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
                    'Saqlash',
                    style: TextStyle(
                      color: AppTheme.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profil rasmi
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            _newProfileImage == null &&
                                widget.user.photoUrl.isEmpty
                            ? AppTheme.storyGradient
                            : null,
                        color: AppTheme.darkGrey,
                      ),
                      child: ClipOval(
                        child: _newProfileImage != null
                            ? Image.memory(
                                _newProfileImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : widget.user.photoUrl.isNotEmpty
                            ? Image.network(
                                widget.user.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _avatarFallback(),
                              )
                            : _avatarFallback(),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: const Text(
                  'Profil rasmini o\'zgartirish',
                  style: TextStyle(color: AppTheme.blue, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),

              // To'liq ism
              _buildField(
                label: 'To\'liq ism',
                controller: _displayNameController,
                hint: 'Ism Familiya',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ismingizni kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Username
              _buildField(
                label: 'Foydalanuvchi nomi',
                controller: _usernameController,
                hint: 'foydalanuvchi_nomi',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username kiriting';
                  if (v.trim().length < 3) return 'Kamida 3 ta belgi';
                  if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v.trim())) {
                    return 'Faqat harf, raqam, nuqta va _ bo\'lishi mumkin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Bio
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bio',
                    style: TextStyle(
                      color: AppTheme.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    style: const TextStyle(color: AppTheme.white, fontSize: 14),
                    maxLines: 4,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'O\'zingiz haqingizda...',
                      hintStyle: const TextStyle(
                        color: AppTheme.grey,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.darkGrey,
                      counterStyle: const TextStyle(color: AppTheme.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.grey),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: AppTheme.darkGrey,
      child: const Icon(Icons.person, color: AppTheme.grey, size: 48),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: AppTheme.white, fontSize: 14),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.grey, fontSize: 13),
            filled: true,
            fillColor: AppTheme.darkGrey,
            errorStyle: const TextStyle(color: AppTheme.red, fontSize: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.grey),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
