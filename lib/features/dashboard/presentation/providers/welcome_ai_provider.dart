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
    final lastDate = prefs.getString('welcome_ai_date_v14_${user.idUser}');
    final cachedMessage = prefs.getString('welcome_ai_msg_v14_${user.idUser}');
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

    final systemInstruction =
        'Kamu adalah asisten penyapa yang ramah dan kasual. Balas HANYA dengan TEPAT 2 kalimat pendek dan santai/kasual.\n'
        'Kalimat 1: Sapa user dengan namanya dengan ramah.\n'
        'Kalimat 2: Berikan satu kalimat motivasi pendek terkait rencana masa depan/impian mereka.\n'
        'ATURAN KETAT:\n'
        '- JANGAN gunakan markdown (seperti **bold** atau *italic*).\n'
        '- JANGAN sebutkan nominal saldo, uang, atau kekayaan.\n'
        '- Tulis sapaan secara sangat singkat, padat, langsung ke poinnya, dan tanpa bertele-tele.\n'
        '- Pastikan kalimat lengkap selesai sepenuhnya.';

    final prompt =
        '''
Data:
- Nama: ${user.nama}
- Rencana: ${user.tujuanFinansial}
- Jumlah Catatan: ${transactions.length}

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
    final cleanMsg = response.replaceAll('**', '').trim();
    if (kDebugMode) {
      debugPrint("WELCOME_AI: API Success. Raw Msg: $cleanMsg");
    }

    final lowerMsg = cleanMsg.toLowerCase();
    final isRefusal = lowerMsg.contains('kiro') ||
        lowerMsg.contains('development environment') ||
        lowerMsg.contains('roleplay') ||
        lowerMsg.contains('financial') ||
        lowerMsg.contains('i appreciate') ||
        lowerMsg.contains('prompt') ||
        lowerMsg.contains('artificial intelligence') ||
        lowerMsg.contains('coding');

    String msg;
    if (isRefusal || cleanMsg.isEmpty) {
      final goalText = user.tujuanFinansial.isNotEmpty
          ? user.tujuanFinansial
          : 'masa depan yang cerah';
      final greetings = [
        'Halo ${user.nama}! Mari catat setiap transaksi hari ini agar impianmu untuk "$goalText" bisa terwujud selangkah demi selangkah.',
        'Selamat datang kembali, ${user.nama}! Fokus pada tujuan "$goalText" dan pastikan arus kasmu tetap sehat hari ini.',
        'Halo ${user.nama}, yuk terus konsisten mencatat keuangan agar impian "$goalText" segera terealisasi!',
        'Setiap catatan transaksi hari ini membawamu lebih dekat ke impian "$goalText", ${user.nama}. Semangat!',
      ];
      final index = (user.nama.hashCode + DateTime.now().day) % greetings.length;
      msg = greetings[index];
    } else {
      msg = cleanMsg;
    }

    await prefs.setString('welcome_ai_date_v14_${user.idUser}', today);
    await prefs.setString('welcome_ai_msg_v14_${user.idUser}', msg);

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
