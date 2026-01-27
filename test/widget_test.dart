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
}
