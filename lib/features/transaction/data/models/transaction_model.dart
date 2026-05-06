class TransactionModel {
  final int? idTransaksi;
  final int idUser;
  final int idWallet;
  final int idKategori;
  final String judulTransaksi;
  final double nominal;
  final String jenisArusKas; // IN / OUT
  final String metodePembayaran;
  final String? deskripsi;
  final DateTime timeStamp;

  TransactionModel({
    this.idTransaksi,
    required this.idUser,
    required this.idWallet,
    required this.idKategori,
    required this.judulTransaksi,
    required this.nominal,
    required this.jenisArusKas,
    required this.metodePembayaran,
    this.deskripsi,
    required this.timeStamp,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idTransaksi != null) 'id_transaksi': idTransaksi,
      'id_user': idUser,
      'id_wallet': idWallet,
      'id_kategori': idKategori,
      'judul_transaksi': judulTransaksi,
      'nominal': nominal,
      'jenis_arus_kas': jenisArusKas,
      'metode_pembayaran': metodePembayaran,
      'deskripsi': deskripsi,
      'time_stamp': timeStamp.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      idTransaksi: map['id_transaksi']?.toInt(),
      idUser: map['id_user']?.toInt() ?? 0,
      idWallet: map['id_wallet']?.toInt() ?? 0,
      idKategori: map['id_kategori']?.toInt() ?? 0,
      judulTransaksi: map['judul_transaksi'] ?? '',
      nominal: map['nominal']?.toDouble() ?? 0.0,
      jenisArusKas: map['jenis_arus_kas'] ?? '',
      metodePembayaran: map['metode_pembayaran'] ?? '',
      deskripsi: map['deskripsi'],
      timeStamp: DateTime.tryParse(map['time_stamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel.fromMap(json);
}
