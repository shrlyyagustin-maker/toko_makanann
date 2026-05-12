import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'models/barang.dart';
import 'models/transaksi.dart';
import 'models/user.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

// Global list produk tersedia
List<Map<String, dynamic>> produkTersediaGlobal = [
  {
    'nama': 'Beras',
    'harga': 15000,
    'stok': 50,
    'imagePath': 'assets/images/beras.png',
  },
  {
    'nama': 'Gula',
    'harga': 12000,
    'stok': 30,
    'imagePath': 'assets/images/gula.png',
  },
  {
    'nama': 'Minyak Goreng',
    'harga': 25000,
    'stok': 20,
    'imagePath': 'assets/images/minyak_goreng.png',
  },
  {
    'nama': 'Telur',
    'harga': 20000,
    'stok': 100,
    'imagePath': 'assets/images/telur.png',
  },
];

// Global history transaksi
List<Map<String, dynamic>> historyTransaksiGlobal = [];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Bahan Makanan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class TokoPage extends StatefulWidget {
  static final GlobalKey<TokoPageState> pageKey = GlobalKey<TokoPageState>();
  final User user;

  const TokoPage({super.key, required this.user});

  @override
  State<TokoPage> createState() => TokoPageState();
}

class TokoPageState extends State<TokoPage> with TickerProviderStateMixin {
  final Transaksi _transaksi = Transaksi();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fabAnimationController;

  // Produk tersedia yang bisa dibeli (global)
  List<Map<String, dynamic>> get _produkTersedia {
    if (_searchQuery.isEmpty) return produkTersediaGlobal;
    return produkTersediaGlobal.where((produk) {
      final nama = produk['nama'].toString().toLowerCase();
      return nama.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // History transaksi (global)
  List<Map<String, dynamic>> get _historyTransaksi => historyTransaksiGlobal;

  // Controllers untuk qty produk tersedia
  final Map<String, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    // Inisialisasi controllers untuk qty tersedia
    for (var produk in _produkTersedia) {
      if (!_qtyControllers.containsKey(produk['nama'])) {
        _qtyControllers[produk['nama']] = TextEditingController(text: '1');
      }
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _namaController.dispose();
    _hargaController.dispose();
    _qtyController.dispose();
    _searchController.dispose();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _tambahBarangDummy(String nama, double harga) {
    int qty = int.tryParse(_qtyControllers[nama]?.text ?? '1') ?? 1;
    if (qty <= 0) return;

    var produk = _produkTersedia.firstWhere((p) => p['nama'] == nama);
    if (qty > produk['stok']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stok tidak cukup! Stok tersedia: ${produk['stok']}')),
      );
      return;
    }

    _transaksi.tambahBarang(Barang(nama: nama, harga: harga, qty: qty));
    produk['stok'] -= qty;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nama x$qty ditambahkan ke keranjang')),
    );
  }

  void addToCart(String nama, double harga, int qty) {
    if (qty <= 0) return;
    var produk = _produkTersedia.firstWhere((p) => p['nama'] == nama);
    if (qty > produk['stok']) return;

    _transaksi.tambahBarang(Barang(nama: nama, harga: harga, qty: qty));
    produk['stok'] -= qty;
    setState(() {});
  }

  void _tambahStokProduk(String nama, int tambahStok) {
    var produk = _produkTersedia.firstWhere((p) => p['nama'] == nama);
    produk['stok'] += tambahStok;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Stok $nama ditambah $tambahStok')),
    );
  }

  void _hapusStokProduk(String nama, int kurangStok) {
    var produk = _produkTersedia.firstWhere((p) => p['nama'] == nama);
    if (produk['stok'] >= kurangStok) {
      produk['stok'] -= kurangStok;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok $nama dikurangi $kurangStok'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok tidak cukup! Stok tersedia: ${produk['stok']}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _hapusProduk(String nama) {
    produkTersediaGlobal.removeWhere((p) => p['nama'] == nama);
    _qtyControllers.remove(nama);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Produk $nama berhasil dihapus'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<void> _pickProductImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memilih gambar'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _tambahBarang() {
    try {
      String nama = _namaController.text.trim();
      double harga = double.parse(_hargaController.text);
      int stok = int.parse(_qtyController.text);

      // Cek jika produk sudah ada, tambah stok
      var existing = _produkTersedia.firstWhere(
        (p) => p['nama'] == nama,
        orElse: () => {},
      );
      if (existing.isNotEmpty) {
        existing['stok'] += stok;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok $nama ditambah $stok'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        produkTersediaGlobal.add({
          'nama': nama,
          'harga': harga,
          'stok': stok,
          if (_pickedImageBytes != null) 'imageBytes': _pickedImageBytes,
          if (_pickedImage != null) 'imagePath': _pickedImage!.path,
        });
        _qtyControllers[nama] = TextEditingController(text: '1');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produk baru berhasil ditambahkan'),
            backgroundColor: const Color(0xFF1E3A8A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      _namaController.clear();
      _hargaController.clear();
      _qtyController.clear();
      _pickedImage = null;
      _pickedImageBytes = null;

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mohon isi semua field dengan benar'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _checkout() {
    if (_transaksi.keranjang.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white),
              SizedBox(width: 8),
              Text('Keranjang kosong'),
            ],
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            const Text('Konfirmasi Checkout'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detail Pesanan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _transaksi.keranjang.length,
                  itemBuilder: (context, index) {
                    var item = _transaksi.keranjang[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.nama,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('${item.qty} x Rp${item.harga}'),
                              ],
                            ),
                          ),
                          Text(
                            'Rp${item.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp${_transaksi.totalBelanja.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Generate struk
              String struk = _generateStruk();
              
              // Simpan ke history
              _historyTransaksi.add({
                'tanggal': DateTime.now().toString(),
                'user': widget.user.username,
                'items': List.from(_transaksi.keranjang.map((b) => {
                  'nama': b.nama,
                  'harga': b.harga,
                  'qty': b.qty,
                  'total': b.total,
                })),
                'total': _transaksi.totalBelanja,
                'struk': struk,
              });

              setState(() {
                _transaksi.checkout();
              });
              Navigator.of(context).pop();
              
              // Tampilkan struk setelah pembayaran berhasil
              _showStrukAfterPayment(struk);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Konfirmasi Pembayaran'),
          ),
        ],
      ),
    );
  }

