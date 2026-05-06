# 💰 DuitLy - Asisten Keuangan Pribadi Cerdas

DuitLy adalah aplikasi manajemen keuangan pribadi berbasis mobile yang dibangun dengan Flutter. Aplikasi ini dirancang untuk membantu pengguna mencatat transaksi, mengelola berbagai dompet (wallets), dan mendapatkan wawasan keuangan mendalam melalui bantuan **AI (Gemini)**.

## ✨ Fitur Utama

- **🤖 Asisten AI Gemini**: Chat bot cerdas yang memahami konteks keuangan Anda. Berikan pertanyaan seputar saldo, pengeluaran, atau minta saran penghematan.
- **📱 Manajemen Transaksi**: Catat pemasukan (IN) dan pengeluaran (OUT) dengan mudah.
- **💳 Multi-Wallet**: Kelola berbagai jenis dompet (Tunai, Bank, E-Wallet, dll) dalam satu tempat.
- **📊 Dashboard & Analytics**: Visualisasi data keuangan Anda menggunakan grafik yang interaktif.
- **🔒 Keamanan Data Lokal**: Semua data keuangan disimpan secara aman di perangkat menggunakan SQLite.
- **🔐 Sistem Autentikasi**: Fitur Login dan Register untuk menjaga privasi data pengguna.

## 🚀 Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Database**: [SQLite (sqflite)](https://pub.dev/packages/sqflite)
- **AI Engine**: [Google Generative AI (Gemini)](https://pub.dev/packages/google_generative_ai)
- **Environment Variables**: [Flutter Dotenv](https://pub.dev/packages/flutter_dotenv)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)

## 🛠️ Persyaratan Sistem

Sebelum memulai, pastikan Anda telah menginstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Versi terbaru direkomendasikan)
- [Android Studio](https://developer.android.com/studio) atau [VS Code](https://code.visualstudio.com/)
- API Key Gemini (Dapatkan di [Google AI Studio](https://aistudio.google.com/))

## 📦 Instalasi & Persiapan

1.  **Clone repositori ini:**
    ```bash
    git clone https://github.com/username/duitly.git
    cd duitly
    ```

2.  **Instal dependensi:**
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Environment:**
    - Salin file `.env.example` menjadi `.env`:
      ```bash
      cp .env.example .env
      ```
    - Buka file `.env` dan masukkan API Key Gemini Anda:
      ```env
      GEMINI_API_KEY=MASUKKAN_API_KEY_ANDA_DISINI
      ```

## 🏃 Cara Menjalankan Project

1.  Pastikan emulator Android/iOS atau perangkat fisik sudah terhubung.
2.  Jalankan aplikasi dengan perintah:
    ```bash
    flutter run
    ```
3.  Untuk menjalankan dalam mode Debug di VS Code, tekan `F5`.

## 📁 Struktur Folder

```text
lib/
├── core/                # Konfigurasi basis (DB, Navigation, Providers)
├── features/            # Modul fitur aplikasi
│   ├── auth/            # Login & Register
│   ├── chat/            # AI Assistant Interface
│   ├── dashboard/       # Ringkasan Keuangan
│   ├── transaction/     # Manajemen Transaksi
│   ├── user/            # Profil & Data User
│   └── wallet/          # Manajemen Dompet
└── main.dart            # Titik masuk aplikasi
```

## 📄 Lisensi

Proyek ini dibuat untuk keperluan tugas akademik Pemrograman Mobile.

---
Dibuat dengan ❤️ untuk manajemen keuangan yang lebih baik.
