import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_translation_service.dart';

class TranslationSeedService {
  Future<void> ensureBaseTranslations() async {
    final db = FirebaseFirestore.instance;
    final col = db.collection('app_translations');

    for (final entry in AppTranslationService.fallbackValues.entries) {
      final doc = await col.doc(entry.key).get();
      if (doc.exists) continue;
      await col.doc(entry.key).set({'values': entry.value});
    }
  }
}