  void _showStrukAfterPayment(String struk) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            const Text('Struk Pembayaran'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                struk,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: struk));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Checkout berhasil! Struk disalin'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E3A8A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Salin & Selesai'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Checkout berhasil!'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E3A8A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _lihatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.history, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            const Text('History Transaksi'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _historyTransaksi.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada transaksi',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _historyTransaksi.length,
                  itemBuilder: (context, index) {
                    var trans = _historyTransaksi[_historyTransaksi.length - 1 - index]; // Reverse order
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        title: Text(
                          'Rp${trans['total'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User: ${trans['user']}'),
                            Text(
                              'Tanggal: ${DateTime.parse(trans['tanggal']).toString().split('.')[0]}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${trans['items'].length} item(s)',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility, color: const Color(0xFF1E3A8A)),
                          onPressed: () => _lihatStrukDetail(trans),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _lihatStrukDetail(Map<String, dynamic> trans) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            const Text('Detail Struk'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                trans['struk'],
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Copy to clipboard functionality could be added here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.copy, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Struk berhasil disalin'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF1E3A8A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Salin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showTambahStokDialog(String nama) {
    TextEditingController stokController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.inventory, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Text('Tambah Stok $nama'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: stokController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Stok',
                  prefixIcon: const Icon(Icons.add_box, color: Color(0xFF1E3A8A)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF92AEDC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Color(0xFF1E3A8A), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stok saat ini: ${_produkTersedia.firstWhere((p) => p['nama'] == nama)['stok']}',
                      style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              int tambah = int.tryParse(stokController.text) ?? 0;
              if (tambah > 0) {
                _tambahStokProduk(nama, tambah);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Masukkan jumlah stok yang valid'),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tambah Stok'),
          ),
        ],
      ),
    );
  }

  void _showHapusStokDialog(String nama) {
    TextEditingController stokController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Kurangi Stok $nama'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: stokController,
                decoration: InputDecoration(
                  labelText: 'Jumlah Stok yang Dihapus',
                  prefixIcon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFBFA0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stok saat ini: ${_produkTersedia.firstWhere((p) => p['nama'] == nama)['stok']}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              int kurang = int.tryParse(stokController.text) ?? 0;
              if (kurang > 0) {
                _hapusStokProduk(nama, kurang);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Masukkan jumlah stok yang valid'),
                      ],
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kurangi Stok'),
          ),
        ],
      ),
    );
  }

  void _showHapusProdukDialog(String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent),
            const SizedBox(width: 8),
            const Text('Hapus Produk'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "$nama"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _hapusProduk(nama);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _generateStruk() {
    StringBuffer struk = StringBuffer();
    DateTime now = DateTime.now();
    String tanggal = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    String jam = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    struk.writeln('      TOKO MAKANAN');
    struk.writeln('════════════════════════');
    struk.writeln('$tanggal $jam | ${widget.user.username}');
    struk.writeln('────────────────────────');
    struk.writeln('ITEM          QTY  HARGA');
    struk.writeln('────────────────────────');
    
    for (var item in _transaksi.keranjang) {
      String nama = item.nama.length > 12 ? item.nama.substring(0, 12) : item.nama;
      String hargaFormatted = _formatCurrency(item.total);
      struk.writeln('${nama.padRight(12)} ${item.qty.toString().padLeft(2)}  Rp${hargaFormatted}');
    }
    
    struk.writeln('────────────────────────');
    String totalFormatted = _formatCurrency(_transaksi.totalBelanja);
    struk.writeln('TOTAL    Rp${totalFormatted.padLeft(8)}');
    struk.writeln('════════════════════════');
    struk.writeln('Terima kasih !');
    
    return struk.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Toko Makanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(user: widget.user),
                ),
              );
            },
            icon: const Icon(Icons.person, color: Colors.white, size: 28),
            tooltip: 'Profil',
          ),
          IconButton(
            onPressed: _lihatHistory,
            icon: const Icon(Icons.history, color: Colors.white, size: 28),
            tooltip: 'History Transaksi',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1F44), Color(0xFF1E3A8A), Color(0xFF3C5A9A)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${widget.user.username}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.user.role == Role.admin ? 'Mode Admin' : 'Mode Pembeli',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Produk Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var produk = _produkTersedia[index];
                    return _buildProductCard(produk);
                  },
                  childCount: _produkTersedia.length,
                ),
              ),
            ),

            // Form Tambah Produk Baru - Only for Admin
            if (widget.user.role == Role.admin)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_box, color: Color(0xFF1E3A8A), size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            'Tambah Produk Baru',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Nama Produk
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          key: const Key('productName'),
                          controller: _namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Produk',
                            prefixIcon: const Icon(Icons.shopping_bag, color: Color(0xFF1E3A8A)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Harga dan Stok
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                key: const Key('productPrice'),
                                controller: _hargaController,
                                decoration: InputDecoration(
                                  labelText: 'Harga (Rp)',
                                  prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF1E3A8A)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: TextField(
                                key: const Key('productStock'),
                                controller: _qtyController,
                                decoration: InputDecoration(
                                  labelText: 'Stok Awal',
                                  prefixIcon: const Icon(Icons.inventory, color: Color(0xFF1E3A8A)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Gambar Produk
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _pickedImage != null ? 'Gambar terpilih: ${_pickedImage!.name}' : 'Pilih gambar produk',
                                style: TextStyle(
                                  color: _pickedImage != null ? Colors.black87 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            TextButton(
                              key: const Key('pickProductImage'),
                              onPressed: _pickProductImage,
                              child: const Text('Pilih'),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedImageBytes != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _pickedImageBytes!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Tombol Tambah
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          key: const Key('addProductButton'),
                          onPressed: _tambahBarang,
                          icon: const Icon(Icons.add_circle, size: 24),
                          label: const Text(
                            'Tambah Produk',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: Colors.black26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Keranjang Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart, color: Color(0xFF1E3A8A), size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Keranjang Belanja',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_transaksi.keranjang.length} item',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: _transaksi.keranjang.isEmpty ? 60 : 120,
                      child: _transaksi.keranjang.isEmpty
                          ? const Center(
                              child: Text(
                                'Keranjang kosong',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _transaksi.keranjang.length,
                              itemBuilder: (context, index) {
                                var barang = _transaksi.keranjang[index];
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              barang.nama,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text('x${barang.qty}'),
                                            Text(
                                              'Rp${barang.total.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            var produk = _produkTersedia.firstWhere(
                                              (p) => p['nama'] == barang.nama,
                                              orElse: () => {},
                                            );
                                            if (produk.isNotEmpty) {
                                              produk['stok'] += barang.qty;
                                            }
                                            _transaksi.keranjang.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Total
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Belanja:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Rp${_transaksi.totalBelanja.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: _transaksi.keranjang.isNotEmpty
          ? FloatingActionButton.extended(
              key: const Key('checkoutButton'),
              onPressed: _checkout,
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.payment),
              label: const Text('Checkout'),
            )
          : null,
    );
  }

  Widget _buildProductCard(Map<String, dynamic> produk) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image or fallback icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: produk['imageBytes'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        produk['imageBytes'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.inventory_2,
                          size: 30,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    )
                  : produk['imagePath'] != null && produk['imagePath'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            produk['imagePath'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.inventory_2,
                              size: 30,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2,
                          size: 30,
                          color: Color(0xFF1E3A8A),
                        ),
            ),
            const SizedBox(height: 12),

            // Product Name
            Text(
              produk['nama'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Price
            Text(
              'Rp${produk['harga']}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w600,
              ),
            ),

            // Stock
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: produk['stok'] > 10 ? const Color(0xFFE8F1FF) : const Color(0xFF1E3A8A).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Stok: ${produk['stok']}',
                style: TextStyle(
                  fontSize: 12,
                  color: produk['stok'] > 10 ? const Color(0xFF1E3A8A) : const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // Action Button
            if (widget.user.role == Role.admin)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTambahStokDialog(produk['nama']),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tambah Stok'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showHapusStokDialog(produk['nama']),
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Kurangi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showHapusProdukDialog(produk['nama']),
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Hapus'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else if (widget.user.role == Role.pembeli)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        key: Key('qty_${produk['nama']}'),
                        controller: _qtyControllers[produk['nama']],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      key: Key('add_${produk['nama']}'),
                      onPressed: () => _tambahBarangDummy(produk['nama'], produk['harga'].toDouble()),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}