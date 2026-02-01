import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class ProfileResult {
  const ProfileResult._(this.ok, this.message);

  final bool ok;
  final String? message;

  const ProfileResult.ok([String? message]) : this._(true, message);
  const ProfileResult.error(String message) : this._(false, message);
}

abstract class ProfileService {
  Future<UserProfile?> fetchProfile({
    required String userId,
    required String email,
  });

  Future<ProfileResult> saveProfile({
    required UserProfile profile,
  });

  void dispose();
}

class FirebaseProfileService implements ProfileService {
  FirebaseProfileService(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile?> fetchProfile({
    required String userId,
    required String email,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) {
        return UserProfile(
          userId: userId,
          email: email,
          firstName: '',
          lastName: '',
          avatarIndex: 0,
          lastScan: null,
          lastGenerated: null,
        );
      }
      return UserProfile(
        userId: userId,
        email: (data['email'] as String?) ?? email,
        firstName: (data['first_name'] as String?) ?? '',
        lastName: (data['last_name'] as String?) ?? '',
        avatarIndex: (data['avatar_index'] as int?) ?? 0,
        lastScan: data['last_scan'] as String?,
        lastGenerated: data['last_generated'] as String?,
      );
    } on FirebaseException catch (error) {
      throw error;
    }
  }

  @override
  Future<ProfileResult> saveProfile({
    required UserProfile profile,
  }) async {
    try {
      await _firestore.collection('users').doc(profile.userId).set({
        'user_id': profile.userId,
        'email': profile.email,
        'first_name': profile.firstName,
        'last_name': profile.lastName,
        'avatar_index': profile.avatarIndex,
        'last_scan': profile.lastScan,
        'last_generated': profile.lastGenerated,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return const ProfileResult.ok();
    } on FirebaseException catch (error) {
      return ProfileResult.error(error.message ?? error.code);
    } catch (error) {
      return ProfileResult.error(error.toString());
    }
  }

  @override
  void dispose() {}
}

class DisabledProfileService implements ProfileService {
  @override
  Future<UserProfile?> fetchProfile({
    required String userId,
    required String email,
  }) async {
    return null;
  }

  @override
  Future<ProfileResult> saveProfile({
    required UserProfile profile,
  }) async {
    return const ProfileResult.error('Firebase yapılandırılmadı.');
  }

  @override
  void dispose() {}
}

class FakeProfileService implements ProfileService {
  UserProfile? storedProfile;

  @override
  Future<UserProfile?> fetchProfile({
    required String userId,
    required String email,
  }) async {
    return storedProfile ??
        UserProfile(
          userId: userId,
          email: email,
          firstName: '',
          lastName: '',
          avatarIndex: 0,
          lastScan: null,
          lastGenerated: null,
        );
  }

  @override
  Future<ProfileResult> saveProfile({
    required UserProfile profile,
  }) async {
    storedProfile = profile;
    return const ProfileResult.ok();
  }

  @override
  void dispose() {}
}
