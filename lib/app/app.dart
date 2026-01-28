import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/home/home_page.dart';
import '../state/auth_service.dart';
import '../state/qr_app_controller.dart';
import 'controller_scope.dart';
import 'theme.dart';

class QrApp extends StatefulWidget {
  const QrApp({super.key, required this.isSupabaseReady});

  final bool isSupabaseReady;

  @override
  State<QrApp> createState() => _QrAppState();
}

class _QrAppState extends State<QrApp> {
  late final QrAppController _controller;
  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    final isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isTest) {
      _authService = FakeAuthService();
    } else if (widget.isSupabaseReady) {
      _authService = SupabaseAuthService(Supabase.instance.client);
    } else {
      _authService = DisabledAuthService();
    }
    _controller = QrAppController(authService: _authService);
  }

  @override
  void dispose() {
    _controller.dispose();
    _authService.dispose();
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
