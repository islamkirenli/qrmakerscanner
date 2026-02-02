import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'qr_storage_service.dart';

abstract class QrImageSaver {
  Future<SaveResult> saveToGallery({required String payload});
}

class GalleryQrImageSaver implements QrImageSaver {
  const GalleryQrImageSaver();

  @override
  Future<SaveResult> saveToGallery({required String payload}) async {
    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) {
        return const SaveResult.error('Galeri izni verilmedi.');
      }

      final imageBytes = await _buildQrPng(payload);
      if (imageBytes == null) {
        return const SaveResult.error('QR görseli oluşturulamadı.');
      }

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: 'qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      final isSuccess = result is Map &&
          (result['isSuccess'] == true || result['success'] == true);
      if (!isSuccess) {
        return const SaveResult.error('Görsel kaydedilemedi.');
      }
      return const SaveResult.ok('QR görsellerine kaydedildi.');
    } on MissingPluginException {
      return const SaveResult.error(
        'Galeri eklentisi yüklenemedi. Uygulamayı tamamen kapatıp yeniden başlatın.',
      );
    } catch (_) {
      return const SaveResult.error('Görsel kaydedilirken hata oluştu.');
    }
  }

  Future<bool> _requestGalleryPermission() async {
    if (Platform.isIOS) {
      final addOnlyStatus = await Permission.photosAddOnly.request();
      if (addOnlyStatus.isGranted || addOnlyStatus.isLimited) {
        return true;
      }
      final status = await Permission.photos.request();
      return status.isGranted || status.isLimited;
    }
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt != null && sdkInt >= 33) {
        final photosStatus = await Permission.photos.request();
        return photosStatus.isGranted || photosStatus.isLimited;
      }
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
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

  Future<Uint8List?> _buildQrPng(String payload) async {
    final painter = QrPainter(
      data: payload,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    );
    final imageData = await painter.toImageData(
      900,
      format: ImageByteFormat.png,
    );
    return imageData?.buffer.asUint8List();
  }
}
