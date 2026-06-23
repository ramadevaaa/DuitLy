/// Konfigurasi aplikasi yang mengambil nilai dari compile-time constants.
///
/// API key di-inject saat build menggunakan `--dart-define`, bukan dari file .env.
/// Ini jauh lebih aman karena key ter-compile ke dalam binary (bukan plain text di assets).
///
/// Cara menjalankan:
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=your_api_key_here
/// ```
///
/// Cara build APK:
/// ```
/// flutter build apk --dart-define=GEMINI_API_KEY=your_api_key_here
/// ```
class AppConfig {
  AppConfig._(); // Prevent instantiation

  /// Gemini API Key, di-inject via `--dart-define=GEMINI_API_KEY=xxx`.
  /// Tidak pernah tersimpan sebagai plain text di assets/file.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Cek apakah API key sudah dikonfigurasi.
  static bool get isGeminiConfigured => geminiApiKey.isNotEmpty;
}
