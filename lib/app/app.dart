import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../features/home/home_page.dart';
import '../state/auth_service.dart';
import '../state/qr_storage_service.dart';
import '../state/qr_app_controller.dart';
import '../state/profile_service.dart';
import 'controller_scope.dart';
import 'theme.dart';

class QrApp extends StatefulWidget {
  const QrApp({
    super.key,
    required this.isFirebaseReady,
    this.authServiceOverride,
    this.storageServiceOverride,
    this.profileServiceOverride,
  });

  final bool isFirebaseReady;
  final AuthService? authServiceOverride;
  final QrStorageService? storageServiceOverride;
  final ProfileService? profileServiceOverride;

  @override
  State<QrApp> createState() => _QrAppState();
}

class _QrAppState extends State<QrApp> {
  late final QrAppController _controller;
  late final AuthService _authService;
  late final QrStorageService _storageService;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    final isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (widget.authServiceOverride != null) {
      _authService = widget.authServiceOverride!;
    } else if (isTest) {
      _authService = FakeAuthService();
    } else if (widget.isFirebaseReady) {
      _authService = FirebaseAuthService(FirebaseAuth.instance);
    } else {
      _authService = DisabledAuthService();
    }
    if (widget.storageServiceOverride != null) {
      _storageService = widget.storageServiceOverride!;
    } else if (isTest) {
      _storageService = FakeQrStorageService();
    } else if (widget.isFirebaseReady) {
      _storageService = FirebaseQrStorageService(
        FirebaseStorage.instance,
        FirebaseFirestore.instance,
        _authService,
      );
    } else {
      _storageService = DisabledQrStorageService();
    }
    if (widget.profileServiceOverride != null) {
      _profileService = widget.profileServiceOverride!;
    } else if (isTest) {
      _profileService = FakeProfileService();
    } else if (widget.isFirebaseReady) {
      _profileService = FirebaseProfileService(FirebaseFirestore.instance);
    } else {
      _profileService = DisabledProfileService();
    }
    _controller = QrAppController(
      authService: _authService,
      storageService: _storageService,
      profileService: _profileService,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _authService.dispose();
    _storageService.dispose();
    _profileService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QrControllerScope(
      controller: _controller,
      child: MaterialApp(
        title: 'QR Maker & Scanner',
        theme: buildQrTheme(),
        debugShowCheckedModeBanner: false,
        home: const QrHomePage(),
      ),
    );
  }
}
