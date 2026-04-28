import 'package:flutter/material.dart';
import '../services/app_translation_service.dart';

class AppStrings {
  final Locale locale;

  AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      AppStrings(Localizations.localeOf(context));

  String t(String key) {
    return AppTranslationService().tr(key, locale);
  }
}

extension AppStringsX on BuildContext {
  AppStrings get strings => AppStrings.of(this);

  String tr(String key) => strings.t(key);
}
