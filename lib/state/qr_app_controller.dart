import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../models/qr_record.dart';

class QrActionResult {
  const QrActionResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const QrActionResult.ok([String? message]) : this._(true, message);
  const QrActionResult.error(String message) : this._(false, message);
}

class QrAppController extends ChangeNotifier {
  QrAppController() : tabIndexListenable = ValueNotifier<int>(0);

  final ValueNotifier<int> tabIndexListenable;
  String? _lastScan;
  String? _lastGenerated;
  String? _displayName;
  String? _email;
  final List<QrRecord> _history = <QrRecord>[];

  int get tabIndex => tabIndexListenable.value;
  String? get lastScan => _lastScan;
  String? get lastGenerated => _lastGenerated;
  bool get isSignedIn => _displayName != null;
  String? get displayName => _displayName;
  String? get email => _email;
  UnmodifiableListView<QrRecord> get history => UnmodifiableListView(_history);

  void setTabIndex(int value) {
    if (value == tabIndexListenable.value) {
      return;
    }
    tabIndexListenable.value = value;
  }

  QrActionResult addGenerated(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return const QrActionResult.error('Lütfen QR içeriği girin.');
    }
    _lastGenerated = text;
    if (!isSignedIn) {
      notifyListeners();
      return const QrActionResult.ok('Giriş yapmadan geçmişe kaydedilmez.');
    }
    _history.insert(
      0,
      QrRecord(
        type: QrEntryType.generate,
        payload: text,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return const QrActionResult.ok();
  }

  QrActionResult addScan(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return const QrActionResult.error('Taranan değer boş olamaz.');
    }
    _lastScan = text;
    if (!isSignedIn) {
      notifyListeners();
      return const QrActionResult.ok('Giriş yapmadan geçmişe kaydedilmez.');
    }
    _history.insert(
      0,
      QrRecord(
        type: QrEntryType.scan,
        payload: text,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return const QrActionResult.ok();
  }

  void clearHistory() {
    if (_history.isEmpty) {
      return;
    }
    _history.clear();
    notifyListeners();
  }

  QrActionResult signIn({required String name, required String email}) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty) {
      return const QrActionResult.error('Ad soyad gerekli.');
    }
    if (!trimmedEmail.contains('@')) {
      return const QrActionResult.error('Geçerli bir email girin.');
    }
    _displayName = trimmedName;
    _email = trimmedEmail;
    notifyListeners();
    return const QrActionResult.ok();
  }

  void signOut() {
    if (!isSignedIn) {
      return;
    }
    _displayName = null;
    _email = null;
    _lastScan = null;
    _lastGenerated = null;
    _history.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    tabIndexListenable.dispose();
    super.dispose();
  }
}
