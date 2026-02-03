import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/controller_scope.dart';
import '../../state/document_picker_service.dart';
import '../../state/image_picker_service.dart';
import '../../state/qr_image_saver.dart';
import '../account/account_page.dart';
import 'generate_category.dart';

enum SocialPlatform {
  instagram('Instagram', 'https://instagram.com/', Icons.camera_alt_outlined),
  x('X', 'https://x.com/', Icons.alternate_email),
  tiktok('TikTok', 'https://www.tiktok.com/@', Icons.music_note_outlined),
  linkedin('LinkedIn', 'https://www.linkedin.com/in/', Icons.work_outline),
  youtube('YouTube', 'https://www.youtube.com/@', Icons.play_circle_outline),
  facebook('Facebook', 'https://www.facebook.com/', Icons.thumb_up_alt_outlined),
  whatsapp('WhatsApp', 'https://wa.me/', Icons.chat_outlined),
  telegram('Telegram', 'https://t.me/', Icons.send_outlined),
  snapchat('Snapchat', 'https://www.snapchat.com/add/', Icons.camera_front),
  pinterest('Pinterest', 'https://www.pinterest.com/', Icons.push_pin_outlined),
  reddit('Reddit', 'https://www.reddit.com/user/', Icons.forum_outlined),
  github('GitHub', 'https://github.com/', Icons.code_outlined),
  medium('Medium', 'https://medium.com/@', Icons.article_outlined),
  twitch('Twitch', 'https://www.twitch.tv/', Icons.videogame_asset_outlined),
  discord('Discord', 'https://discord.com/users/', Icons.headset_mic_outlined),
  spotify('Spotify', 'https://open.spotify.com/user/', Icons.music_note);

  const SocialPlatform(this.label, this.baseUrl, this.icon);

  final String label;
  final String baseUrl;
  final IconData icon;
}

enum _WifiSecurity {
  wpaAuto,
  wep,
  nopass,
}

class GenerateDetailPage extends StatefulWidget {
  const GenerateDetailPage({
    super.key,
    required this.category,
    this.imageSaver,
    this.documentPicker,
    this.imagePicker,
  });

  final GenerateCategoryInfo category;
  final QrImageSaver? imageSaver;
  final DocumentPickerService? documentPicker;
  final ImagePickerService? imagePicker;

  @override
  State<GenerateDetailPage> createState() => _GenerateDetailPageState();
}

class _GenerateDetailPageState extends State<GenerateDetailPage> {
  static const int _maxDocumentBytes = 15 * 1024 * 1024;
  static const String _maxDocumentLabel = 'Maksimum 15 MB';
  static const _documentPreviewTypes = {
    GenerateCategoryType.text,
    GenerateCategoryType.url,
    GenerateCategoryType.email,
    GenerateCategoryType.vcard,
    GenerateCategoryType.wifi,
    GenerateCategoryType.social,
    GenerateCategoryType.document,
    GenerateCategoryType.image,
  };

  late final TextEditingController _textController;
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _faxController;
  late final TextEditingController _vcardEmailController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _streetController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _websiteController;
  late final TextEditingController _socialController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;
  _WifiSecurity _wifiSecurity = _WifiSecurity.wpaAuto;
  bool _wifiHidden = false;
  SocialPlatform _socialPlatform = SocialPlatform.instagram;
  String? _generatedPayload;
  final ValueNotifier<bool> _isDownloading = ValueNotifier<bool>(false);
  final ValueNotifier<DocumentUploadState> _documentUploadState =
      ValueNotifier<DocumentUploadState>(const DocumentUploadState.idle());
  final ValueNotifier<DocumentUploadState> _imageUploadState =
      ValueNotifier<DocumentUploadState>(const DocumentUploadState.idle());
  late final QrImageSaver _imageSaver;
  late final DocumentPickerService _documentPicker;
  late final ImagePickerService _imagePicker;

