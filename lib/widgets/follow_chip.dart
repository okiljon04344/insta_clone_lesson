import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact pill button for follow / following actions.
///
/// Filled with the accent colour for the call to action; outlined when
/// [isActive] (the relationship already exists).
class FollowChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isLoading;
  final VoidCallback? onTap;

  const FollowChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppTheme.ink : AppTheme.onAccent;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.background : AppTheme.accent,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: isActive ? Border.all(color: AppTheme.border) : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: foreground,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
