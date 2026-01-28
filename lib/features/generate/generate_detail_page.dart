import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../app/controller_scope.dart';
import '../account/account_page.dart';
import 'generate_category.dart';

enum SocialPlatform {
  instagram('Instagram', 'https://instagram.com/'),
  x('X', 'https://x.com/'),
  tiktok('TikTok', 'https://www.tiktok.com/@'),
  linkedin('LinkedIn', 'https://www.linkedin.com/in/'),
  youtube('YouTube', 'https://www.youtube.com/@'),
  facebook('Facebook', 'https://www.facebook.com/');

  const SocialPlatform(this.label, this.baseUrl);

  final String label;
  final String baseUrl;
}

class GenerateDetailPage extends StatefulWidget {
  const GenerateDetailPage({super.key, required this.category});

  final GenerateCategoryInfo category;

  @override
  State<GenerateDetailPage> createState() => _GenerateDetailPageState();
}

class _GenerateDetailPageState extends State<GenerateDetailPage> {
  late final TextEditingController _textController;
  late final TextEditingController _emailController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _vcardEmailController;
  late final TextEditingController _companyController;
  late final TextEditingController _socialController;
  late final TextEditingController _ssidController;
  late final TextEditingController _passwordController;
  String _wifiSecurity = 'WPA';
  SocialPlatform _socialPlatform = SocialPlatform.instagram;
  String? _generatedPayload;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _emailController = TextEditingController();
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _vcardEmailController = TextEditingController();
    _companyController = TextEditingController();
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
    _vcardEmailController.dispose();
    _companyController.dispose();
    _socialController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleGenerate() {
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
    if (widget.category.type == GenerateCategoryType.text ||
        widget.category.type == GenerateCategoryType.url ||
        widget.category.type == GenerateCategoryType.email ||
        widget.category.type == GenerateCategoryType.vcard ||
        widget.category.type == GenerateCategoryType.wifi ||
        widget.category.type == GenerateCategoryType.social) {
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
        final email = _vcardEmailController.text.trim();
        final company = _companyController.text.trim();
        final lines = <String>[
          'BEGIN:VCARD',
          'VERSION:3.0',
          'FN:$name',
          if (company.isNotEmpty) 'ORG:$company',
          if (phone.isNotEmpty) 'TEL:$phone',
          if (email.isNotEmpty) 'EMAIL:$email',
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
        final auth = _wifiSecurity;
        return 'WIFI:T:$auth;S:$ssid;P:$password;;';
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
      case GenerateCategoryType.image:
        final text = _textController.text.trim();
        if (text.isEmpty) {
          _showSnackBar('Bağlantı boş olamaz.');
          return null;
        }
        if (!text.startsWith('http://') && !text.startsWith('https://')) {
          _showSnackBar('Bağlantı http:// veya https:// ile başlamalı.');
          return null;
        }
        return text;
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          ..._buildForm(category.type),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _handleGenerate,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('QR Oluştur'),
          ),
          if ((category.type == GenerateCategoryType.text ||
                  category.type == GenerateCategoryType.url ||
                  category.type == GenerateCategoryType.email ||
                  category.type == GenerateCategoryType.vcard ||
                  category.type == GenerateCategoryType.wifi ||
                  category.type == GenerateCategoryType.social) &&
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
                  child: OutlinedButton.icon(
                    key: const ValueKey('qrDownloadButton'),
                    onPressed: () {},
                    icon: const Icon(Icons.download),
                    label: const Text('İndir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('qrSaveButton'),
                    onPressed: () {},
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
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'ornek@mail.com',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('emailSubject'),
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Konu (opsiyonel)',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('emailBody'),
            controller: _bodyController,
            decoration: const InputDecoration(
              labelText: 'Mesaj (opsiyonel)',
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
      case GenerateCategoryType.vcard:
        return [
          TextField(
            key: const ValueKey('vcardName'),
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('vcardCompany'),
            controller: _companyController,
            decoration: const InputDecoration(
              labelText: 'Şirket (opsiyonel)',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('vcardPhone'),
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Telefon (opsiyonel)',
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('vcardEmail'),
            controller: _vcardEmailController,
            decoration: const InputDecoration(
              labelText: 'Email (opsiyonel)',
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('wifiSecurity'),
            value: _wifiSecurity,
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('Şifresiz')),
            ],
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
        ];
      case GenerateCategoryType.social:
        return [
          DropdownButtonFormField<SocialPlatform>(
            key: const ValueKey('socialPlatform'),
            value: _socialPlatform,
            items: SocialPlatform.values
                .map(
                  (platform) => DropdownMenuItem(
                    value: platform,
                    child: Text(platform.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _socialPlatform = value);
            },
            decoration: const InputDecoration(
              labelText: 'Platform',
            ),
          ),
          const SizedBox(height: 12),
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
      case GenerateCategoryType.image:
        return [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Bağlantı',
              hintText: 'https://example.com',
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleGenerate(),
          ),
        ];
    }
  }
}