  @override
  void initState() {
    super.initState();
    _imageSaver = widget.imageSaver ?? const GalleryQrImageSaver();
    _documentPicker = widget.documentPicker ?? DocumentPickerService();
    _imagePicker = widget.imagePicker ?? ImagePickerService();
    _textController = TextEditingController();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _faxController = TextEditingController();
    _vcardEmailController = TextEditingController();
    _companyController = TextEditingController();
    _jobTitleController = TextEditingController();
    _streetController = TextEditingController();
    _neighborhoodController = TextEditingController();
    _cityController = TextEditingController();
    _districtController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
    _websiteController = TextEditingController();
    _socialController = TextEditingController();
    _ssidController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _faxController.dispose();
    _vcardEmailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _streetController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _socialController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    _isDownloading.dispose();
    _documentUploadState.dispose();
    _imageUploadState.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final payload = _generatedPayload;
    if (payload == null) {
      _showSnackBar('İndirilecek QR bulunamadı.');
      return;
    }
    if (_isDownloading.value) {
      return;
    }
    _isDownloading.value = true;
    final result = await _imageSaver.saveToGallery(payload: payload);
    _isDownloading.value = false;
    if (!mounted) {
      return;
    }
    _showSnackBar(
      result.message ?? (result.ok ? 'QR görsellere kaydedildi.' : 'Kayıt başarısız.'),
    );
  }

  void _handleGenerate() {
    if (widget.category.type == GenerateCategoryType.document &&
        _documentUploadState.value.isLoading) {
      _showSnackBar('Yükleme tamamlanmadan QR oluşturulamaz.');
      return;
    }
    if (widget.category.type == GenerateCategoryType.image &&
        _imageUploadState.value.isLoading) {
      _showSnackBar('Yükleme tamamlanmadan QR oluşturulamaz.');
      return;
    }
    final payload = _buildPayload();
    if (payload == null) {
      return;
    }
    final controller = QrControllerScope.of(context);
    final result = controller.addGenerated(payload);
    if (!result.ok) {
      _showSnackBar(result.message ?? 'Bilinmeyen hata.');
      return;
    }
    if (_documentPreviewTypes.contains(widget.category.type)) {
      setState(() => _generatedPayload = payload);
    }
  }

