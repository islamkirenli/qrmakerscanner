import 'package:flutter/material.dart';
import '../features/home/home_page.dart';
import '../state/qr_app_controller.dart';
import 'controller_scope.dart';
import 'theme.dart';

class QrApp extends StatefulWidget {
  const QrApp({super.key});

  @override
  State<QrApp> createState() => _QrAppState();
}

class _QrAppState extends State<QrApp> {
  late final QrAppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QrAppController();
  }

  @override
  void dispose() {
    _controller.dispose();
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
