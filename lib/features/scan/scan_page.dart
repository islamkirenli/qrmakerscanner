import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/controller_scope.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final MobileScannerController _scannerController;
  String? _lastPayload;
  DateTime? _lastScanAt;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (!mounted) {
      return;
    }
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      return;
    }
    final payload = barcodes.first.rawValue?.trim();
    if (payload == null || payload.isEmpty) {
      _showSnackBar('Taranan değer boş olamaz.');
      return;
    }
    if (_shouldIgnore(payload)) {
      return;
    }
    _lastPayload = payload;
    _lastScanAt = DateTime.now();
    final controller = QrControllerScope.of(context);
    final result = controller.addScan(payload);
    if (!result.ok) {
      _showSnackBar(result.message ?? 'Bilinmeyen hata.');
    } else {
      _showSnackBar(result.message ?? 'QR kaydedildi.');
    }
  }

  bool _shouldIgnore(String payload) {
    final lastScanAt = _lastScanAt;
    if (payload == _lastPayload && lastScanAt != null) {
      final diff = DateTime.now().difference(lastScanAt);
      if (diff < const Duration(seconds: 2)) {
        return true;
      }
    }
    return false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isTest) {
      return const ColoredBox(color: Colors.black12);
    }

    return MobileScanner(
      controller: _scannerController,
      onDetect: _handleDetect,
      errorBuilder: (context, error) {
        return Center(
          child: Text(
            'Kamera erişimi gerekiyor.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