  String? _buildPayload() {
    switch (widget.category.type) {
      case GenerateCategoryType.text:
        final text = _textController.text.trim();
        if (text.isEmpty) {
          _showSnackBar('Metin boş olamaz.');
          return null;
        }
        return text;
      case GenerateCategoryType.url:
        final text = _textController.text.trim();
        if (text.isEmpty) {
          _showSnackBar('URL boş olamaz.');
          return null;
        }
        final normalizedUrl = _normalizeUrl(text);
        if (normalizedUrl == null) {
          _showSnackBar('Geçerli bir URL girin.');
          return null;
        }
        return normalizedUrl;
      case GenerateCategoryType.email:
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          _showSnackBar('Email boş olamaz.');
          return null;
        }
        if (!email.contains('@')) {
          _showSnackBar('Geçerli bir email girin.');
          return null;
        }
        final subject = Uri.encodeComponent(_subjectController.text.trim());
        final body = Uri.encodeComponent(_bodyController.text.trim());
        final query = [
          if (subject.isNotEmpty) 'subject=$subject',
          if (body.isNotEmpty) 'body=$body',
        ].join('&');
        return query.isEmpty ? 'mailto:$email' : 'mailto:$email?$query';
      case GenerateCategoryType.vcard:
        final name = _fullNameController.text.trim();
        if (name.isEmpty) {
          _showSnackBar('Ad soyad gerekli.');
          return null;
        }
        final phone = _phoneController.text.trim();
        final fax = _faxController.text.trim();
        final email = _vcardEmailController.text.trim();
        if (phone.isEmpty && email.isEmpty) {
          _showSnackBar('Telefon veya email gerekli.');
          return null;
        }
        if (email.isNotEmpty && !email.contains('@')) {
          _showSnackBar('Geçerli bir email girin.');
          return null;
        }
        final company = _companyController.text.trim();
        final jobTitle = _jobTitleController.text.trim();
        final street = _streetController.text.trim();
        final neighborhood = _neighborhoodController.text.trim();
        final city = _cityController.text.trim();
        final district = _districtController.text.trim();
        final postalCode = _postalCodeController.text.trim();
        final country = _countryController.text.trim();
        final website = _websiteController.text.trim();
        final normalizedWebsite =
            website.isEmpty ? '' : (_normalizeUrl(website) ?? '');
        if (website.isNotEmpty && normalizedWebsite.isEmpty) {
          _showSnackBar('Geçerli bir web sitesi girin.');
          return null;
        }
        final lines = <String>[
          'BEGIN:VCARD',
          'VERSION:3.0',
          'FN:${_escapeVCardValue(name)}',
          'N:${_escapeVCardValue(name)};;;;',
          if (company.isNotEmpty) 'ORG:${_escapeVCardValue(company)}',
          if (jobTitle.isNotEmpty) 'TITLE:${_escapeVCardValue(jobTitle)}',
          if (phone.isNotEmpty) 'TEL:${_escapeVCardValue(phone)}',
          if (fax.isNotEmpty) 'TEL;TYPE=FAX:${_escapeVCardValue(fax)}',
          if (email.isNotEmpty) 'EMAIL:${_escapeVCardValue(email)}',
          if (normalizedWebsite.isNotEmpty)
            'URL:${_escapeVCardValue(normalizedWebsite)}',
          if (street.isNotEmpty ||
              neighborhood.isNotEmpty ||
              city.isNotEmpty ||
              district.isNotEmpty ||
              postalCode.isNotEmpty ||
              country.isNotEmpty)
            'ADR;TYPE=WORK:;${_escapeVCardValue(neighborhood)};${_escapeVCardValue(street)};${_escapeVCardValue(city)};${_escapeVCardValue(district)};${_escapeVCardValue(postalCode)};${_escapeVCardValue(country)}',
          'END:VCARD',
        ];
        return lines.join('\n');
      case GenerateCategoryType.wifi:
        final ssid = _ssidController.text.trim();
        if (ssid.isEmpty) {
          _showSnackBar('Wi-Fi adı (SSID) gerekli.');
          return null;
        }
        final password = _passwordController.text.trim();
        final auth = _wifiSecurityPayload(_wifiSecurity);
        if (_wifiSecurity != _WifiSecurity.nopass && password.isEmpty) {
          _showSnackBar('Şifre gerekli.');
          return null;
        }
        final escapedSsid = _escapeWifiField(ssid);
        final escapedPassword = _escapeWifiField(password);
        final segments = <String>[
          'WIFI:T:$auth',
          'S:$escapedSsid',
          if (_wifiSecurity != _WifiSecurity.nopass)
            'P:$escapedPassword',
          if (_wifiHidden) 'H:true',
        ];
        return '${segments.join(';')};;';
      case GenerateCategoryType.social:
        final input = _socialController.text.trim();
        if (input.isEmpty) {
          _showSnackBar('Kullanıcı adı veya URL boş olamaz.');
          return null;
        }
        if (input.startsWith('http://') || input.startsWith('https://')) {
          _showSnackBar('Lütfen kullanıcı adı girin.');
          return null;
        }
        final normalized = input.startsWith('@') ? input.substring(1) : input;
        if (normalized.isEmpty) {
          _showSnackBar('Kullanıcı adı boş olamaz.');
          return null;
        }
        return '${_socialPlatform.baseUrl}$normalized';
      case GenerateCategoryType.document:
        final state = _documentUploadState.value;
        if (state.isLoading) {
          _showSnackBar('Yükleme devam ediyor.');
          return null;
        }
        final downloadUrl = state.downloadUrl;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          _showSnackBar('Önce dokümanı yükleyin.');
          return null;
        }
        return downloadUrl;
      case GenerateCategoryType.image:
        final state = _imageUploadState.value;
        if (state.isLoading) {
          _showSnackBar('Yükleme devam ediyor.');
          return null;
        }
        final downloadUrl = state.downloadUrl;
        if (downloadUrl == null || downloadUrl.isEmpty) {
          _showSnackBar('Önce görsel yükleyin.');
          return null;
        }
        return downloadUrl;
    }
  }

  String? _normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final candidate = trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';
    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      return null;
    }
    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }

  String _escapeWifiField(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll(':', r'\:');
  }

  String _escapeVCardValue(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', '');
  }

  String _requiredLabel(String label, {required bool required}) {
    return required ? '$label *' : label;
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  String _wifiSecurityLabel(_WifiSecurity security) {
    switch (security) {
      case _WifiSecurity.wpaAuto:
        return 'WPA/WPA2/WPA3 (Otomatik)';
      case _WifiSecurity.wep:
        return 'WEP';
      case _WifiSecurity.nopass:
        return 'Şifresiz';
    }
  }

  String _wifiSecurityPayload(_WifiSecurity security) {
    switch (security) {
      case _WifiSecurity.wpaAuto:
        return 'WPA';
      case _WifiSecurity.wep:
        return 'WEP';
      case _WifiSecurity.nopass:
        return 'nopass';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canGenerateForCategory(GenerateCategoryType type) {
    if (type != GenerateCategoryType.document) {
      if (type != GenerateCategoryType.image) {
        return true;
      }
      final state = _imageUploadState.value;
      return !state.isLoading && state.downloadUrl != null;
    }
    final state = _documentUploadState.value;
    return !state.isLoading && state.downloadUrl != null;
  }

  Future<void> _pickAndUploadDocument() async {
    if (_documentUploadState.value.isLoading) {
      return;
    }
    _documentUploadState.value =
        const DocumentUploadState.uploading(fileName: null, progress: 0);
    final pickResult = await _documentPicker.pickDocument();
    if (!mounted) {
      return;
    }
    if (pickResult.isCancelled) {
      _documentUploadState.value = const DocumentUploadState.idle();
      return;
    }
    if (!pickResult.ok || pickResult.document == null) {
      final detail = pickResult.message ?? 'Doküman seçilemedi.';
      debugPrint('Document pick failed: $detail');
      const message = 'Doküman seçilemedi. Lütfen tekrar deneyin.';
      _documentUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    final document = pickResult.document!;
    if (document.size > _maxDocumentBytes) {
      const message = 'Dosya boyutu 15 MB sınırını aşıyor.';
      _documentUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    _documentUploadState.value = DocumentUploadState.uploading(
      fileName: document.name,
      progress: 0,
    );
    final controller = QrControllerScope.of(context);
    final uploadResult = await controller.uploadDocument(
      name: document.name,
      path: document.path,
      bytes: document.bytes,
      readStream: document.readStream,
      contentType: _mapContentType(document.extension),
      folder: 'documents',
      onProgress: (value) {
        if (!mounted) {
          return;
        }
        final progress =
            value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
        _documentUploadState.value = DocumentUploadState.uploading(
          fileName: document.name,
          progress: progress,
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (!uploadResult.ok || uploadResult.downloadUrl == null) {
      final detail = uploadResult.message ?? 'Yükleme başarısız.';
      debugPrint('Document upload failed: $detail');
      const message = 'Yükleme sırasında hata oluştu.';
      _documentUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    _generatedPayload = null;
    _documentUploadState.value = DocumentUploadState.ready(
      fileName: document.name,
      downloadUrl: uploadResult.downloadUrl!,
    );
    _showSnackBar('Doküman yüklendi.');
  }

  Future<void> _pickAndUploadImage() async {
    if (_imageUploadState.value.isLoading) {
      return;
    }
    _imageUploadState.value =
        const DocumentUploadState.uploading(fileName: null, progress: 0);
    final pickResult = await _imagePicker.pickImage();
    if (!mounted) {
      return;
    }
    if (pickResult.isCancelled) {
      _imageUploadState.value = const DocumentUploadState.idle();
      return;
    }
    if (!pickResult.ok || pickResult.image == null) {
      final detail = pickResult.message ?? 'Görsel seçilemedi.';
      debugPrint('Image pick failed: $detail');
      const message = 'Görsel seçilemedi. Lütfen tekrar deneyin.';
      _imageUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    final image = pickResult.image!;
    if (image.size > _maxDocumentBytes) {
      const message = 'Dosya boyutu 15 MB sınırını aşıyor.';
      _imageUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    _imageUploadState.value = DocumentUploadState.uploading(
      fileName: image.name,
      progress: 0,
    );
    final controller = QrControllerScope.of(context);
    final uploadResult = await controller.uploadDocument(
      name: image.name,
      path: image.path,
      bytes: image.bytes,
      readStream: image.readStream,
      contentType: _mapImageContentType(image.extension),
      folder: 'images',
      onProgress: (value) {
        if (!mounted) {
          return;
        }
        final progress =
            value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
        _imageUploadState.value = DocumentUploadState.uploading(
          fileName: image.name,
          progress: progress,
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (!uploadResult.ok || uploadResult.downloadUrl == null) {
      final detail = uploadResult.message ?? 'Yükleme başarısız.';
      debugPrint('Image upload failed: $detail');
      const message = 'Yükleme sırasında hata oluştu.';
      _imageUploadState.value = const DocumentUploadState.error(message);
      _showSnackBar(message);
      return;
    }
    _generatedPayload = null;
    _imageUploadState.value = DocumentUploadState.ready(
      fileName: image.name,
      downloadUrl: uploadResult.downloadUrl!,
    );
    _showSnackBar('Görsel yüklendi.');
  }

  String _mapContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _mapImageContentType(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _showSaveDialog(String payload) async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _SaveQrDialog(
        payload: payload,
        categoryTitle: widget.category.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final controller = QrControllerScope.of(context);
    final isLocked = !controller.isSignedIn &&
        (category.type == GenerateCategoryType.document ||
            category.type == GenerateCategoryType.image);
    if (isLocked) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${category.title} QR'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bu kategori giriş yapmadan kullanılamaz.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AccountPage(),
                    ),
                  ),
                  child: const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.title} QR'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (category.type == GenerateCategoryType.document) ...[
            _DocumentPickerSection(
              stateListenable: _documentUploadState,
              onPick: _pickAndUploadDocument,
            ),
            const SizedBox(height: 16),
          ],
          if (category.type == GenerateCategoryType.image) ...[
            _ImagePickerSection(
              stateListenable: _imageUploadState,
              onPick: _pickAndUploadImage,
            ),
            const SizedBox(height: 16),
          ],
          ..._buildForm(category.type),
          const SizedBox(height: 16),
          if (category.type == GenerateCategoryType.document ||
              category.type == GenerateCategoryType.image)
            ValueListenableBuilder<DocumentUploadState>(
              valueListenable: category.type == GenerateCategoryType.document
                  ? _documentUploadState
                  : _imageUploadState,
              builder: (context, state, _) {
                return FilledButton.icon(
                  onPressed: _canGenerateForCategory(category.type)
                      ? _handleGenerate
                      : null,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('QR Oluştur'),
                );
              },
            )
          else
            FilledButton.icon(
              onPressed: _handleGenerate,
              icon: const Icon(Icons.qr_code_2),
              label: const Text('QR Oluştur'),
            ),
          if (_documentPreviewTypes.contains(category.type) &&
              _generatedPayload != null) ...[
            const SizedBox(height: 24),
            Text(
              'Oluşturulan QR',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Center(
              child: QrImageView(
                key: const ValueKey('generatedQrPreview'),
                data: _generatedPayload!,
                size: 220,
                errorStateBuilder: (context, error) => Text(
                  'QR oluşturulamadı.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isDownloading,
                    builder: (context, isDownloading, _) {
                      return OutlinedButton.icon(
                        key: const ValueKey('qrDownloadButton'),
                        onPressed: isDownloading ? null : _handleDownload,
                        icon: isDownloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(isDownloading ? 'Kaydediliyor' : 'İndir'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('qrSaveButton'),
                    onPressed: () => _showSaveDialog(_generatedPayload!),
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Kaydet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('qrCustomizeButton'),
              onPressed: () {},
              icon: const Icon(Icons.tune),
              label: const Text('Özelleştir'),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildForm(GenerateCategoryType type) {
    switch (type) {
      case GenerateCategoryType.text:
        return [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Metin',
              hintText: 'Örn: Merhaba QR',
            ),
            maxLines: 3,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) {
              return Align(
                alignment: Alignment.centerRight,
                child: Text('$currentLength/$maxLength'),
              );
            },
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
      case GenerateCategoryType.url:
        return [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
      case GenerateCategoryType.email:
        return [
          TextField(
            key: const ValueKey('emailInput'),
            controller: _emailController,
            decoration: InputDecoration(
              labelText: _requiredLabel('Email', required: true),
              hintText: 'ornek@mail.com',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('emailSubject'),
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: _requiredLabel('Konu', required: false),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('emailBody'),
            controller: _bodyController,
            decoration: InputDecoration(
              labelText: _requiredLabel('Mesaj', required: false),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
      case GenerateCategoryType.vcard:
        return [
          _buildSectionCard(
            title: 'Temel Bilgiler',
            icon: Icons.badge_outlined,
            initiallyExpanded: true,
            children: [
              TextField(
                key: const ValueKey('vcardName'),
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Ad Soyad', required: true),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardCompany'),
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Şirket', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardJobTitle'),
                controller: _jobTitleController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Pozisyon', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'İletişim',
            icon: Icons.call_outlined,
            initiallyExpanded: true,
            children: [
              TextField(
                key: const ValueKey('vcardPhone'),
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Telefon', required: true),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardFax'),
                controller: _faxController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Fax', required: false),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardEmail'),
                controller: _vcardEmailController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Email', required: true),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardWebsite'),
                controller: _websiteController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Web sitesi', required: false),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleGenerate(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Adres',
            icon: Icons.location_on_outlined,
            initiallyExpanded: false,
            children: [
              TextField(
                key: const ValueKey('vcardStreet'),
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Cadde/Sokak', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardNeighborhood'),
                controller: _neighborhoodController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Mahalle', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardCity'),
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('İl', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardDistrict'),
                controller: _districtController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('İlçe', required: false),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardPostalCode'),
                controller: _postalCodeController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Posta Kodu', required: false),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('vcardCountry'),
                controller: _countryController,
                decoration: InputDecoration(
                  labelText: _requiredLabel('Ülke', required: false),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleGenerate(),
              ),
            ],
          ),
        ];
      case GenerateCategoryType.wifi:
        return [
          TextField(
            key: const ValueKey('wifiSsid'),
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'Wi-Fi adı (SSID)',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('wifiPassword'),
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Şifre',
            ),
            obscureText: true,
            enabled: _wifiSecurity != _WifiSecurity.nopass,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_WifiSecurity>(
            key: const ValueKey('wifiSecurity'),
            value: _wifiSecurity,
            items: _WifiSecurity.values
                .map(
                  (security) => DropdownMenuItem(
                    value: security,
                    child: Text(_wifiSecurityLabel(security)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _wifiSecurity = value);
            },
            decoration: const InputDecoration(
              labelText: 'Güvenlik',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            key: const ValueKey('wifiHidden'),
            value: _wifiHidden,
            contentPadding: EdgeInsets.zero,
            title: const Text('Gizli ağ (SSID yayınlanmıyor)'),
            onChanged: (value) => setState(() => _wifiHidden = value),
          ),
        ];
      case GenerateCategoryType.social:
        return [
          _buildSectionCard(
            title: 'Platform Seç',
            icon: Icons.public,
            initiallyExpanded: true,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SocialPlatform.values.map((platform) {
                  final selected = _socialPlatform == platform;
                  return ChoiceChip(
                    key: ValueKey('socialPlatform_${platform.name}'),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          platform.icon,
                          size: 18,
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(platform.label),
                      ],
                    ),
                    selected: selected,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    onSelected: (_) => setState(() => _socialPlatform = platform),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('socialUsername'),
            controller: _socialController,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı adı',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
      case GenerateCategoryType.document:
        return const [];
      case GenerateCategoryType.image:
        return const [];
    }
  }
}

class DocumentUploadState {
  const DocumentUploadState._({
    required this.isLoading,
    this.fileName,
    this.downloadUrl,
    this.errorMessage,
    this.progress,
  });

  final bool isLoading;
  final String? fileName;
  final String? downloadUrl;
  final String? errorMessage;
  final double? progress;

  const DocumentUploadState.idle()
      : this._(isLoading: false);

  const DocumentUploadState.uploading({
    required String? fileName,
    required double progress,
  }) : this._(
          isLoading: true,
          fileName: fileName,
          progress: progress,
        );

  const DocumentUploadState.ready({
    required String fileName,
    required String downloadUrl,
  }) : this._(
          isLoading: false,
          fileName: fileName,
          downloadUrl: downloadUrl,
          progress: 1,
        );

  const DocumentUploadState.error(String message)
      : this._(isLoading: false, errorMessage: message);
}

class _DocumentPickerSection extends StatelessWidget {
  const _DocumentPickerSection({
    required this.stateListenable,
    required this.onPick,
  });

  final ValueListenable<DocumentUploadState> stateListenable;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DocumentUploadState>(
      valueListenable: stateListenable,
      builder: (context, state, _) {
        final theme = Theme.of(context);
        final label = state.isLoading
            ? 'Yükleniyor...'
            : state.downloadUrl != null
                ? 'Doküman Yüklendi'
                : 'Doküman Seç';
        final helper = state.errorMessage ?? state.fileName ?? 'Dosya seçin';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconButton(
                key: const ValueKey('documentPickerButton'),
                iconSize: 72,
                onPressed: state.isLoading ? null : onPick,
                icon: Icon(
                  Icons.insert_drive_file,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Doküman seç',
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.errorMessage == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _GenerateDetailPageState._maxDocumentLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 6),
              Text(
                '%${((state.progress ?? 0) * 100).round()}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.stateListenable,
    required this.onPick,
  });

  final ValueListenable<DocumentUploadState> stateListenable;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DocumentUploadState>(
      valueListenable: stateListenable,
      builder: (context, state, _) {
        final theme = Theme.of(context);
        final label = state.isLoading
            ? 'Yükleniyor...'
            : state.downloadUrl != null
                ? 'Görsel Yüklendi'
                : 'Görsel Seç';
        final helper = state.errorMessage ?? state.fileName ?? 'Görsel seçin';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: IconButton(
                key: const ValueKey('imagePickerButton'),
                iconSize: 72,
                onPressed: state.isLoading ? null : onPick,
                icon: Icon(
                  Icons.image_outlined,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Görsel seç',
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: state.errorMessage == null
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _GenerateDetailPageState._maxDocumentLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 6),
              Text(
                '%${((state.progress ?? 0) * 100).round()}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SaveQrDialog extends StatefulWidget {
  const _SaveQrDialog({
    required this.payload,
    required this.categoryTitle,
  });

  final String payload;
  final String categoryTitle;

  @override
  State<_SaveQrDialog> createState() => _SaveQrDialogState();
}

class _SaveQrDialogState extends State<_SaveQrDialog> {
  late final TextEditingController _titleController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final controller = QrControllerScope.of(context);
    setState(() => _isSaving = true);
    final imageBytes = await _buildQrPngBytes();
    if (!mounted) {
      return;
    }
    if (imageBytes == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR görseli oluşturulamadı.')),
      );
      return;
    }
    final result = await controller.saveGenerated(
      title: _titleController.text,
      payload: widget.payload,
      category: widget.categoryTitle,
      imageBytes: imageBytes,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (!result.ok) {
      final message = result.message ?? 'Kaydetme başarısız.';
      debugPrint('Save QR failed: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kaydedildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    final userEmail = controller.email;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'QR Kaydet',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('saveQrTitle'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSave(),
                ),
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(
                    data: widget.payload,
                    size: 160,
                  ),
                ),
                if (userEmail != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Kaydeden: $userEmail',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('saveQrSubmit'),
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _buildQrPngBytes() async {
    try {
      final painter = QrPainter(
        data: widget.payload,
        version: QrVersions.auto,
        gapless: true,
      );
      final image = await painter.toImage(512);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
