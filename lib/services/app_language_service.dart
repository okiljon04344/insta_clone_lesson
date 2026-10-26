import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageService {
  static final AppLanguageService _instance = AppLanguageService._internal();
  factory AppLanguageService() => _instance;
  AppLanguageService._internal();

  static const _langCodeKey = 'app_language_code';
  static const _countryCodeKey = 'app_country_code';
  bool _authSyncBound = false;

  final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('uz'),
  );

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('uz'),
    Locale('ja'),
    Locale('ru'),
    Locale('tr'),
    Locale('ar'),
    Locale('fr'),
    Locale('de'),
    Locale('es'),
    Locale('it'),
    Locale('pt'),
    Locale('nl'),
    Locale('pl'),
    Locale('uk'),
    Locale('hi'),
    Locale('bn'),
    Locale('ur'),
    Locale('fa'),
    Locale('id'),
    Locale('ms'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('ko'),
    Locale('kk'),
    Locale('ky'),
    Locale('az'),
    Locale('ka'),
    Locale('hy'),
    Locale('he'),
    Locale('sv'),
    Locale('no'),
    Locale('da'),
    Locale('fi'),
    Locale('cs'),
    Locale('sk'),
    Locale('sl'),
    Locale('hr'),
    Locale('sr'),
    Locale('bg'),
    Locale('ro'),
    Locale('hu'),
    Locale('el'),
    Locale('lt'),
    Locale('lv'),
    Locale('et'),
    Locale('is'),
    Locale('ga'),
    Locale('mt'),
    Locale('sq'),
    Locale('mk'),
    Locale('bs'),
    Locale('af'),
    Locale('sw'),
    Locale('am'),
    Locale('ne'),
    Locale('si'),
    Locale('ta'),
    Locale('te'),
    Locale('ml'),
    Locale('mr'),
    Locale('gu'),
    Locale('pa'),
    Locale('kn'),
    Locale('or'),
    Locale('my'),
    Locale('km'),
    Locale('lo'),
    Locale('mn'),
    Locale('ps'),
    Locale('tg'),
    Locale('tt'),
    Locale('be'),
    Locale('eu'),
    Locale('gl'),
    Locale('ca'),
    Locale('cy'),
    Locale('lb'),
    Locale('fil'),
    Locale('ha'),
    Locale('yo'),
    Locale('zu'),
    Locale('ig'),
    Locale('mi'),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'uz': 'O\'zbek',
    'ja': '日本語',
    'ru': 'Русский',
    'tr': 'Türkçe',
    'ar': 'العربية',
    'fr': 'Français',
    'de': 'Deutsch',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'nl': 'Nederlands',
    'pl': 'Polski',
    'uk': 'Українська',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'ur': 'اردو',
    'fa': 'فارسی',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
    'zh': '中文',
    'ko': '한국어',
    'kk': 'Қазақша',
    'ky': 'Кыргызча',
    'az': 'Azərbaycanca',
    'ka': 'ქართული',
    'hy': 'Հայերեն',
    'he': 'עברית',
    'sv': 'Svenska',
    'no': 'Norsk',
    'da': 'Dansk',
    'fi': 'Suomi',
    'cs': 'Čeština',
    'sk': 'Slovenčina',
    'sl': 'Slovenščina',
    'hr': 'Hrvatski',
    'sr': 'Српски',
    'bg': 'Български',
    'ro': 'Română',
    'hu': 'Magyar',
    'el': 'Ελληνικά',
    'lt': 'Lietuvių',
    'lv': 'Latviešu',
    'et': 'Eesti',
    'is': 'Íslenska',
    'ga': 'Gaeilge',
    'mt': 'Malti',
    'sq': 'Shqip',
    'mk': 'Македонски',
    'bs': 'Bosanski',
    'af': 'Afrikaans',
    'sw': 'Kiswahili',
    'am': 'አማርኛ',
    'ne': 'नेपाली',
    'si': 'සිංහල',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'ml': 'മലയാളം',
    'mr': 'मराठी',
    'gu': 'ગુજરાતી',
    'pa': 'ਪੰਜਾਬੀ',
    'kn': 'ಕನ್ನಡ',
    'or': 'ଓଡ଼ିଆ',
    'my': 'မြန်မာ',
    'km': 'ខ្មែរ',
    'lo': 'ລາວ',
    'mn': 'Монгол',
    'ps': 'پښتو',
    'tg': 'Тоҷикӣ',
    'tt': 'Татарча',
    'be': 'Беларуская',
    'eu': 'Euskara',
    'gl': 'Galego',
    'ca': 'Català',
    'cy': 'Cymraeg',
    'lb': 'Lëtzebuergesch',
    'fil': 'Filipino',
    'ha': 'Hausa',
    'yo': 'Yorùbá',
    'zu': 'isiZulu',
    'ig': 'Igbo',
    'mi': 'Māori',
  };

  Future<void> init() async {
    _bindAuthSync();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final locale = await _fetchLocaleFromServer(user.uid);
        if (locale != null) {
          localeNotifier.value = locale;
          await _storeLocaleLocally(locale);
          return;
        }
      } catch (_) {
        // If the server is unavailable, the local fallback is used.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_langCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (code == null || code.isEmpty) {
      localeNotifier.value = const Locale('uz');
      return;
    }

    final candidate = Locale(
      code,
      (countryCode != null && countryCode.isNotEmpty) ? countryCode : null,
    );
    localeNotifier.value = _resolveSupported(candidate);
  }

  Future<void> setLocale(Locale locale) async {
    final resolved = _resolveSupported(locale);
    localeNotifier.value = resolved;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'appLanguageCode': resolved.languageCode,
          'appLanguageCountryCode': resolved.countryCode ?? '',
        }, SetOptions(merge: true));
      } catch (_) {
        // The in-app language switches immediately even without a network.
      }
    }

    await _storeLocaleLocally(resolved);
  }

  String labelFor(Locale locale) {
    if (locale.languageCode == 'zh' && locale.countryCode == 'CN') {
      return '中文 (简体)';
    }
    if (locale.languageCode == 'zh' && locale.countryCode == 'TW') {
      return '中文 (繁體)';
    }
    return languageNames[locale.languageCode] ??
        locale.languageCode.toUpperCase();
  }

  Locale _resolveSupported(Locale locale) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode &&
          supported.countryCode == locale.countryCode) {
        return supported;
      }
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }

  void _bindAuthSync() {
    if (_authSyncBound) return;
    _authSyncBound = true;

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) return;
      final serverLocale = await _fetchLocaleFromServer(user.uid);
      if (serverLocale == null) return;

      final current = localeNotifier.value;
      final changed =
          current.languageCode != serverLocale.languageCode ||
          current.countryCode != serverLocale.countryCode;
      if (!changed) return;

      localeNotifier.value = serverLocale;
      await _storeLocaleLocally(serverLocale);
    });
  }

  Future<Locale?> _fetchLocaleFromServer(String uid) async {
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = profile.data();
    final serverLang = data?['appLanguageCode'] as String?;
    final serverCountry = data?['appLanguageCountryCode'] as String?;

    if (serverLang == null || serverLang.isEmpty) return null;

    return _resolveSupported(
      Locale(
        serverLang,
        (serverCountry != null && serverCountry.isNotEmpty)
            ? serverCountry
            : null,
      ),
    );
  }

  Future<void> _storeLocaleLocally(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
  }
}
