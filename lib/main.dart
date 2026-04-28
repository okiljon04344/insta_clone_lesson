import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'supabase_config.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/app_language_service.dart';
import 'services/app_translation_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppLanguageService().init();
  await AppTranslationService().loadForLocale(
    AppLanguageService().localeNotifier.value,
  );
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const InstagramApp());
}

class InstagramApp extends StatelessWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = AppLanguageService();
    final translationService = AppTranslationService();
    return ValueListenableBuilder<Locale>(
      valueListenable: languageService.localeNotifier,
      builder: (context, locale, child) {
        translationService.loadForLocale(locale);
        return ValueListenableBuilder<int>(
          valueListenable: translationService.revisionNotifier,
          builder: (context, revision, child) {
            return MaterialApp(
              title: 'Instagram',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              locale: locale,
              supportedLocales: AppLanguageService.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const AuthWrapper(),
            );
          },
        );
      },
    );
  }
}
