import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PickedImage {
  const PickedImage({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
    this.extension,
    this.readStream,
  });

  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
  final String? extension;
  final Stream<List<int>>? readStream;
}

class ImagePickResult {
  const ImagePickResult._({
    required this.ok,
    required this.isCancelled,
    this.message,
    this.image,
  });

  final bool ok;
  final bool isCancelled;
  final String? message;
  final PickedImage? image;

  const ImagePickResult.ok(PickedImage image)
      : this._(ok: true, isCancelled: false, image: image);

  const ImagePickResult.cancelled()
      : this._(ok: false, isCancelled: true);

  const ImagePickResult.error(String message)
      : this._(ok: false, isCancelled: false, message: message);
}

class ImagePickerService {
  Future<ImagePickResult> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        return const ImagePickResult.cancelled();
      }
      final file = result.files.first;
      return ImagePickResult.ok(
        PickedImage(
          name: file.name,
          size: file.size,
          path: file.path,
          bytes: file.bytes,
          extension: file.extension,
          readStream: file.readStream,
        ),
      );
    } on MissingPluginException {
      return const ImagePickResult.error(
        'Görsel seçici yüklenemedi. Uygulamayı kapatıp açın.',
      );
    } catch (_) {
      return const ImagePickResult.error('Görsel seçilemedi.');
    }
  }
}
