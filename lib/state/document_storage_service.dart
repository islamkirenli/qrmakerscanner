import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

class DocumentUploadResult {
  const DocumentUploadResult._(
    this.ok,
    this.message,
    this.downloadUrl,
    this.storagePath,
  );

  final bool ok;
  final String? message;
  final String? downloadUrl;
  final String? storagePath;

  const DocumentUploadResult.ok({
    required String downloadUrl,
    required String storagePath,
  }) : this._(true, null, downloadUrl, storagePath);

  const DocumentUploadResult.error(String message)
      : this._(false, message, null, null);
}

abstract class DocumentStorageService {
  Future<DocumentUploadResult> uploadDocument({
    required String name,
    String? path,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
    String? contentType,
    ValueChanged<double>? onProgress,
  });
}

class FirebaseDocumentStorageService implements DocumentStorageService {
  FirebaseDocumentStorageService(this._storage, this._authService);

  final FirebaseStorage _storage;
  final AuthService _authService;

  @override
  Future<DocumentUploadResult> uploadDocument({
    required String name,
    String? path,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
    String? contentType,
    ValueChanged<double>? onProgress,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      return const DocumentUploadResult.error('Yüklemek için giriş yapmalısın.');
    }
    final safeName = _sanitizeFileName(name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '${user.id}/$timestamp-$safeName';
    final storageRef = _storage.ref().child('documents/$objectPath');
    try {
      final metadata = SettableMetadata(
        contentType: contentType ?? 'application/octet-stream',
      );
      UploadTask task;
      File? tempFile;
      if (bytes != null) {
        task = storageRef.putData(bytes, metadata);
      } else if (path != null && path.isNotEmpty) {
        if (kIsWeb) {
          return const DocumentUploadResult.error('Web için dosya verisi yok.');
        }
        final file = File(path);
        final exists = await file.exists();
        if (exists) {
          task = storageRef.putFile(file, metadata);
        } else if (readStream != null) {
          tempFile = await _writeStreamToTempFile(
            readStream,
            _sanitizeFileName(name),
          );
          task = storageRef.putFile(tempFile, metadata);
        } else {
          return const DocumentUploadResult.error('Dosya bulunamadı.');
        }
      } else if (readStream != null) {
        tempFile = await _writeStreamToTempFile(
          readStream,
          _sanitizeFileName(name),
        );
        task = storageRef.putFile(tempFile, metadata);
      } else {
        return const DocumentUploadResult.error('Dosya verisi bulunamadı.');
      }
      task.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total <= 0) {
          return;
        }
        final progress = snapshot.bytesTransferred / total;
        onProgress?.call(progress.clamp(0, 1));
      });
      await task;
      if (tempFile != null) {
        await _safeDeleteTemp(tempFile);
      }
      final url = await storageRef.getDownloadURL();
      return DocumentUploadResult.ok(
        downloadUrl: url,
        storagePath: objectPath,
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        return const DocumentUploadResult.error(
          'Storage yazma izni yok. Kuralları kontrol edin.',
        );
      }
      return DocumentUploadResult.error(error.message ?? error.code);
    } catch (error) {
      return DocumentUploadResult.error(error.toString());
    }
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\/]+'), '_').trim();
    return sanitized.isEmpty ? 'document' : sanitized;
  }

  Future<File> _writeStreamToTempFile(
    Stream<List<int>> stream,
    String fileName,
  ) async {
    final dir = await Directory.systemTemp.createTemp('qr_upload_');
    final tempFile = File('${dir.path}/$fileName');
    final sink = tempFile.openWrite();
    await sink.addStream(stream);
    await sink.close();
    return tempFile;
  }

  Future<void> _safeDeleteTemp(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    try {
      final dir = file.parent;
      if (await dir.exists()) {
        await dir.delete();
      }
    } catch (_) {}
  }
}

class DisabledDocumentStorageService implements DocumentStorageService {
  @override
  Future<DocumentUploadResult> uploadDocument({
    required String name,
    String? path,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
    String? contentType,
    ValueChanged<double>? onProgress,
  }) async {
    return const DocumentUploadResult.error('Firebase yapılandırılmadı.');
  }
}

class FakeDocumentStorageService implements DocumentStorageService {
  String? lastName;
  String? lastPath;
  Uint8List? lastBytes;
  String? lastContentType;

  @override
  Future<DocumentUploadResult> uploadDocument({
    required String name,
    String? path,
    Uint8List? bytes,
    Stream<List<int>>? readStream,
    String? contentType,
    ValueChanged<double>? onProgress,
  }) async {
    lastName = name;
    lastPath = path;
    lastBytes = bytes;
    lastContentType = contentType;
    onProgress?.call(1);
    return const DocumentUploadResult.ok(
      downloadUrl: 'https://example.com/document.pdf',
      storagePath: 'test/document.pdf',
    );
  }
}
