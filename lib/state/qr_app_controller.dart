import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/qr_record.dart';

class QrActionResult {
  const QrActionResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const QrActionResult.ok([String? message]) : this._(true, message);
  const QrActionResult.error(String message) : this._(false, message);
}

class QrAppController extends ChangeNotifier {
  QrAppController({required AuthService authService})
      : _authService = authService,
        tabIndexListenable = ValueNotifier<int>(0) {
    _currentUser = _authService.currentUser;
    _syncUser(_currentUser);
    _authSubscription = _authService.onAuthStateChanged.listen(_syncUser);
  }

  final ValueNotifier<int> tabIndexListenable;
  final AuthService _authService;
  late final StreamSubscription<AuthUser?> _authSubscription;
  String? _lastScan;
  String? _lastGenerated;
  AuthUser? _currentUser;
  final List<QrRecord> _history = <QrRecord>[];

  int get tabIndex => tabIndexListenable.value;
  String? get lastScan => _lastScan;
  String? get lastGenerated => _lastGenerated;
  bool get isSignedIn => _currentUser != null;
  String? get displayName => _currentUser?.displayName ?? _currentUser?.email;
  String? get email => _currentUser?.email;
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

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return const AuthResult.error('Email gerekli.');
    }
    if (!trimmedEmail.contains('@')) {
      return const AuthResult.error('Geçerli bir email girin.');
    }
    if (password.trim().isEmpty) {
      return const AuthResult.error('Şifre gerekli.');
    }
    return _authService.signInWithEmailPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return const AuthResult.error('Email gerekli.');
    }
    if (!trimmedEmail.contains('@')) {
      return const AuthResult.error('Geçerli bir email girin.');
    }
    if (password.trim().isEmpty) {
      return const AuthResult.error('Şifre gerekli.');
    }
    if (password.trim().length < 6) {
      return const AuthResult.error('Şifre en az 6 karakter olmalı.');
    }
    return _authService.signUpWithEmailPassword(
      email: trimmedEmail,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (!isSignedIn) {
      return;
    }
    await _authService.signOut();
  }

  void _syncUser(AuthUser? user) {
    final wasSignedIn = _currentUser != null;
    _currentUser = user;
    if (user == null && wasSignedIn) {
      _lastScan = null;
      _lastGenerated = null;
      _history.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    tabIndexListenable.dispose();
    super.dispose();
  }
}
