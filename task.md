# DuitLy - Project Roadmap & Task Checklist

## Deskripsi Singkat
DuitLy adalah aplikasi manajemen keuangan personal "Local-First" yang ditenagai oleh AI (Gemini API). Data disimpan secara lokal di SQLite untuk kecepatan dan privasi. AI (Gemini) akan membaca riwayat transaksi melalui *Context Injection* sebagai asisten finansial pintar.

## Arsitektur & Teknologi
- **UI/UX**: Flutter (Material 3)
- **State Management**: flutter_riverpod
- **Local Database**: sqflite (Strictly no cloud DB / Firebase)
- **AI Engine**: google_generative_ai (Gemini API)
- **Data Visualization**: fl_chart
- **Architecture**: Clean Architecture (Layered)

---

### Tahap 1: Setup Data Layer & SQLite ✅
- [x] Buat model (User, Wallet, Kategori, Transaksi, ChatHistory).
- [x] Inisialisasi `DatabaseHelper` dengan `sqflite`.
- [x] Tulis struktur tabel SQLite (sesuai PDM).
- [x] Buat fungsi CRUD untuk Transaksi dan Wallet.
- [x] Implementasi fungsi Atomic `insertTransactionAndUpdateWallet()`.

### Tahap 2: State Management (Riverpod) ✅
- [x] Buat `database_provider.dart`.
- [x] Buat `wallet_provider.dart` (AsyncNotifier) untuk saldo & daftar wallet.
- [x] Buat `transaction_provider.dart` (AsyncNotifier) terintegrasi dengan wallet state.

### Tahap 3: Onboarding & Home / Dashboard Page ✅
- [x] **Onboarding/QnA Screen**: Form inisialisasi Profil (Nama, Financial Goal, Income, Saldo Awal). Muncul jika tabel `user` kosong.
- [x] **Home Dashboard**:
  - [x] Top Bar: Sapaan & Profil.
  - [x] Total Balance: Kalkulasi dari semua wallet.
  - [x] Wallet Carousel: Kartu geser per sumber dana.
  - [x] Recent Activity: 5 transaksi terbaru.
- [x] **Add Transaction Sheet/Modal**: Form input (Judul, Nominal, IN/OUT, Dropdown Wallet & Kategori).
- [x] **Bottom Navigation Bar**: Navigasi ke 4 halaman utama.

### Tahap 4: History / Analytics Page ✅
- [x] Implementasi **Pie Chart** pengeluaran berdasarkan kategori (`fl_chart`).
- [x] Fitur **Filter Transaksi**: Rentang waktu (7 Hari, 30 Hari, 3 Bulan, 1 Tahun) & Filter Wallet.
- [x] **Detailed List**: Daftar riwayat transaksi lengkap.

### Tahap 5: DuitLy AI Assistant (Chatbot Page)
- [ ] Buat `FinancialAIService` via `google_generative_ai`.
- [ ] **Context Injection**: Fungsi untuk mengubah profil user & histori transaksi SQLite menjadi JSON untuk prompt Gemini.
- [ ] **Chat Interface**: Tampilan ala WhatsApp/Telegram.
- [ ] **Quick Suggestions**: Bubble pertanyaan cepat (e.g., "Rangkum pengeluaran minggu ini").
- [ ] Simpan log percakapan ke tabel `chat_history`.

### Tahap 6: Settings & Profile Management ✅
- [x] **User Profile**: Edit nama/foto/income.
- [x] **Financial Profile**: Edit data QnA (Goal, Income).
- [x] **Wallet Management**: Tambah, edit, hapus sumber dana.
- [x] **Privacy & Security**: Info keamanan data lokal.
