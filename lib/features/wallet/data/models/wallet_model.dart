class WalletModel {
  final int? idWallet;
  final int idUser;
  final String namaWallet;
  final double saldo;
  final String jenisWallet;
  final String? catatanWallet;

  WalletModel({
    this.idWallet,
    required this.idUser,
    required this.namaWallet,
    required this.saldo,
    required this.jenisWallet,
    this.catatanWallet,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idWallet != null) 'id_wallet': idWallet,
      'id_user': idUser,
      'nama_wallet': namaWallet,
      'saldo': saldo,
      'jenis_wallet': jenisWallet,
      'catatan_wallet': catatanWallet,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      idWallet: map['id_wallet']?.toInt(),
      idUser: map['id_user']?.toInt() ?? 0,
      namaWallet: map['nama_wallet'] ?? '',
      saldo: map['saldo']?.toDouble() ?? 0.0,
      jenisWallet: map['jenis_wallet'] ?? '',
      catatanWallet: map['catatan_wallet'],
    );
  }

  WalletModel copyWith({
    int? idWallet,
    int? idUser,
    String? namaWallet,
    double? saldo,
    String? jenisWallet,
    String? catatanWallet,
  }) {
    return WalletModel(
      idWallet: idWallet ?? this.idWallet,
      idUser: idUser ?? this.idUser,
      namaWallet: namaWallet ?? this.namaWallet,
      saldo: saldo ?? this.saldo,
      jenisWallet: jenisWallet ?? this.jenisWallet,
      catatanWallet: catatanWallet ?? this.catatanWallet,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel.fromMap(json);
}
