import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class untuk hashing dan verifikasi password.
/// Menggunakan SHA-256 agar password tidak disimpan dalam bentuk plaintext.
class PasswordUtils {
  PasswordUtils._(); // Prevent instantiation

  static const String _salt = 'DuitLy-Security-Salt-2026';

  /// Hash password menggunakan SHA-256 dengan salt.
  /// Mengembalikan string hex dari hash.
  static String hashPassword(String password) {
    final bytes = utf8.encode('$password$_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifikasi apakah [plainPassword] cocok dengan [hashedPassword].
  /// Mendukung fallback ke hash lama tanpa salt demi kompatibilitas data lokal.
  static bool verifyPassword(String plainPassword, String hashedPassword) {
    // 1. Coba verifikasi menggunakan salt (untuk akun baru)
    if (hashPassword(plainPassword) == hashedPassword) {
      return true;
    }
    // 2. Fallback: Coba verifikasi tanpa salt (untuk akun lama di database lokal)
    final bytesUnsalted = utf8.encode(plainPassword);
    final digestUnsalted = sha256.convert(bytesUnsalted).toString();
    return digestUnsalted == hashedPassword;
  }
}
