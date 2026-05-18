// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:typed_data';

/// Ouvre le sélecteur de fichiers, redimensionne l'image (max 800px) et retourne les bytes.
Future<Uint8List?> pickImageBytes({bool camera = false}) async {
  final completer = Completer<Uint8List?>();

  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  input.onChange.listen((event) {
    if (input.files!.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = input.files![0];
    final reader = html.FileReader();

    reader.onLoad.listen((e) {
      final img = html.ImageElement();
      img.src = html.Url.createObjectUrlFromBlob(file);

      img.onLoad.listen((_) {
        // Redimensionnement via Canvas pour la performance Web
        const int maxWidth = 800;
        int width = img.width!;
        int height = img.height!;

        if (width > maxWidth) {
          double ratio = maxWidth / width;
          width = maxWidth;
          height = (height * ratio).toInt();
        }

        final canvas = html.CanvasElement(width: width, height: height);
        canvas.context2D.drawImageScaled(img, 0, 0, width, height);
        
        // Conversion du canvas en Blob puis en Bytes
        canvas.toBlob('image/jpeg', 0.8).then((blob) {
          final readerBlob = html.FileReader();
          readerBlob.onLoad.listen((_) {
            completer.complete(readerBlob.result as Uint8List);
            html.Url.revokeObjectUrl(img.src!); // Nettoyage mémoire
          });
          readerBlob.readAsArrayBuffer(blob);
        });
      });
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();

  return completer.future.timeout(
    const Duration(minutes: 1),
    onTimeout: () => null,
  );
}
