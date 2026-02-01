import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'qr_storage_service.dart';
import 'profile_service.dart';
import '../models/qr_record.dart';
import '../models/saved_qr_record.dart';
import '../models/user_profile.dart';

class QrActionResult {
  const QrActionResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const QrActionResult.ok([String? message]) : this._(true, message);
  const QrActionResult.error(String message) : this._(false, message);
}

class QrAppController extends ChangeNotifier {
  QrAppController({
    required AuthService authService,
    required QrStorageService storageService,
    required ProfileService profileService,
  })  : _authService = authService,
        _storageService = storageService,
        _profileService = profileService,
        tabIndexListenable = ValueNotifier<int>(0) {
    _currentUser = _authService.currentUser;
    _syncUser(_currentUser);
    _authSubscription = _authService.onAuthStateChanged.listen(_syncUser);
  }

  final ValueNotifier<int> tabIndexListenable;
  final AuthService _authService;
  final QrStorageService _storageService;
  final ProfileService _profileService;
  late final StreamSubscription<AuthUser?> _authSubscription;
  StreamSubscription<List<SavedQrRecord>>? _historySubscription;
  String? _lastScan;
  String? _lastGenerated;
  AuthUser? _currentUser;
  UserProfile? _profile;
  bool _isProfileLoading = false;
  String? _profileError;
  final List<QrRecord> _history = <QrRecord>[];
  List<SavedQrRecord> _savedHistory = <SavedQrRecord>[];
  bool _isHistoryLoading = false;
  String? _historyError;
  bool _isSelectionMode = false;
  bool _isDeleting = false;
  final Set<String> _selectedIds = <String>{};

  int get tabIndex => tabIndexListenable.value;
  String? get lastScan => _lastScan;
  String? get lastGenerated => _lastGenerated;
  bool get isSignedIn => _currentUser != null;
  String? get displayName => _currentUser?.displayName ?? _currentUser?.email;
  String? get email => _currentUser?.email;
  UserProfile? get profile => _profile;
  bool get isProfileLoading => _isProfileLoading;
  String? get profileError => _profileError;
  UnmodifiableListView<QrRecord> get history => UnmodifiableListView(_history);
  UnmodifiableListView<SavedQrRecord> get savedHistory =>
      UnmodifiableListView(_savedHistory);
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;
  bool get isSelectionMode => _isSelectionMode;
  bool get isDeleting => _isDeleting;
  int get selectedCount => _selectedIds.length;

  bool isSelected(String id) => _selectedIds.contains(id);

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

  Future<SaveResult> saveGenerated({
    required String title,
    required String payload,
    required String category,
    required Uint8List imageBytes,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Future.value(const SaveResult.error('Başlık gerekli.'));
    }
    return _storageService.saveQr(
      title: trimmedTitle,
      payload: payload,
      category: category,
      imageBytes: imageBytes,
    );
  }

  void _syncUser(AuthUser? user) {
    final wasSignedIn = _currentUser != null;
    _currentUser = user;
    if (user == null && wasSignedIn) {
      _lastScan = null;
      _lastGenerated = null;
      _profile = null;
      _isProfileLoading = false;
      _profileError = null;
      _history.clear();
      _historySubscription?.cancel();
      _historySubscription = null;
      _savedHistory = <SavedQrRecord>[];
      _isHistoryLoading = false;
      _historyError = null;
      _isSelectionMode = false;
      _isDeleting = false;
      _selectedIds.clear();
    }
    if (user != null) {
      _startHistorySync(user);
      _loadProfile(user);
    }
    notifyListeners();
  }

  Future<void> _loadProfile(AuthUser user) async {
    _isProfileLoading = true;
    _profileError = null;
    notifyListeners();
    try {
      final loadedProfile = await _profileService.fetchProfile(
        userId: user.id,
        email: user.email ?? '',
      );
      _profile = loadedProfile ??
          UserProfile(
            userId: user.id,
            email: user.email ?? '',
            firstName: '',
            lastName: '',
            avatarIndex: 0,
          );
      _isProfileLoading = false;
      _profileError = null;
      notifyListeners();
    } catch (_) {
      _isProfileLoading = false;
      _profileError = 'Profil yüklenemedi.';
      notifyListeners();
    }
  }

  Future<ProfileResult> saveProfile({
    required String firstName,
    required String lastName,
    required int avatarIndex,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return const ProfileResult.error('Giriş yapmadan kaydedilemez.');
    }
    final profile = UserProfile(
      userId: user.id,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      avatarIndex: avatarIndex,
    );
    final result = await _profileService.saveProfile(profile: profile);
    if (result.ok) {
      _profile = profile;
      notifyListeners();
    }
    return result;
  }

  void retryProfile() {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    _loadProfile(user);
  }

  void _startHistorySync(AuthUser user) {
    _historySubscription?.cancel();
    _isHistoryLoading = true;
    _historyError = null;
    _savedHistory = <SavedQrRecord>[];
    _isSelectionMode = false;
    _isDeleting = false;
    _selectedIds.clear();
    _historySubscription = _storageService
        .watchSavedQrs(userId: user.id)
        .listen((items) {
      _savedHistory = items;
      if (_selectedIds.isNotEmpty) {
        final ids = items.map((item) => item.id).toSet();
        _selectedIds.removeWhere((id) => !ids.contains(id));
      }
      _isHistoryLoading = false;
      _historyError = null;
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('History load failed: $error');
      debugPrint('History load stack: $stackTrace');
      _isHistoryLoading = false;
      _historyError = 'Geçmiş yüklenemedi. Lütfen tekrar deneyin.';
      notifyListeners();
    });
  }

  void retryHistory() {
    final user = _currentUser;
    if (user == null) {
      return;
    }
    _startHistorySync(user);
    notifyListeners();
  }

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (!_isSelectionMode) {
      return;
    }
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isEmpty) {
      return;
    }
    _selectedIds.clear();
    notifyListeners();
  }

  Future<DeleteResult> deleteSelected() async {
    if (_currentUser == null) {
      return const DeleteResult.error('Giriş yapmalısın.');
    }
    if (_selectedIds.isEmpty) {
      return const DeleteResult.error('Silmek için seçim yapmalısın.');
    }
    _isDeleting = true;
    notifyListeners();
    final items = _savedHistory
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    final result = await _storageService.deleteQrs(items: items);
    _isDeleting = false;
    if (result.ok) {
      _isSelectionMode = false;
      _selectedIds.clear();
    }
    notifyListeners();
    return result;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _historySubscription?.cancel();
    tabIndexListenable.dispose();
    super.dispose();
  }
}
