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
