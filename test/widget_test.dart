import 'package:flutter_test/flutter_test.dart';
import 'package:qr_maker_scanner/app/app.dart';
import 'package:qr_maker_scanner/features/scan/scan_page.dart';

void main() {
  testWidgets('Generate flow adds item to history', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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

    await tester.tap(find.text('Geçmiş'));
    await tester.pumpAndSettle();

    expect(find.text('Merhaba QR'), findsOneWidget);
  });

  testWidgets('URL generate shows QR preview', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

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
    await tester.pumpWidget(const QrApp(isSupabaseReady: false));

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('authEmail')), 'user@example.com');
    await tester.enterText(find.byKey(const ValueKey('authPassword')), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();

    expect(find.text('user@example.com'), findsOneWidget);
  });
}
