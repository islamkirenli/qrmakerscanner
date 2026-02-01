import 'package:flutter_test/flutter_test.dart';
import 'package:qr_maker_scanner/app/app.dart';
import 'package:qr_maker_scanner/features/scan/scan_page.dart';
import 'package:qr_maker_scanner/models/user_profile.dart';
import 'package:qr_maker_scanner/state/auth_service.dart';
import 'package:qr_maker_scanner/state/profile_service.dart';
import 'package:qr_maker_scanner/state/qr_storage_service.dart';

void main() {
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

    await tester.tap(find.byKey(const ValueKey('profileDeleteAccount')));
    await tester.pumpAndSettle();

    expect(find.text('Hesap silme yakında eklenecek.'), findsOneWidget);
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

  testWidgets('vCard generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('vCard'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('vcardName')), 'Ada Lovelace');
    await tester.enterText(find.byKey(const ValueKey('vcardCompany')), 'Analytical');
    await tester.enterText(find.byKey(const ValueKey('vcardPhone')), '+90 555 123 4567');
    await tester.enterText(find.byKey(const ValueKey('vcardEmail')), 'ada@example.com');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
  });

  testWidgets('Wi-Fi generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isFirebaseReady: false));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('wifiSsid')), 'OfficeWifi');
    await tester.enterText(find.byKey(const ValueKey('wifiPassword')), 'secret123');
    await tester.tap(find.text('QR Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('generatedQrPreview')), findsOneWidget);
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
