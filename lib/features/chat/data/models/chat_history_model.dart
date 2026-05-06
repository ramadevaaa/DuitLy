class ChatHistoryModel {
  final int? idChat;
  final int idUser;
  final String pesanUser;
  final String balasanAi;
  final DateTime waktuChat;

  ChatHistoryModel({
    this.idChat,
    required this.idUser,
    required this.pesanUser,
    required this.balasanAi,
    required this.waktuChat,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idChat != null) 'id_chat': idChat,
      'id_user': idUser,
      'pesan_user': pesanUser,
      'balasan_ai': balasanAi,
      'waktu_chat': waktuChat.toIso8601String(),
    };
  }

  factory ChatHistoryModel.fromMap(Map<String, dynamic> map) {
    return ChatHistoryModel(
      idChat: map['id_chat']?.toInt(),
      idUser: map['id_user']?.toInt() ?? 0,
      pesanUser: map['pesan_user'] ?? '',
      balasanAi: map['balasan_ai'] ?? '',
      waktuChat: DateTime.tryParse(map['waktu_chat'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ChatHistoryModel.fromJson(Map<String, dynamic> json) => ChatHistoryModel.fromMap(json);
}
