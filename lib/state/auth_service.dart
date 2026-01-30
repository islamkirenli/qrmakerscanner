import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String? email;
  final String? displayName;
}

class AuthResult {
  const AuthResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const AuthResult.ok([String? message]) : this._(true, message);
  const AuthResult.error(String message) : this._(false, message);
}

abstract class AuthService {
  AuthUser? get currentUser;
  Stream<AuthUser?> get onAuthStateChanged;

  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  void dispose();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get onAuthStateChanged =>
      _auth.authStateChanges().map(_mapUser);

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return const AuthResult.ok();
    } on FirebaseAuthException catch (error) {
      return AuthResult.error(error.message ?? 'Giriş sırasında hata oluştu.');
    } catch (_) {
      return const AuthResult.error('Giriş sırasında hata oluştu.');
    }
  }

  @override
  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.sendEmailVerification();
      return const AuthResult.ok('Kayıt başarılı. Email doğrulamasını kontrol et.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.error(error.message ?? 'Kayıt sırasında hata oluştu.');
    } catch (_) {
      return const AuthResult.error('Kayıt sırasında hata oluştu.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {}

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}

class DisabledAuthService implements AuthService {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> get onAuthStateChanged => _controller.stream;

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return const AuthResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return const AuthResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

class FakeAuthService implements AuthService {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get onAuthStateChanged => _controller.stream;

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(id: 'test-user', email: email, displayName: null);
    _controller.add(_user);
    return const AuthResult.ok();
  }

  @override
  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _user = AuthUser(id: 'test-user', email: email, displayName: null);
    _controller.add(_user);
    return const AuthResult.ok();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
