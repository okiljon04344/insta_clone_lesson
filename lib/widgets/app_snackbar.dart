import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows a floating snack bar; errors use the danger colour.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.danger : null,
    ),
  );
}
