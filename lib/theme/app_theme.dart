import 'package:flutter/material.dart';

/// Design tokens and the app-wide [ThemeData].
///
/// Light, neutral surfaces with a single teal accent that is only used for
/// primary actions and active icons.
class AppTheme {
  AppTheme._();

  static const String appName = 'frame';

  // Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF5F5F4);
  static const Color border = Color(0xFFE7E5E4);

  // Content
  static const Color ink = Color(0xFF1C1917);
  static const Color muted = Color(0xFF78716C);
  static const Color onAccent = Color(0xFFFFFFFF);

  // Semantic
  static const Color accent = Color(0xFF0F766E);
  static const Color danger = Color(0xFFB91C1C);

  static const double radius = 10;

  // Type scale
  static const TextStyle headlineStyle = TextStyle(
    color: ink,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const TextStyle titleStyle = TextStyle(
    color: ink,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle bodyStyle = TextStyle(color: ink, fontSize: 14);
  static const TextStyle labelStyle = TextStyle(
    color: ink,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle captionStyle = TextStyle(color: muted, fontSize: 12);
  static const TextStyle wordmarkStyle = TextStyle(
    color: ink,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
  );

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: accent,
      onPrimary: onAccent,
      surface: background,
      onSurface: ink,
      error: danger,
      outline: border,
    ),
    dividerColor: border,
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: ink),
      titleTextStyle: titleStyle,
    ),
    textTheme: const TextTheme(
      titleLarge: titleStyle,
      titleMedium: labelStyle,
      bodyLarge: bodyStyle,
      bodyMedium: bodyStyle,
      bodySmall: captionStyle,
      labelLarge: labelStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceMuted,
      hintStyle: const TextStyle(color: muted, fontSize: 14),
      errorStyle: const TextStyle(color: danger, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _inputBorder(border),
      enabledBorder: _inputBorder(border),
      focusedBorder: _inputBorder(accent),
      errorBorder: _inputBorder(danger),
      focusedErrorBorder: _inputBorder(danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: onAccent,
        disabledBackgroundColor: accent.withValues(alpha: 0.4),
        disabledForegroundColor: onAccent,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: border),
        textStyle: labelStyle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: const TextStyle(color: background, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: accent,
      unselectedLabelColor: muted,
      indicatorColor: accent,
      dividerColor: border,
    ),
  );
}
