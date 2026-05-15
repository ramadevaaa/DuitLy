import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/core/providers/database_provider.dart';

final welcomeAiProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null || user.idUser == null) return null;

  final prefs = await SharedPreferences.getInstance();
  final lastDate = prefs.getString('welcome_ai_date_v9_${user.idUser}');
  final cachedMessage = prefs.getString('welcome_ai_msg_v9_${user.idUser}');
  final today = DateTime.now().toString().substring(0, 10);

  if (lastDate == today && cachedMessage != null && cachedMessage.isNotEmpty) {
    print("WELCOME_AI: Found cached message: $cachedMessage");
    return cachedMessage;
  }

  print("WELCOME_AI: No cache found or new day. Generating...");
  // Generate new message
  final db = ref.read(databaseProvider);
  final wallets = await db.readAllWallets(user.idUser!);
  final transactions = await db.readAllTransactions(user.idUser!);

  print(
    "WELCOME_AI: Fetched ${wallets.length} wallets and ${transactions.length} transactions.",
  );

  final totalKekayaan = wallets.fold<double>(0, (s, w) => s + w.saldo);

  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (apiKey.isEmpty) return 'Halo, selamat datang di DuitLy!';

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
    generationConfig: GenerationConfig(temperature: 0.7, maxOutputTokens: 300),
    systemInstruction: Content.system(
      'Kamu adalah asisten DuitLy. Balas HANYA dengan TEPAT 2 kalimat singkat, tidak lebih, tidak kurang. '
      'Kalimat 1: Sapa user dengan namanya. '
      'Kalimat 2: Sebutkan goals mereka secara spesifik dan statusnya yang sedang diperjuangkan. '
      'LARANGAN: Jangan gunakan markdown, jangan lebih dari 2 kalimat, jangan terlalu panjang.',
    ),
  );

  final prompt =
      '''
Nama user: ${user.nama}
Tujuan Finansial / Goals: ${user.tujuanFinansial ?? 'Belum diatur'}
Total Kekayaan saat ini: Rp ${totalKekayaan.toStringAsFixed(0)}
Jumlah Transaksi yang dicatat: ${transactions.length} transaksi

Tulis sapaan LENGKAP sesuai format. Jangan berhenti di tengah kalimat.
''';

  try {
    print("WELCOME_AI: Calling Gemini API...");
    final response = await model.generateContent([Content.text(prompt)]);
    final msg =
        response.text?.replaceAll('**', '').trim() ??
        'Selamat datang kembali, ${user.nama}!';
    print("WELCOME_AI: API Success. Msg: $msg");

    await prefs.setString('welcome_ai_date_v9_${user.idUser}', today);
    await prefs.setString('welcome_ai_msg_v9_${user.idUser}', msg);

    return msg;
  } catch (e) {
    print("WELCOME_AI: API Error: $e");
    return 'Halo ${user.nama}, yuk cek catatan keuanganmu hari ini!';
  }
});
