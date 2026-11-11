import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sebastian_app/config/api_config.dart';
import 'package:sebastian_app/widgets/common/custom_icon.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.localFile,
    this.size = 100,
    this.onTap,
  });

  final String? imageUrl;
  final File? localFile;
  final double size;
  final VoidCallback? onTap;

  static String? resolveUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '${ApiConfig.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveUrl(imageUrl);
    Widget imageChild;

    if (localFile != null) {
      imageChild = Image.file(localFile!, fit: BoxFit.cover);
    } else if (resolvedUrl != null) {
      imageChild = Image.network(
        resolvedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset('assets/images/logo1.png', fit: BoxFit.cover),
      );
    } else {
      imageChild =
          Image.asset('assets/images/logo1.png', fit: BoxFit.cover);
    }

    final avatar = CustomIcon(
      size: size,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: imageChild,
        ),
      ),
    );

    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
