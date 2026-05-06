import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/chat/data/models/chat_history_model.dart';

// Model untuk merepresentasikan satu pesan di UI (bisa dari User atau AI)
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });
}

// State untuk seluruh halaman Chat
class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatNotifier extends AsyncNotifier<ChatState> {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  late GenerativeModel _model;
  late ChatSession _chatSession;

  @override
  FutureOr<ChatState> build() async {
    _initGemini();
    await _startNewSession();
    final messages = await _loadHistoryFromDB();
    return ChatState(messages: messages);
  }

  void _initGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2048,
      ),
      systemInstruction: Content.system(
        'Kamu adalah DuitLy AI, asisten keuangan pribadi yang cerdas, ramah, dan membantu. '
        'Kamu berbicara dalam Bahasa Indonesia yang santai namun profesional. '
        'Tugasmu adalah membantu pengguna menganalisis keuangan mereka, memberikan saran pengelolaan uang, '
        'mengidentifikasi pola pengeluaran, dan membantu mencapai tujuan finansial mereka. '
        'Jika pengguna bertanya di luar topik keuangan, arahkan kembali dengan sopan. '
        'Gunakan emoji secukupnya agar percakapan terasa lebih hidup. '
        'Saat menganalisis data keuangan, berikan insight yang actionable dan spesifik.',
      ),
    );
  }

  Future<void> _startNewSession() async {
    final history = await _buildGeminiHistory();
    _chatSession = _model.startChat(history: history);
  }

  Future<List<Content>> _buildGeminiHistory() async {
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return [];

    final db = ref.read(databaseProvider);
    final dbHistory = await db.readChatHistory(user.idUser!);

    return dbHistory
        .map(
          (h) => [
            Content.text(h.pesanUser),
            Content.model([TextPart(h.balasanAi)]),
          ],
        )
        .expand((e) => e)
        .toList();
  }

  Future<List<ChatMessage>> _loadHistoryFromDB() async {
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return [];

    final db = ref.read(databaseProvider);
    final dbHistory = await db.readChatHistory(user.idUser!);

    final messages = <ChatMessage>[];
    for (final h in dbHistory) {
      messages.add(
        ChatMessage(text: h.pesanUser, isUser: true, timestamp: h.waktuChat),
      );
      messages.add(
        ChatMessage(text: h.balasanAi, isUser: false, timestamp: h.waktuChat),
      );
    }
    return messages;
  }

  // Membangun konteks keuangan user untuk di-inject ke prompt
  Future<String> _buildFinancialContext() async {
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return '';

    final db = ref.read(databaseProvider);

    final wallets = await db.readAllWallets(user.idUser!);
    final transactions = await db.readAllTransactions(user.idUser!);

    final totalKekayaan = wallets.fold<double>(0, (s, w) => s + w.saldo);
    final totalPemasukan = transactions
        .where((t) => t.jenisArusKas == 'IN')
        .fold<double>(0, (s, t) => s + t.nominal);
    final totalPengeluaran = transactions
        .where((t) => t.jenisArusKas == 'OUT')
        .fold<double>(0, (s, t) => s + t.nominal);

    final walletInfo = wallets
        .map(
          (w) =>
              '- ${w.namaWallet} (${w.jenisWallet}): Rp ${w.saldo.toStringAsFixed(0)}',
        )
        .join('\n');

    final recentTx = transactions
        .take(10)
        .map(
          (t) =>
              '- [${t.jenisArusKas}] ${t.judulTransaksi}: Rp ${t.nominal.toStringAsFixed(0)} (${t.timeStamp.toString().substring(0, 10)})',
        )
        .join('\n');

    return '''
[DATA KEUANGAN PENGGUNA - ${DateTime.now().toString().substring(0, 10)}]
Nama: ${user.nama}
Tujuan Finansial: ${user.tujuanFinansial ?? 'Belum diatur'}
Kisaran Pendapatan: Rp ${(user.kisaranPendapatan ?? 0).toStringAsFixed(0)}/bulan
Total Kekayaan: Rp ${totalKekayaan.toStringAsFixed(0)}
Total Pemasukan (semua waktu): Rp ${totalPemasukan.toStringAsFixed(0)}
Total Pengeluaran (semua waktu): Rp ${totalPengeluaran.toStringAsFixed(0)}

Dompet:
$walletInfo

10 Transaksi Terakhir:
$recentTx
''';
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return;

    final currentState = state.value ?? const ChatState();

    // Tambahkan pesan user + bubble loading AI ke UI
    final userMsg = ChatMessage(
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final loadingMsg = ChatMessage(
      text: '...',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    state = AsyncValue.data(
      currentState.copyWith(
        messages: [...currentState.messages, userMsg, loadingMsg],
        isSending: true,
      ),
    );

    try {
      // Inject konteks keuangan ke pesan pertama atau jika ada trigger kata kunci
      final financialKeywords = [
        'keuangan',
        'saldo',
        'dompet',
        'transaksi',
        'pengeluaran',
        'pemasukan',
        'tabungan',
        'analisis',
        'analisa',
        'berapa',
        'total',
      ];
      final needsContext =
          currentState.messages.isEmpty ||
          financialKeywords.any((k) => userText.toLowerCase().contains(k));

      String promptText = userText;
      if (needsContext) {
        final context = await _buildFinancialContext();
        promptText = '$context\n\nPertanyaan pengguna: $userText';
      }

      final response = await _chatSession.sendMessage(Content.text(promptText));
      final aiReply =
          response.text ?? 'Maaf, saya tidak dapat merespons saat ini.';

      // Simpan ke SQLite
      final db = ref.read(databaseProvider);
      await db.insertChatHistory(
        ChatHistoryModel(
          idUser: user.idUser!,
          pesanUser: userText,
          balasanAi: aiReply,
          waktuChat: DateTime.now(),
        ),
      );

      // Update state: ganti bubble loading dengan jawaban asli
      final updatedMessages = [...currentState.messages, userMsg];
      updatedMessages.add(
        ChatMessage(text: aiReply, isUser: false, timestamp: DateTime.now()),
      );

      state = AsyncValue.data(
        currentState.copyWith(
          messages: updatedMessages,
          isSending: false,
          error: null,
        ),
      );
    } catch (e) {
      // Hapus bubble loading, tampilkan error
      state = AsyncValue.data(
        currentState.copyWith(
          messages: [...currentState.messages, userMsg],
          isSending: false,
          error: 'Gagal menghubungi AI: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> clearHistory() async {
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return;

    final db = ref.read(databaseProvider);
    await db.deleteChatHistory(user.idUser!);

    _initGemini();
    await _startNewSession();
    state = AsyncValue.data(const ChatState());
  }
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
