# DuitLy Enhancement Progress Tracker

## 1. Session Management (Persistent Login)
- [x] Update `AuthProvider` dan mekanisme routing awal aplikasi.
- [x] Simpan status login (session) menggunakan `SharedPreferences` atau `secure_storage`.
- [x] Buka otomatis ke Dashboard jika session masih valid (belum logout).
- [x] Implementasikan tombol/fungsi Log Out untuk menghapus session.
- [ ] (Opsional) Tambahkan batas waktu session (misal: 3 bulan).

## 2. Fitur Report PDF by Filter
- [x] Buat UI Filter Rentang Waktu (7 Hari, 30 Hari, 3 Bulan, 1 Tahun, dsb) di halaman History/Report.
- [x] Buat query database untuk mengambil transaksi berdasarkan filter tanggal.
- [x] Integrasikan package `pdf` dan `printing` / `path_provider` untuk membuat layout dokumen laporan (Pemasukan, Pengeluaran, Total).
- [x] Buat fungsi untuk Save/Share file PDF yang dihasilkan.

## 3. Dashboard AI Welcome Message
- [x] Ambil data User Context (Goals tercapai/belum, saldo saat ini).
- [x] Buat fungsi pemanggilan AI berjalan di *background* agar tidak memblokir UI.
- [x] Simpan hasil *generate* AI beserta *timestamp* (waktu generate) di `SharedPreferences`.
- [x] Buat *logic*: Jika data hari ini sudah ada, gunakan cache. Jika beda hari, *generate* ulang.
- [x] Tampilkan di UI Dashboard.

## 4. Chatbot Assistant (Gatekeeper & Optimasi)
- [x] Rombak *System Prompt* di `ChatProvider`:
  - Berperan sebagai **Gatekeeper** (tolak prompt di luar konteks aplikasi/finansial).
  - Wajib menjawab **singkat, padat, to the point**, dan hemat token.
  - Kurangi/hilangkan emotikon yang tidak perlu.
- [x] Integrasi package `flutter_markdown` pada *chat bubble* di UI agar format seperti `**teks**` terender menjadi *bold*.
- [x] Siapkan kerangka kode (placeholder logic) untuk integrasi *API Sembako/Kebutuhan Pokok*.

## 5. Integrasi Data Bahan Pokok (Hybrid Static Approach) - [DONE]
- [x] **Sumber Data:** Menggunakan data statis dari **Info Pasar Denpasar (Mei 2026)** untuk akurasi dan stabilitas dan Sumber data dari PIHPS Bank Indonesia untuk Data harga Realtime untuk bulan Mei terakhir update.
- [x] **Data Asset:** Implementasi `assets/data/harga_sembako_bali.json` yang berisi >25 komoditas (Beras, Ayam, Telur, Tempe, Mie Instan, dll).
- [x] **Alur Kerja (Workflow):**
  1. **Trigger:** `ChatProvider` mendeteksi kata kunci (harga, sembako, ayam, dll) dalam pesan user.
  2. **Injection:** Jika terdeteksi, aplikasi memuat JSON dari assets dan menyuntikkannya sebagai *Context* ke dalam prompt AI.
  3. **Calculation:** AI melakukan kalkulasi belanja (misal: budget 20rb) berdasarkan harga per kg/bungkus yang ada di data asset.
  4. **Attribution:** AI memberikan jawaban dengan menyebutkan sumber data untuk menjaga kredibilitas.
- [x] **Optimasi Token:** Data hanya dikirim ke API Gemini jika user benar-benar bertanya soal harga, sehingga menghemat kuota API.
- [x] **Gatekeeper AI:** Memperketat instruksi agar AI hanya menjawab seputar finansial dan aplikasi DuitLy.

## 6. Migrasi ke Custom API OpenRouter
- [x] Buat class helper `CustomAIService` (`custom_ai_service.dart`) dengan OpenRouter API Key.
- [x] Ubah `welcome_ai_provider.dart` agar menggunakan `CustomAIService`.
- [x] Ubah `chat_provider.dart` agar menggunakan `CustomAIService` dengan format riwayat standard.

## 7. Fitur Dashboard Shortcut & OCR Struk Belanja - [DONE]
- [x] Install dependensi `google_mlkit_text_recognition`, `image_picker`, dan `http`.
- [x] Buat class helper `ReceiptParserNotifier` untuk OCR & OpenRouter hybrid parsing.
- [x] Implementasikan Shortcut Grid (Aksi Cepat) di `dashboard_screen.dart`.
- [x] Buat widget dialog verifikasi `ScanConfirmationDialog`.
- [x] Modifikasi `AddTransactionSheet` agar menerima data inisialisasi dari hasil scan, dan menyembunyikan tombol scan saat mode edit struk (`isFromScan == true`).
- [x] Jalankan verifikasi manual dan `flutter analyze`.

## 8. Penyesuaian Batasan (Limit & Timeout) AI
- [x] Ubah `maxTokens` di `welcome_ai_provider.dart` menjadi `8000` agar model reasoning memiliki cukup ruang.
- [x] Tambahkan `.timeout(const Duration(seconds: 120))` pada pemanggilan HTTP POST di `custom_ai_service.dart`.
- [x] Lakukan verifikasi kode dengan `flutter analyze`.

## 9. Penyeragaman Alur Scan Struk & Dialog Read-Only
- [x] Ubah dialog konfirmasi `ScanConfirmationDialog` agar semua form field bersifat read-only.
- [x] Tampilkan kategori sebagai TextField read-only di `ScanConfirmationDialog` (bukan Dropdown).
- [x] Ubah alur di `add_transaction_sheet.dart`: Setelah pemindaian sukses, tutup sheet dan tampilkan `ScanConfirmationDialog`.
- [x] Jalankan verifikasi kode dengan `flutter analyze`.

## 10. Hardening Keamanan & Kualitas Akhir (Final Scan)
- [x] Tambahkan validasi identitas (Email & Nama lengkap) sebelum reset password di `login_screen.dart`.
- [x] Lindungi debug prints sensitif dengan checks `if (kDebugMode)` di service dan providers.
- [x] Terapkan salted password hashing secara backward-compatible di `password_utils.dart`.
- [x] Terapkan pembatasan context chat history (maksimal 10 turn) di `chat_provider.dart`.
- [x] Bersihkan warning `use_build_context_synchronously` di `add_transaction_sheet.dart` menggunakan local variable context.
- [x] Lakukan scan final dan verifikasi dengan `flutter analyze` (Zero Issues).
