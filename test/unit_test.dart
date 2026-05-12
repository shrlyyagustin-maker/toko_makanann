import 'package:flutter_test/flutter_test.dart';
import 'package:toko_makanan/models/barang.dart';
import 'package:toko_makanan/models/transaksi.dart';

void main() {
  group('Unit Test', () {
    test('Validitas input barang', () {
      expect(() => Barang(nama: 'Apel', harga: 10000, qty: 2), returnsNormally);
      expect(() => Barang(nama: 'Apel', harga: -100, qty: 2), throwsArgumentError);
      expect(() => Barang(nama: 'Apel', harga: 10000, qty: 0), throwsArgumentError);
    });

    test('Akurasi perhitungan total belanja', () {
      Transaksi transaksi = Transaksi();
      transaksi.tambahBarang(Barang(nama: 'Apel', harga: 10000, qty: 2));
      transaksi.tambahBarang(Barang(nama: 'Jeruk', harga: 5000, qty: 3));
      expect(transaksi.totalBelanja, 35000);
    });
  });
}