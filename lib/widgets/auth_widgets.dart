import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Title and subtitle shown at the top of each auth step.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final CrossAxisAlignment alignment;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final textAlign = alignment == CrossAxisAlignment.center
        ? TextAlign.center
        : TextAlign.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(title, style: AppTheme.headlineStyle, textAlign: textAlign),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 14),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTheme.labelStyle.copyWith(fontSize: 13)),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppTheme.onAccent,
                strokeWidth: 2,
              ),
            )
          : Text(label),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata, size: 28),
      label: Text(label),
    );
  }
}

/// Horizontal rule with a centred caption, e.g. "or".
class LabeledDivider extends StatelessWidget {
  final String text;

  const LabeledDivider(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(text, style: AppTheme.captionStyle),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Eye icon that toggles a password field.
class VisibilityToggle extends StatelessWidget {
  final bool isHidden;
  final VoidCallback onPressed;

  const VisibilityToggle({
    super.key,
    required this.isHidden,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: AppTheme.muted,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}

/// Round avatar placeholder with a camera badge for picking a profile photo.
class AvatarPicker extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const AvatarPicker({
    super.key,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceMuted,
              border: Border.all(color: AppTheme.border),
              image: bytes != null
                  ? DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: bytes == null
                ? const Icon(Icons.person, color: AppTheme.muted, size: 40)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: AppTheme.onAccent,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
