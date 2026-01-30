import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'auth_service.dart';
import '../models/saved_qr_record.dart';

class SaveResult {
  const SaveResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const SaveResult.ok([String? message]) : this._(true, message);
  const SaveResult.error(String message) : this._(false, message);
}

abstract class QrStorageService {
  Future<SaveResult> saveQr({
    required String title,
    required String payload,
    required String category,
    required Uint8List imageBytes,
  });

  Stream<List<SavedQrRecord>> watchSavedQrs({
    required String userId,
  });

  void dispose();
}

class FirebaseQrStorageService implements QrStorageService {
  FirebaseQrStorageService(this._storage, this._firestore, this._authService);

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final AuthService _authService;

  @override
  Future<SaveResult> saveQr({
    required String title,
    required String payload,
    required String category,
    required Uint8List imageBytes,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      return const SaveResult.error('Kaydetmek için giriş yapmalısın.');
    }
    final docRef = _firestore.collection('qr_codes').doc();
    final objectPath = '${user.id}/${docRef.id}.png';
    final storageRef = _storage.ref().child('qr_codes/$objectPath');
    try {
      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      await docRef.set({
        'id': docRef.id,
        'user_id': user.id,
        'user_email': user.email,
        'title': title,
        'payload': payload,
        'category': category,
        'image_path': objectPath,
        'image_storage': 'firebase',
        'created_at': FieldValue.serverTimestamp(),
      });
      return const SaveResult.ok();
    } on FirebaseException catch (error) {
      if (error.plugin == 'cloud_firestore') {
        await _safeDelete(storageRef);
      }
      if (error.code == 'permission-denied') {
        return const SaveResult.error(
          'Firestore yazma izni yok. Lütfen kuralları kontrol edin.',
        );
      }
      return SaveResult.error(error.message ?? error.code);
    } catch (error) {
      return SaveResult.error(error.toString());
    }
  }

  @override
  Stream<List<SavedQrRecord>> watchSavedQrs({
    required String userId,
  }) {
    return _firestore
        .collection('qr_codes')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapSavedRecord(doc))
              .toList(growable: false),
        );
  }

  SavedQrRecord _mapSavedRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = _mapDateTime(data['created_at']);
    return SavedQrRecord(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Başlıksız',
      payload: (data['payload'] as String?) ?? '',
      category: (data['category'] as String?) ?? '',
      createdAt: createdAt,
      imagePath: (data['image_path'] as String?) ?? '',
      userEmail: data['user_email'] as String?,
    );
  }

  DateTime _mapDateTime(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void dispose() {}

  Future<void> _safeDelete(Reference ref) async {
    try {
      await ref.delete();
    } catch (_) {}
  }
}

class DisabledQrStorageService implements QrStorageService {
  @override
  Future<SaveResult> saveQr({
    required String title,
    required String payload,
    required String category,
    required Uint8List imageBytes,
  }) async {
    return const SaveResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Stream<List<SavedQrRecord>> watchSavedQrs({
    required String userId,
  }) {
    return const Stream<List<SavedQrRecord>>.empty();
  }

  @override
  void dispose() {}
}

class FakeQrStorageService implements QrStorageService {
  String? lastTitle;
  String? lastPayload;
  String? lastCategory;
  Uint8List? lastImageBytes;
  final List<SavedQrRecord> _items = <SavedQrRecord>[];
  final StreamController<List<SavedQrRecord>> _controller =
      StreamController<List<SavedQrRecord>>.broadcast();

  @override
  Future<SaveResult> saveQr({
    required String title,
    required String payload,
    required String category,
    required Uint8List imageBytes,
  }) async {
    lastTitle = title;
    lastPayload = payload;
    lastCategory = category;
    lastImageBytes = imageBytes;
    final record = SavedQrRecord(
      id: 'local-${_items.length + 1}',
      title: title,
      payload: payload,
      category: category,
      createdAt: DateTime.now(),
      imagePath: 'local-path',
      userEmail: 'user@example.com',
    );
    _items.insert(0, record);
    _controller.add(List<SavedQrRecord>.unmodifiable(_items));
    return const SaveResult.ok();
  }

  @override
  Stream<List<SavedQrRecord>> watchSavedQrs({
    required String userId,
  }) {
    return () async* {
      yield List<SavedQrRecord>.unmodifiable(_items);
      yield* _controller.stream;
    }();
  }

  @override
  void dispose() {
    _controller.close();
  }
}
