<<<<<<< HEAD
# Toko Makanan - Aplikasi Toko Bahan Makanan

Aplikasi Flutter untuk simulasi toko bahan makanan dengan fitur role-based (Admin dan Pembeli), manajemen stok, dan history transaksi.

## Fitur Utama

### 🔐 Autentikasi
- Login sebagai Admin atau Pembeli
- Register user baru
- Role-based access control

### 🛒 Belanja
- Produk dummy: Beras, Gula, Minyak Goreng, Telur
- Input quantity untuk pembelian
- Validasi stok sebelum checkout
- Keranjang belanja real-time
- Total harga otomatis

### 👨‍💼 Admin Features
- Tambah stok produk
- Lihat semua transaksi
- Akses ke history pembelian

### 📊 History & Reporting
- Simpan history transaksi otomatis
- Lihat detail struk pembelian
- Tracking user dan tanggal transaksi

### 🎨 UI/UX
- Material 3 Design
- Gradient background
- Responsive layout
- Animasi smooth

## Teknologi

- **Flutter**: Framework cross-platform
- **Dart**: Programming language
- **Material 3**: Design system
- **Image Picker**: Untuk input gambar (future feature)

## Testing

- Unit tests untuk logika bisnis
- Integration tests untuk alur lengkap
- CI/CD dengan GitHub Actions

## Struktur Proyek

```
lib/
├── main.dart              # Main app dengan TokoPage
├── login_screen.dart      # Screen login
├── register_screen.dart   # Screen register
└── models/
    ├── user.dart          # Model User dengan enum Role
    ├── barang.dart        # Model Barang
    └── transaksi.dart     # Model Transaksi
```

## Cara Menjalankan

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Jalankan app:
   ```bash
   flutter run
   ```

3. Jalankan tests:
   ```bash
   flutter test
   ```

## User Credentials

### Admin
- Username: admin
- Password: admin123

### Pembeli
- Username: user
- Password: user123

## Development

Proyek ini dibuat untuk memenuhi praktikum "Pengembangan Aplikasi & Software Testing" dengan fokus pada:
- Clean architecture
- State management
- Testing coverage
- CI/CD pipeline
- User experience
=======
# Toko_bahan_makanan
>>>>>>> 5416746d6dd89d3856d8da5cf775f2d62382849f
