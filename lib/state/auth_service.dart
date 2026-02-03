import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  Future<AuthResult> signInWithGoogle();

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthResult> reauthenticate({
    required String currentPassword,
  });

  Future<AuthResult> deleteCurrentUser();

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
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return const AuthResult.error('Google giriş iptal edildi.');
      }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        return const AuthResult.error('Google kimlik doğrulaması alınamadı.');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (error) {
      debugPrint('Google sign-in FirebaseAuthException: '
          '${error.code} ${error.message}');
      return AuthResult.error(error.message ?? 'Google ile giriş başarısız.');
    } catch (error, stackTrace) {
      debugPrint('Google sign-in error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const AuthResult.error('Google ile giriş başarısız.');
    }
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        return const AuthResult.error('Önce giriş yapmalısın.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return const AuthResult.ok('Şifre güncellendi.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.error(error.message ?? 'Şifre güncellenemedi.');
    } catch (_) {
      return const AuthResult.error('Şifre güncellenemedi.');
    }
  }

  @override
  Future<AuthResult> reauthenticate({
    required String currentPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        return const AuthResult.error('Önce giriş yapmalısın.');
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      return const AuthResult.ok();
    } on FirebaseAuthException catch (error) {
      return AuthResult.error(error.message ?? 'Yeniden doğrulama başarısız.');
    } catch (_) {
      return const AuthResult.error('Yeniden doğrulama başarısız.');
    }
  }

  @override
  Future<AuthResult> deleteCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthResult.error('Önce giriş yapmalısın.');
      }
      await user.delete();
      return const AuthResult.ok('Hesap silindi.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.error(error.message ?? 'Hesap silinemedi.');
    } catch (_) {
      return const AuthResult.error('Hesap silinemedi.');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
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
  Future<AuthResult> signInWithGoogle() async {
    return const AuthResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const AuthResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Future<AuthResult> reauthenticate({
    required String currentPassword,
  }) async {
    return const AuthResult.error('Firebase yapılandırılmadı.');
  }

  @override
  Future<AuthResult> deleteCurrentUser() async {
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
  int googleSignInCount = 0;

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
  Future<AuthResult> signInWithGoogle() async {
    googleSignInCount += 1;
    _user = const AuthUser(id: 'google-user', email: null, displayName: 'Google');
    _controller.add(_user);
    return const AuthResult.ok();
  }

  @override
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_user == null) {
      return const AuthResult.error('Önce giriş yapmalısın.');
    }
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return const AuthResult.error('Şifre gerekli.');
    }
    return const AuthResult.ok('Şifre güncellendi.');
  }

  @override
  Future<AuthResult> reauthenticate({
    required String currentPassword,
  }) async {
    if (_user == null) {
      return const AuthResult.error('Önce giriş yapmalısın.');
    }
    if (currentPassword.isEmpty) {
      return const AuthResult.error('Şifre gerekli.');
    }
    return const AuthResult.ok();
  }

  @override
  Future<AuthResult> deleteCurrentUser() async {
    if (_user == null) {
      return const AuthResult.error('Önce giriş yapmalısın.');
    }
    _user = null;
    _controller.add(null);
    return const AuthResult.ok('Hesap silindi.');
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
