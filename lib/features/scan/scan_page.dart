import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/controller_scope.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({
    super.key,
    this.debugPayloadListenable,
    this.launchUriOverride,
  });

  final ValueNotifier<String?>? debugPayloadListenable;
  final Future<bool> Function(Uri uri)? launchUriOverride;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final MobileScannerController _scannerController;
  String? _lastPayload;
  DateTime? _lastScanAt;
  bool _isTorchOn = false;
  bool _isHandlingPayload = false;
  VoidCallback? _debugListener;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    final debugListenable = widget.debugPayloadListenable;
    if (debugListenable != null) {
      _debugListener = () {
        final payload = debugListenable.value;
        if (payload == null || payload.trim().isEmpty) {
          return;
        }
        _handlePayload(payload);
      };
      debugListenable.addListener(_debugListener!);
    }
  }

  @override
  void dispose() {
    final debugListenable = widget.debugPayloadListenable;
    if (debugListenable != null && _debugListener != null) {
      debugListenable.removeListener(_debugListener!);
    }
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
    _handlePayload(payload);
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

  Future<void> _handlePayload(String payload) async {
    if (_isHandlingPayload) {
      return;
    }
    final uri = _resolvePayloadUri(payload);
    if (uri == null) {
      return;
    }
    _isHandlingPayload = true;
    try {
      final launched = await (widget.launchUriOverride?.call(uri) ??
          launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!launched) {
        _showSnackBar('Bu içerik açılamadı.');
      }
    } catch (_) {
      _showSnackBar('Bu içerik açılamadı.');
    } finally {
      _isHandlingPayload = false;
    }
  }

  Uri? _resolvePayloadUri(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('www.')) {
      return Uri.tryParse('https://$trimmed');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return null;
    }
    if (!uri.hasScheme) {
      return null;
    }
    return uri;
  }

  Future<void> _toggleTorch({required bool isTest}) async {
    if (isTest) {
      setState(() => _isTorchOn = !_isTorchOn);
      return;
    }
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {
      _showSnackBar('Flaş değiştirilemedi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const isTest = bool.fromEnvironment('FLUTTER_TEST');
    final scanner = isTest
        ? const ColoredBox(color: Colors.black12)
        : MobileScanner(
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

    return Stack(
      children: [
        Positioned.fill(child: scanner),
        Positioned(
          left: 0,
          right: 0,
          bottom: 15,
          child: Center(
            child: IconButton.filled(
              key: const ValueKey('scanTorchButton'),
              onPressed: () => _toggleTorch(isTest: isTest),
              iconSize: 36,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              icon: Icon(
                _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
