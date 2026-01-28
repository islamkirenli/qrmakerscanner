import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

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

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AuthUser?> get onAuthStateChanged =>
      _client.auth.onAuthStateChange.map((data) => _mapUser(data.session?.user));

  @override
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return const AuthResult.ok();
    } on AuthException catch (error) {
      return AuthResult.error(error.message);
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
      await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.emailRedirectUrl,
      );
      return const AuthResult.ok('Kayıt başarılı. Email doğrulamasını kontrol et.');
    } on AuthException catch (error) {
      return AuthResult.error(error.message);
    } catch (_) {
      return const AuthResult.error('Kayıt sırasında hata oluştu.');
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void dispose() {}

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }
    final metadata = user.userMetadata;
    String? displayName;
    if (metadata is Map<String, dynamic>) {
      displayName = metadata['full_name'] as String?;
    }
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: displayName,
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
    return const AuthResult.error('Supabase yapılandırılmadı.');
  }

  @override
  Future<AuthResult> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return const AuthResult.error('Supabase yapılandırılmadı.');
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
