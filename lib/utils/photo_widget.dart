import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Vérifie si une URL photo est un data URI base64.
bool isDataUri(String url) => url.startsWith('data:');

/// Décode un data URI base64 en bytes.
Uint8List decodeDataUri(String dataUri) {
  // Format: data:image/jpeg;base64,XXXX...
  final commaIndex = dataUri.indexOf(',');
  if (commaIndex == -1) return Uint8List(0);
  return base64Decode(dataUri.substring(commaIndex + 1));
}

/// Widget qui affiche une photo de profil à partir d'une URL standard
/// OU d'un data URI base64, avec un fallback en cas d'erreur.
class ProfilePhoto extends StatelessWidget {
  final String photoUrl;
  final Widget fallback;
  final BoxFit fit;

  const ProfilePhoto({
    super.key,
    required this.photoUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isEmpty) return fallback;

    if (isDataUri(photoUrl)) {
      try {
        final bytes = decodeDataUri(photoUrl);
        if (bytes.isEmpty) return fallback;
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => fallback,
        );
      } catch (_) {
        return fallback;
      }
    }

    return Image.network(
      photoUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// ImageProvider qui supporte à la fois les data URI et les URLs réseau.
/// Utile pour CircleAvatar.backgroundImage.
ImageProvider? photoProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.isEmpty) return null;
  if (isDataUri(photoUrl)) {
    try {
      final bytes = decodeDataUri(photoUrl);
      if (bytes.isEmpty) return null;
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(photoUrl);
}
