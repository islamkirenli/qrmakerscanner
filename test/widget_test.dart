import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_maker_scanner/app/app.dart';
import 'package:qr_maker_scanner/features/scan/scan_page.dart';
import 'package:qr_maker_scanner/features/generate/generate_category.dart';
import 'package:qr_maker_scanner/features/generate/generate_detail_page.dart';
import 'package:qr_maker_scanner/models/user_profile.dart';
import 'package:qr_maker_scanner/state/auth_service.dart';
import 'package:qr_maker_scanner/state/document_picker_service.dart';
import 'package:qr_maker_scanner/state/document_storage_service.dart';
import 'package:qr_maker_scanner/state/image_picker_service.dart';
import 'package:qr_maker_scanner/state/profile_service.dart';
import 'package:qr_maker_scanner/state/qr_app_controller.dart';
import 'package:qr_maker_scanner/state/qr_image_saver.dart';
import 'package:qr_maker_scanner/state/qr_storage_service.dart';
import 'package:qr_maker_scanner/app/controller_scope.dart';

void main() {
  class FakeQrImageSaver implements QrImageSaver {
    int callCount = 0;

    @override
    Future<SaveResult> saveToGallery({required String payload}) async {
      callCount += 1;
      return const SaveResult.ok('Kaydedildi.');
    }
  }

  class FakeDocumentPickerService extends DocumentPickerService {
    FakeDocumentPickerService({
      required this.document,
      this.cancelled = false,
      this.hasError = false,
    });

    final PickedDocument document;
    final bool cancelled;
    final bool hasError;

    @override
    Future<DocumentPickResult> pickDocument() async {
      if (cancelled) {
        return const DocumentPickResult.cancelled();
      }
      if (hasError) {
        return const DocumentPickResult.error('Doküman seçilemedi.');
      }
      return DocumentPickResult.ok(document);
    }
  }

  class FakeImagePickerService extends ImagePickerService {
    FakeImagePickerService({
      required this.image,
      this.cancelled = false,
      this.hasError = false,
    });

    final PickedImage image;
    final bool cancelled;
    final bool hasError;

    @override
    Future<ImagePickResult> pickImage() async {
      if (cancelled) {
        return const ImagePickResult.cancelled();
      }
      if (hasError) {
        return const ImagePickResult.error('Görsel seçilemedi.');
      }
      return ImagePickResult.ok(image);
    }
  }

  testWidgets('Saved QR shows in history list and opens preview',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('authEmail')), 'ali@example.com');
    await tester.enterText(find.byKey(const ValueKey('authPassword')), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Merhaba QR');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('qrSaveButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('saveQrTitle')), 'Favori QR');
    await tester.tap(find.byKey(const ValueKey('saveQrSubmit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geçmiş'));
    await tester.pumpAndSettle();

    expect(find.text('Favori QR'), findsOneWidget);

    await tester.tap(find.text('Favori QR'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('historyQrPreview')), findsOneWidget);
    expect(find.byKey(const ValueKey('historyQrTitle')), findsOneWidget);
    expect(find.byKey(const ValueKey('historyQrDownloadButton')), findsOneWidget);
  });

  testWidgets('Profile copy email shows feedback',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profileCopyEmail')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profileCopyEmail')));
    await tester.pumpAndSettle();

    expect(find.text('Email kopyalandı.'), findsOneWidget);
  });

  testWidgets('Auth screen shows modern cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('authHeroCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('authFormCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('authEmail')), findsOneWidget);
    expect(find.byKey(const ValueKey('authPassword')), findsOneWidget);
    expect(find.byKey(const ValueKey('authSubmit')), findsOneWidget);
    expect(find.byKey(const ValueKey('authConfirmPassword')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('authToggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('authConfirmPassword')), findsOneWidget);
  });

  testWidgets('Generated QR download saves to gallery',
      (WidgetTester tester) async {
    final controller = QrAppController(
      authService: FakeAuthService(),
      storageService: FakeQrStorageService(),
      documentStorageService: FakeDocumentStorageService(),
      profileService: FakeProfileService(),
    );
    final saver = FakeQrImageSaver();
    final category = generateCategories
        .firstWhere((item) => item.type == GenerateCategoryType.text);

    await tester.pumpWidget(
      MaterialApp(
        home: QrControllerScope(
          controller: controller,
          child: GenerateDetailPage(
            category: category,
            imageSaver: saver,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Merhaba QR');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qrDownloadButton')));
    await tester.pumpAndSettle();

    expect(saver.callCount, 1);
    expect(find.text('Kaydedildi.'), findsOneWidget);
  });

  testWidgets('Document picker uploads and generates QR',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );
    final controller = QrAppController(
      authService: auth,
      storageService: FakeQrStorageService(),
      documentStorageService: FakeDocumentStorageService(),
      profileService: FakeProfileService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QrControllerScope(
          controller: controller,
          child: GenerateDetailPage(
            category: generateCategories
                .firstWhere((item) => item.type == GenerateCategoryType.document),
            documentPicker: FakeDocumentPickerService(
              document: PickedDocument(
                name: 'test.pdf',
                size: 1200,
                bytes: Uint8List.fromList([1, 2, 3]),
                extension: 'pdf',
                readStream: null,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('documentPickerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Doküman yüklendi.'), findsOneWidget);

    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('Image picker uploads and generates QR',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );
    final controller = QrAppController(
      authService: auth,
      storageService: FakeQrStorageService(),
      documentStorageService: FakeDocumentStorageService(),
      profileService: FakeProfileService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QrControllerScope(
          controller: controller,
          child: GenerateDetailPage(
            category: generateCategories
                .firstWhere((item) => item.type == GenerateCategoryType.image),
            imagePicker: FakeImagePickerService(
              image: PickedImage(
                name: 'photo.png',
                size: 1200,
                bytes: Uint8List.fromList([1, 2, 3]),
                extension: 'png',
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('imagePickerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Görsel yüklendi.'), findsOneWidget);

    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('Document picker blocks files larger than 15 MB',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );
    final controller = QrAppController(
      authService: auth,
      storageService: FakeQrStorageService(),
      documentStorageService: FakeDocumentStorageService(),
      profileService: FakeProfileService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: QrControllerScope(
          controller: controller,
          child: GenerateDetailPage(
            category: generateCategories
                .firstWhere((item) => item.type == GenerateCategoryType.document),
            documentPicker: FakeDocumentPickerService(
              document: PickedDocument(
                name: 'big.pdf',
                size: 16 * 1024 * 1024,
                bytes: Uint8List.fromList([1, 2, 3]),
                extension: 'pdf',
                readStream: null,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('documentPickerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Dosya boyutu 15 MB sınırını aşıyor.'), findsOneWidget);
    expect(find.byKey(const ValueKey('generatedQrPreview')), findsNothing);
  });

  testWidgets('Profile name save updates header',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('profileFirstName')), 'Ada');
    await tester.enterText(find.byKey(const ValueKey('profileLastName')), 'Lovelace');
    await tester.tap(find.byKey(const ValueKey('profileSave')));
    await tester.pumpAndSettle();

    expect(find.text('Profil kaydedildi.'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('Profile avatar picker selects avatar',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profileAvatarPreview_0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profileAvatarPicker')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('avatarOption2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profileAvatarPreview_2')), findsOneWidget);
  });

  testWidgets('Profile loads from service on open',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    final profileService = FakeProfileService()
      ..storedProfile = const UserProfile(
        userId: 'test-user',
        email: 'user@example.com',
        firstName: 'Grace',
        lastName: 'Hopper',
        avatarIndex: 3,
        lastScan: 'SCAN-001',
        lastGenerated: 'GEN-001',
      );
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
        profileServiceOverride: profileService,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.byKey(const ValueKey('profileAvatarPreview_3')), findsOneWidget);
    expect(find.text('SCAN-001'), findsOneWidget);
    expect(find.text('GEN-001'), findsOneWidget);
  });

  testWidgets('Profile delete account shows feedback',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    final storage = FakeQrStorageService();
    final profileService = FakeProfileService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
        storageServiceOverride: storage,
        profileServiceOverride: profileService,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profileDeleteAccount')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(find.text('Silme nedeni gerekli.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('deleteReasonInput')),
      'Uygulamayı artık kullanmıyorum.',
    );
    await tester.enterText(
      find.byKey(const ValueKey('deletePasswordInput')),
      'password123',
    );
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();

    expect(
      find.text('Hesap silindi.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('authEmail')), findsOneWidget);
  });

  testWidgets('Profile change password shows feedback',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profileChangePassword')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('currentPasswordInput')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('newPasswordInput')),
      'password456',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirmPasswordInput')),
      'password456',
    );
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();

    expect(
      find.text('Şifre güncellendi. Lütfen yeniden giriş yapın.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('authEmail')), findsOneWidget);
  });

  testWidgets('History selection deletes saved QR',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    final storage = FakeQrStorageService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
        storageServiceOverride: storage,
      ),
    );

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Merhaba QR');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qrSaveButton')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('saveQrTitle')), 'Favori QR');
    await tester.tap(find.byKey(const ValueKey('saveQrSubmit')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geçmiş'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('historySelectToggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favori QR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();

    expect(find.text('Favori QR'), findsNothing);
  });

  testWidgets('URL generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('URL'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'https://example.com');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('URL without scheme still generates QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('URL'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'www.example.com');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('Email generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('emailInput')), 'test@example.com');
    await tester.enterText(find.byKey(const ValueKey('emailSubject')), 'Selam');
    await tester.enterText(find.byKey(const ValueKey('emailBody')), 'Merhaba');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('vCard generate shows detailed payload', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('vCard'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('vcardName')), 'Ada Lovelace');
    await tester.enterText(find.byKey(const ValueKey('vcardCompany')), 'Analytical');
    await tester.enterText(find.byKey(const ValueKey('vcardJobTitle')), 'Engineer');
    await tester.enterText(find.byKey(const ValueKey('vcardPhone')), '+90 555 123 4567');
    await tester.enterText(find.byKey(const ValueKey('vcardFax')), '+90 212 555 0000');
    await tester.enterText(find.byKey(const ValueKey('vcardEmail')), 'ada@example.com');
    await tester.enterText(find.byKey(const ValueKey('vcardWebsite')), 'example.com');
    await tester.enterText(find.byKey(const ValueKey('vcardStreet')), 'Main St 12');
    await tester.enterText(find.byKey(const ValueKey('vcardNeighborhood')), 'Moda');
    await tester.enterText(find.byKey(const ValueKey('vcardCity')), 'Istanbul');
    await tester.enterText(find.byKey(const ValueKey('vcardDistrict')), 'Kadikoy');
    await tester.enterText(find.byKey(const ValueKey('vcardPostalCode')), '34000');
    await tester.enterText(find.byKey(const ValueKey('vcardCountry')), 'Turkey');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
    final qrWidget = tester.widget<QrImageView>(
      find.byKey(const ValueKey('generatedQrPreview')),
    );
    expect(
      qrWidget.data,
      [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'FN:Ada Lovelace',
        'N:Ada Lovelace;;;;',
        'ORG:Analytical',
        'TITLE:Engineer',
        'TEL:+90 555 123 4567',
        'TEL;TYPE=FAX:+90 212 555 0000',
        'EMAIL:ada@example.com',
        'URL:https://example.com',
        'ADR;TYPE=WORK:;Moda;Main St 12;Istanbul;Kadikoy;34000;Turkey',
        'END:VCARD',
      ].join('\n'),
    );
  });

  testWidgets('vCard requires phone or email', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('vCard'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('vcardName')), 'Ada Lovelace');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsNothing);
  });

  testWidgets('Wi-Fi generate shows escaped QR payload', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('wifiHidden')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('wifiSsid')),
      'Office;Wifi',
    );
    await tester.enterText(
      find.byKey(const ValueKey('wifiPassword')),
      r'pa\ss:word',
    );
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
    final qrWidget = tester.widget<QrImageView>(
      find.byKey(const ValueKey('generatedQrPreview')),
    );
    expect(
      qrWidget.data,
      r'WIFI:T:WPA;S:Office\;Wifi;P:pa\\ss\:word;H:true;;',
    );
  });

  testWidgets('Social generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Social Media'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('socialUsername')), 'flutterdev');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('Scan page shows torch button', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    expect(find.byKey(const ValueKey('scanTorchButton')), findsOneWidget);
  });

  testWidgets('Scan page routes URL payload', (WidgetTester tester) async {
    final debugPayload = ValueNotifier<String?>(null);
    Uri? launchedUri;

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(
          debugPayloadListenable: debugPayload,
          launchUriOverride: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );

    debugPayload.value = 'https://example.com';
    await tester.pumpAndSettle();

    expect(launchedUri?.host, 'example.com');
  });

  testWidgets('Auth sign in shows signed-in state', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('authEmail')), 'user@example.com');
    await tester.enterText(find.byKey(const ValueKey('authPassword')), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
  });

  testWidgets('Google sign in button triggers auth flow',
      (WidgetTester tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
      ),
    );

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('authGoogle')));
    await tester.pumpAndSettle();

    expect(auth.googleSignInCount, 1);
  });

  testWidgets('Text input shows character counter and enforces max length',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metin'));
    await tester.pumpAndSettle();

    final longText = List.filled(600, 'a').join();
    await tester.enterText(find.byType(EditableText), longText);
    await tester.pumpAndSettle();

    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets('Text QR shows action buttons after generation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Merhaba QR');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('qrDownloadButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('qrSaveButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('qrCustomizeButton')), findsOneWidget);
  });

  testWidgets('Save dialog stores QR data', (WidgetTester tester) async {
    final auth = FakeAuthService();
    final storage = FakeQrStorageService();
    await auth.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'password123',
    );

    await tester.pumpWidget(
      QrApp(
        isFirebaseReady: false,
        authServiceOverride: auth,
        storageServiceOverride: storage,
      ),
    );

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Metin'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), 'Merhaba QR');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('qrSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Kaydeden: user@example.com'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('saveQrTitle')), 'Favori QR');
    await tester.tap(find.byKey(const ValueKey('saveQrSubmit')));
    await tester.pumpAndSettle();

    expect(storage.lastTitle, 'Favori QR');
    expect(storage.lastPayload, 'Merhaba QR');
    expect(storage.lastImageBytes, isNotNull);
  });
}
