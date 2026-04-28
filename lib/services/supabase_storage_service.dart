import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  static const int maxImageBytes = 8 * 1024 * 1024;

  Future<String> uploadPostImage({
    required String uid,
    required String postId,
    required XFile image,
  }) async {
    return _uploadImage(
      path: 'posts/$uid/$postId.jpg',
      bytes: await image.readAsBytes(),
      upsert: false,
    );
  }

  Future<String> uploadAvatar({
    required String uid,
    required XFile image,
  }) async {
    return _uploadImage(
      path: 'avatars/$uid/avatar.jpg',
      bytes: await image.readAsBytes(),
      upsert: true,
    );
  }

  Future<String> uploadChatImage({
    required String chatId,
    required String messageId,
    required XFile image,
  }) async {
    return _uploadImage(
      path: 'chats/$chatId/$messageId.jpg',
      bytes: await image.readAsBytes(),
      upsert: false,
    );
  }

  Future<String> _uploadImage({
    required String path,
    required Uint8List bytes,
    required bool upsert,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase ulanmagan. SUPABASE_URL va SUPABASE_ANON_KEY ni dart-define orqali bering.',
      );
    }

    if (bytes.isEmpty) {
      throw StateError('Rasm fayli bo\'sh. Boshqa rasm tanlang.');
    }

    if (bytes.length > maxImageBytes) {
      throw StateError('Rasm 8 MB dan katta. Iltimos, yengilroq rasm tanlang.');
    }

    try {
      await _client.storage.from(SupabaseConfig.bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: 'image/jpeg',
              upsert: upsert,
            ),
          );
    } on StorageException catch (e) {
      final message = e.message.toLowerCase();
      if (message.contains('bucket not found')) {
        throw StateError(
          'Supabase Storage bucket topilmadi: "${SupabaseConfig.bucket}". '
          'Supabase SQL Editor’da supabase_storage_setup.sql faylini ishga tushiring.',
        );
      }
      rethrow;
    }

    return _client.storage.from(SupabaseConfig.bucket).getPublicUrl(path);
  }
}
