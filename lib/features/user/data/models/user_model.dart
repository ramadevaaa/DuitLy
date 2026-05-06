class UserModel {
  final int? idUser;
  final String nama;
  final String email;
  final String password;
  final String tujuanFinansial;
  final double kisaranPendapatan;
  final double totalKekayaan;
  final String? fotoProfil;

  UserModel({
    this.idUser,
    required this.nama,
    required this.email,
    required this.password,
    required this.tujuanFinansial,
    required this.kisaranPendapatan,
    required this.totalKekayaan,
    this.fotoProfil,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idUser != null) 'id_user': idUser,
      'nama': nama,
      'email': email,
      'password': password,
      'tujuan_finansial': tujuanFinansial,
      'kisaran_pendapatan': kisaranPendapatan,
      'total_kekayaan': totalKekayaan,
      'foto_profil': fotoProfil,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      idUser: map['id_user']?.toInt(),
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      tujuanFinansial: map['tujuan_finansial'] ?? '',
      kisaranPendapatan: map['kisaran_pendapatan']?.toDouble() ?? 0.0,
      totalKekayaan: map['total_kekayaan']?.toDouble() ?? 0.0,
      fotoProfil: map['foto_profil'],
    );
  }

  UserModel copyWith({
    int? idUser,
    String? nama,
    String? email,
    String? password,
    String? tujuanFinansial,
    double? kisaranPendapatan,
    double? totalKekayaan,
    String? fotoProfil,
  }) {
    return UserModel(
      idUser: idUser ?? this.idUser,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      tujuanFinansial: tujuanFinansial ?? this.tujuanFinansial,
      kisaranPendapatan: kisaranPendapatan ?? this.kisaranPendapatan,
      totalKekayaan: totalKekayaan ?? this.totalKekayaan,
      fotoProfil: fotoProfil ?? this.fotoProfil,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);
}
