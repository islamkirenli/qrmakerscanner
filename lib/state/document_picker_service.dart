import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PickedDocument {
  const PickedDocument({
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

class DocumentPickResult {
  const DocumentPickResult._({
    required this.ok,
    required this.isCancelled,
    this.message,
    this.document,
  });

  final bool ok;
  final bool isCancelled;
  final String? message;
  final PickedDocument? document;

  const DocumentPickResult.ok(PickedDocument document)
      : this._(ok: true, isCancelled: false, document: document);

  const DocumentPickResult.cancelled()
      : this._(ok: false, isCancelled: true);

  const DocumentPickResult.error(String message)
      : this._(ok: false, isCancelled: false, message: message);
}

class DocumentPickerService {
  Future<DocumentPickResult> pickDocument() async {
    try {
      final hasPermission = await _requestDocumentPermission();
      if (!hasPermission) {
        return const DocumentPickResult.error('Doküman izni verilmedi.');
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        return const DocumentPickResult.cancelled();
      }
      final file = result.files.first;
      return DocumentPickResult.ok(
        PickedDocument(
          name: file.name,
          size: file.size,
          path: file.path,
          bytes: file.bytes,
          extension: file.extension,
          readStream: file.readStream,
        ),
      );
    } on MissingPluginException {
      return const DocumentPickResult.error(
        'Dosya seçici yüklenemedi. Uygulamayı kapatıp açın.',
      );
    } catch (_) {
      return const DocumentPickResult.error('Doküman seçilemedi.');
    }
  }

  Future<bool> _requestDocumentPermission() async {
    if (kIsWeb) {
      return true;
    }
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt != null && sdkInt >= 33) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return null;
    }
  }
}
