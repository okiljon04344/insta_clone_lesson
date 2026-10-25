import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Circular profile picture with a neutral placeholder when there is no photo.
class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final double radius;

  const UserAvatar({super.key, required this.photoUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surfaceMuted,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Icon(Icons.person, color: AppTheme.muted, size: radius)
          : null,
    );
  }
}
