import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Post image that accepts either a network URL or a `data:image` URI.
class PostImage extends StatelessWidget {
  final String url;

  const PostImage({super.key, required this.url});

  static const _placeholder = ColoredBox(color: AppTheme.surfaceMuted);

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder;
    if (url.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(url.split(',').last),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        return _placeholder;
      }
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => _placeholder,
      errorWidget: (_, _, _) => _placeholder,
    );
  }
}
