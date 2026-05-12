import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:toko_makanan/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test', () {
    testWidgets('Alur proses lengkap', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Input barang
      await tester.enterText(find.byType(TextField).at(0), 'Apel');
      await tester.enterText(find.byType(TextField).at(1), '10000');
      await tester.enterText(find.byType(TextField).at(2), '2');
      await tester.tap(find.byType(ElevatedButton).at(0));
      await tester.pump();

      // Verifikasi ditambahkan
      expect(find.text('Apel'), findsOneWidget);
      expect(find.text('2 x 10000.0 = 20000.0'), findsOneWidget);

      // Checkout
      await tester.tap(find.byType(ElevatedButton).at(1));
      await tester.pumpAndSettle();

      // Verifikasi dialog struk
      expect(find.text('Struk Belanja'), findsOneWidget);
      expect(find.textContaining('Total: 20000'), findsOneWidget);

      // OK
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Verifikasi keranjang kosong
      expect(find.text('Apel'), findsNothing);
    });
  });
}