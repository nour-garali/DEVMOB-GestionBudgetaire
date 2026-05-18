import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Ouvre la galerie ou l'appareil photo et retourne les bytes de l'image.
Future<Uint8List?> pickImageBytes({bool camera = false}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: camera ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 800,
    maxHeight: 800,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return await picked.readAsBytes();
}
