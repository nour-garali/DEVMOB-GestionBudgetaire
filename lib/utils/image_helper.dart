/// Point d'entrée cross-platform pour la sélection d'image.
/// Sur Web  → utilise dart:html (image_helper_web.dart)
/// Sur Mobile → utilise image_picker (image_helper_io.dart)
library image_helper;

export 'image_helper_web.dart'
    if (dart.library.io) 'image_helper_io.dart';
