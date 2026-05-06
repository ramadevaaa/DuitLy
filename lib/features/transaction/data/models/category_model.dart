class CategoryModel {
  final int? idKategori;
  final String namaKategori;
  final String jenisArusKas; // IN / OUT

  CategoryModel({
    this.idKategori,
    required this.namaKategori,
    required this.jenisArusKas,
  });

  Map<String, dynamic> toMap() {
    return {
      if (idKategori != null) 'id_kategori': idKategori,
      'nama_kategori': namaKategori,
      'jenis_arus_kas': jenisArusKas,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      idKategori: map['id_kategori']?.toInt(),
      namaKategori: map['nama_kategori'] ?? '',
      jenisArusKas: map['jenis_arus_kas'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel.fromMap(json);
}
