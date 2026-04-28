import 'package:flutter/material.dart';

class AppTheme {
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF8E8E8E);
  static const Color darkGrey = Color(0xFF262626);
  static const Color lightGrey = Color(0xFFDBDBDB);
  static const Color divider = Color(0xFF363636);
  static const Color red = Color(0xFFED4956);
  static const Color blue = Color(0xFF0095F6);

  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient logoGradient = LinearGradient(
    colors: [
      Color(0xFFF58529),
      Color(0xFFDD2A7B),
      Color(0xFF8134AF),
      Color(0xFF515BD4),
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: black,
    appBarTheme: const AppBarTheme(
      backgroundColor: black,
      elevation: 0,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Billabong',
      ),
    ),
    colorScheme: const ColorScheme.dark(primary: blue, surface: black),
    dividerColor: divider,
    iconTheme: const IconThemeData(color: white),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: white),
      bodyMedium: TextStyle(color: white),
      bodySmall: TextStyle(color: grey),
    ),
  );
}
