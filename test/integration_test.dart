import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:toko_makanan/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test', () {
    testWidgets('Alur proses lengkap', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Login as pembeli
      await tester.enterText(find.byKey(const Key('loginUsername')), 'pembeli');
      await tester.enterText(find.byKey(const Key('loginPassword')), 'pembeli123');
      await tester.ensureVisible(find.byKey(const Key('loginButton')));
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Tambah barang ke keranjang langsung melalui state helper
      TokoPage.pageKey.currentState!.addToCart('Beras', 15000, 2);
      await tester.pumpAndSettle();

      // Verifikasi barang ditambahkan ke keranjang
      expect(find.byKey(const Key('checkoutButton')), findsOneWidget);

      // Checkout
      await tester.tap(find.byKey(const Key('checkoutButton')));
      await tester.pumpAndSettle();

      // Verifikasi dialog konfirmasi checkout
      expect(find.text('Konfirmasi Checkout'), findsOneWidget);
      expect(find.textContaining('2 x Rp15000'), findsOneWidget);
      expect(find.text('Total Pembayaran:'), findsOneWidget);

      await tester.tap(find.text('Konfirmasi Pembayaran'));
      await tester.pumpAndSettle();

      // Verifikasi keranjang dikosongkan setelah checkout
      expect(find.byKey(const Key('checkoutButton')), findsNothing);
    });
  });
}