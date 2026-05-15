# 💰 DuitLy - Smart Financial Assistant with Local Market Insights

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Gemini](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google-gemini&logoColor=white)](https://aistudio.google.com/)

**DuitLy** bukan sekadar aplikasi pencatat keuangan biasa. Ini adalah asisten finansial cerdas yang memahami kondisi dompet Anda dan memberikan wawasan harga kebutuhan pokok secara real-time di wilayah Bali.

---

## ✨ Fitur Unggulan

### 🤖 1. AI Financial Assistant (Gemini 2.5 Flash)
Chatbot cerdas yang terintegrasi langsung dengan data transaksi Anda.
- **Context-Aware:** AI tahu saldo dan transaksi Anda, sehingga saran yang diberikan sangat personal.
- **Gatekeeper Security:** AI fokus hanya pada bantuan finansial dan menolak pertanyaan di luar konteks.
- **Smart Briefing:** AI menyapa Anda di dashboard dengan ringkasan target finansial setiap harinya.

### 🛒 2. Local Market Insights (NEW!)
DuitLy kini dibekali data harga bahan pokok dari **Info Pasar Denpasar & PIHPS Bank Indonesia**.
- **Shopping Advisor:** Minta saran belanja ke AI berdasarkan budget (misal: "Saran belanja 20rb untuk anak kos").
- **Real Prices:** Data mencakup 30+ komoditas (Beras, Ayam, Telur, Tempe, Mie Instan, dll) versi Mei 2026.
- **Accurate Estimation:** AI membantu menghitung estimasi belanja harian Anda secara akurat.

### 📊 3. Smart Analytics & Management
- **Interactive Charts:** Visualisasi pengeluaran dan pemasukan dengan grafik yang cantik.
- **Multi-Wallet Support:** Kelola Tunai, Bank, dan E-Wallet dalam satu aplikasi.
- **Transaction History:** Riwayat lengkap dengan kategori yang terorganisir.

---

## 🛠️ Tech Stack

- **UI Framework:** Flutter (Material 3)
- **State Management:** Riverpod (AsyncNotifier)
- **Local Database:** SQLite (sqflite)
- **AI Engine:** Google Generative AI (Gemini SDK)
- **Config Management:** Flutter Dotenv
- **Visualization:** FL Chart

---

## 🚀 Memulai (Quick Start)

### Persiapan
1. Pastikan **Flutter SDK** sudah terinstal.
2. Dapatkan API Key Gemini di [Google AI Studio](https://aistudio.google.com/).

### Instalasi
1. Clone repositori:
   ```bash
   git clone https://github.com/ramadevaaa/DuitLy.git
   ```
2. Masuk ke direktori & install packages:
   ```bash
   cd duitly
   flutter pub get
   ```
3. Konfigurasi API Key:
   - Buat file `.env` di root project.
   - Isi dengan: `GEMINI_API_KEY=your_api_key_here`

### Jalankan Aplikasi
```bash
flutter run
```

---

## 📁 Struktur Folder Utama
- `lib/core/`: Inti aplikasi (database, navigasi, theme).
- `lib/features/chat/`: Modul asisten AI dan integrasi data sembako.
- `lib/features/dashboard/`: Visualisasi data dan AI Welcome Message.
- `assets/data/`: Sumber data statis untuk harga bahan pokok lokal.

---

## 📄 Lisensi & Kontribusi
Proyek ini dikembangkan sebagai tugas mata kuliah **Pemrograman Mobile**. Kontribusi sangat dipersilakan untuk pengembangan fitur yang lebih luas!

---

