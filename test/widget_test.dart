import 'package:flutter_test/flutter_test.dart';
import 'package:qr_maker_scanner/app/app.dart';

void main() {
  testWidgets('Generate flow adds item to history', (WidgetTester tester) async {
    await tester.pumpWidget(const QrApp());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('loginName')), 'Ali Veli');
    await tester.enterText(find.byKey(const ValueKey('loginEmail')), 'ali@example.com');
    await tester.tap(find.byKey(const ValueKey('loginButton')));
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
    await tester.pumpWidget(const QrApp());

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
    await tester.pumpWidget(const QrApp());

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
    await tester.pumpWidget(const QrApp());

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
    await tester.pumpWidget(const QrApp());

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kişi Kartı'));
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
    await tester.pumpWidget(const QrApp());

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
}
