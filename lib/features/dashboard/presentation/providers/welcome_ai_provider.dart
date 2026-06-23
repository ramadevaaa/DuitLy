import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duitly/core/services/custom_ai_service.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/core/providers/database_provider.dart';

final welcomeAiProvider = FutureProvider<String?>((ref) async {
  try {
    if (kDebugMode) {
      debugPrint("WELCOME_AI: Provider started");
    }
    final user = ref.watch(authProvider);
    if (kDebugMode) {
      debugPrint("WELCOME_AI: User is: $user");
    }
    if (user == null || user.idUser == null) {
      if (kDebugMode) {
        debugPrint(
          "WELCOME_AI: User is null or idUser is null. Returning empty.",
        );
      }
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('welcome_ai_date_v11_${user.idUser}');
    final cachedMessage = prefs.getString('welcome_ai_msg_v11_${user.idUser}');
    final today = DateTime.now().toString().substring(0, 10);
    if (kDebugMode) {
      debugPrint(
        "WELCOME_AI: Cache lastDate: '$lastDate', cachedMessage: '$cachedMessage', today: '$today'",
      );
    }

    if (lastDate == today &&
        cachedMessage != null &&
        cachedMessage.isNotEmpty) {
      if (kDebugMode) {
        debugPrint("WELCOME_AI: Found cached message: $cachedMessage");
      }
      return cachedMessage;
    }

    if (kDebugMode) {
      debugPrint("WELCOME_AI: No cache found or new day. Generating...");
    }
    final db = ref.read(databaseProvider);
    final wallets = await db.readAllWallets(user.idUser!);
    final transactions = await db.readAllTransactions(user.idUser!);

    if (kDebugMode) {
      debugPrint(
        "WELCOME_AI: Fetched ${wallets.length} wallets and ${transactions.length} transactions.",
      );
    }

    final totalKekayaan = wallets.fold<double>(0, (s, w) => s + w.saldo);

    final systemInstruction =
        'Kamu adalah asisten keuangan DuitLy. Balas HANYA dengan TEPAT 2 kalimat pendek dan santai/kasual.\n'
        'Kalimat 1: Sapa user dengan namanya dan sebutkan total kekayaan/saldonya saat ini secara singkat.\n'
        'Kalimat 2: Berikan satu kalimat motivasi pendek terkait goals finansial mereka.\n'
        'ATURAN KETAT:\n'
        '- JANGAN gunakan markdown (seperti **bold** atau *italic*).\n'
        '- Tulis sapaan secara sangat singkat, padat, langsung ke poinnya, dan tanpa bertele-tele.\n'
        '- Pastikan kalimat lengkap selesai sepenuhnya.';

    final prompt =
        '''
Data:
- Nama: ${user.nama}
- Goals: ${user.tujuanFinansial}
- Total Kekayaan: Rp ${totalKekayaan.toStringAsFixed(0)}
- Jumlah Transaksi: ${transactions.length}

Tulis sapaan 2 kalimat singkat sesuai format.
''';

    if (kDebugMode) {
      debugPrint("WELCOME_AI: Calling OpenRouter API...");
    }
    final response = await CustomAIService.getChatCompletion(
      [
        {'role': 'user', 'content': prompt},
      ],
      systemInstruction: systemInstruction,
      maxTokens: 8000,
    );
    final msg = response.replaceAll('**', '').trim();
    if (kDebugMode) {
      debugPrint("WELCOME_AI: API Success. Msg: $msg");
    }

    await prefs.setString('welcome_ai_date_v11_${user.idUser}', today);
    await prefs.setString('welcome_ai_msg_v11_${user.idUser}', msg);

    return msg;
  } catch (e, stack) {
    if (kDebugMode) {
      debugPrint("WELCOME_AI: Top-level Provider Error: $e\n$stack");
    }
    // Fallback to old cached message if possible, even if date doesn't match
    try {
      final user = ref.read(authProvider);
      if (user != null && user.idUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('welcome_ai_msg_v11_${user.idUser}');
        if (cached != null && cached.isNotEmpty) {
          if (kDebugMode) {
            debugPrint("WELCOME_AI: Fallback to old cached message: $cached");
          }
          return cached;
        }
      }
    } catch (_) {}

    final fallbackMsg = 'Halo, yuk cek catatan keuanganmu hari ini!';
    if (kDebugMode) {
      debugPrint("WELCOME_AI: Using default fallback message: $fallbackMsg");
    }
    return fallbackMsg;
  }
});
