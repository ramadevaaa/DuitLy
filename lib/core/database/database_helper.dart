import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../features/transaction/data/models/transaction_model.dart';
import '../../../features/wallet/data/models/wallet_model.dart';
import '../../../features/user/data/models/user_model.dart';
import '../../../features/transaction/data/models/category_model.dart';
import '../../../features/chat/data/models/chat_history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('duitly.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel User
    await db.execute('''
      CREATE TABLE user (
        id_user INTEGER PRIMARY KEY AUTOINCREMENT,
        nama VARCHAR(255) NOT NULL,
        email VARCHAR(255) NOT NULL,
        password VARCHAR(255) NOT NULL,
        tujuan_finansial TEXT,
        kisaran_pendapatan REAL,
        total_kekayaan REAL,
        foto_profil TEXT
      )
    ''');

    // 2. Table wallet
    await db.execute('''
      CREATE TABLE wallet (
        id_wallet INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        nama_wallet TEXT NOT NULL,
        saldo REAL NOT NULL,
        jenis_wallet TEXT NOT NULL,
        catatan_wallet TEXT,
        FOREIGN KEY (id_user) REFERENCES user (id_user) ON DELETE CASCADE
      )
    ''');

    // 3. Table kategori
    await db.execute('''
      CREATE TABLE kategori (
        id_kategori INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_kategori TEXT NOT NULL,
        jenis_arus_kas TEXT NOT NULL
      )
    ''');

    // 4. Table transaksi
    await db.execute('''
      CREATE TABLE transaksi (
        id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        id_wallet INTEGER NOT NULL,
        id_kategori INTEGER NOT NULL,
        judul_transaksi TEXT NOT NULL,
        nominal REAL NOT NULL,
        jenis_arus_kas TEXT NOT NULL,
        metode_pembayaran TEXT NOT NULL,
        deskripsi TEXT,
        time_stamp TEXT NOT NULL,
        FOREIGN KEY (id_user) REFERENCES user (id_user) ON DELETE CASCADE,
        FOREIGN KEY (id_wallet) REFERENCES wallet (id_wallet) ON DELETE CASCADE,
        FOREIGN KEY (id_kategori) REFERENCES kategori (id_kategori) ON DELETE RESTRICT
      )
    ''');

    // 5. Table chat_history
    await db.execute('''
      CREATE TABLE chat_history (
        id_chat INTEGER PRIMARY KEY AUTOINCREMENT,
        id_user INTEGER NOT NULL,
        pesan_user TEXT NOT NULL,
        balasan_ai TEXT NOT NULL,
        waktu_chat TEXT NOT NULL,
        FOREIGN KEY (id_user) REFERENCES user (id_user) ON DELETE CASCADE
      )
    ''');

    // SEED DATA: Kategori Bawaan (sesuai PDM)
    final categories = [
      // ===== PEMASUKAN (IN) =====
      {'nama': 'Gaji', 'tipe': 'IN'},
      {'nama': 'Bonus', 'tipe': 'IN'},
      {'nama': 'Uang Saku', 'tipe': 'IN'},
      {'nama': 'Hadiah', 'tipe': 'IN'},
      // ===== PENGELUARAN (OUT) =====
      {'nama': 'Makanan/Minuman', 'tipe': 'OUT'},
      {'nama': 'Kebutuhan Pokok', 'tipe': 'OUT'},
      {'nama': 'Kuota Internet/WiFi', 'tipe': 'OUT'},
      {'nama': 'Pendidikan', 'tipe': 'OUT'},
      {'nama': 'Fashion', 'tipe': 'OUT'},
      {'nama': 'Bensin', 'tipe': 'OUT'},
      {'nama': 'Olahraga', 'tipe': 'OUT'},
      {'nama': 'Pengeluaran Tak Terduga', 'tipe': 'OUT'},
    ];

    for (var cat in categories) {
      await db.insert('kategori', {
        'nama_kategori': cat['nama'],
        'jenis_arus_kas': cat['tipe'],
      });
    }
  }

  // ==================== CRUD WALLET ====================

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await instance.database;
    return await db.insert('wallet', wallet.toMap());
  }

  Future<List<WalletModel>> readAllWallets(int idUser) async {
    final db = await instance.database;
    final result = await db.query('wallet', where: 'id_user = ?', whereArgs: [idUser]);
    return result.map((json) => WalletModel.fromMap(json)).toList();
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final db = await instance.database;
    return await db.update(
      'wallet',
      wallet.toMap(),
      where: 'id_wallet = ?',
      whereArgs: [wallet.idWallet],
    );
  }

  Future<int> deleteWallet(int idWallet) async {
    final db = await instance.database;
    return await db.delete(
      'wallet',
      where: 'id_wallet = ?',
      whereArgs: [idWallet],
    );
  }

  // ==================== CRUD TRANSAKSI ====================

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transaksi', transaction.toMap());
  }

  Future<List<TransactionModel>> readAllTransactions(int idUser) async {
    final db = await instance.database;
    final result = await db.query(
      'transaksi',
      where: 'id_user = ?',
      whereArgs: [idUser],
      orderBy: 'time_stamp DESC',
    );
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transaksi',
      transaction.toMap(),
      where: 'id_transaksi = ?',
      whereArgs: [transaction.idTransaksi],
    );
  }

  Future<int> deleteTransaction(int idTransaksi) async {
    final db = await instance.database;
    return await db.delete(
      'transaksi',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
  }

  // ==================== ATOMIC TRANSACTION ====================

  Future<void> insertTransactionAndUpdateWallet(TransactionModel transaction) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // 1. Insert Transaksi
      await txn.insert('transaksi', transaction.toMap());

      // 2. Get current Wallet
      final walletResult = await txn.query(
        'wallet',
        where: 'id_wallet = ?',
        whereArgs: [transaction.idWallet],
      );

      if (walletResult.isEmpty) {
        throw Exception('Wallet tidak ditemukan');
      }

      final currentWallet = WalletModel.fromMap(walletResult.first);
      double updatedSaldo = currentWallet.saldo;

      // 3. Update Saldo (IN / OUT)
      if (transaction.jenisArusKas == 'IN') {
        updatedSaldo += transaction.nominal;
      } else if (transaction.jenisArusKas == 'OUT') {
        updatedSaldo -= transaction.nominal;
      }

      // 4. Update Wallet Saldo di DB
      await txn.update(
        'wallet',
        {'saldo': updatedSaldo},
        where: 'id_wallet = ?',
        whereArgs: [transaction.idWallet],
      );

      // 5. [Proses 3.2 DFD] Hitung ulang Total Kekayaan dari SEMUA wallet
      //    lalu update kolom total_kekayaan di tabel user (D1)
      final allWallets = await txn.query('wallet', where: 'id_user = ?', whereArgs: [currentWallet.idUser]);
      final totalKekayaan = allWallets.fold<double>(
        0.0,
        (sum, w) => sum + ((w['saldo'] as num?)?.toDouble() ?? 0.0),
      );

      await txn.update(
        'user',
        {'total_kekayaan': totalKekayaan},
        where: 'id_user = ?',
        whereArgs: [currentWallet.idUser],
      );
    });
  }

  // ==================== CRUD USER ====================

  Future<int> insertUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('user', user.toMap());
  }

  Future<UserModel?> readUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('user', where: 'email = ?', whereArgs: [email], limit: 1);
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'user',
      user.toMap(),
      where: 'id_user = ?',
      whereArgs: [user.idUser],
    );
  }

  // ==================== CRUD KATEGORI ====================

  Future<int> insertKategori(CategoryModel kategori) async {
    final db = await instance.database;
    return await db.insert('kategori', kategori.toMap());
  }

  Future<List<CategoryModel>> readAllKategori() async {
    final db = await instance.database;
    final result = await db.query('kategori');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> updateKategori(CategoryModel kategori) async {
    final db = await instance.database;
    return await db.update(
      'kategori',
      kategori.toMap(),
      where: 'id_kategori = ?',
      whereArgs: [kategori.idKategori],
    );
  }

  Future<int> deleteKategori(int idKategori) async {
    final db = await instance.database;
    return await db.delete('kategori', where: 'id_kategori = ?', whereArgs: [idKategori]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ==================== CRUD CHAT HISTORY ====================

  Future<int> insertChatHistory(ChatHistoryModel chat) async {
    final db = await instance.database;
    return await db.insert('chat_history', chat.toMap());
  }

  Future<List<ChatHistoryModel>> readChatHistory(int idUser) async {
    final db = await instance.database;
    final result = await db.query(
      'chat_history',
      where: 'id_user = ?',
      whereArgs: [idUser],
      orderBy: 'waktu_chat ASC',
    );
    return result.map((json) => ChatHistoryModel.fromMap(json)).toList();
  }

  Future<void> deleteChatHistory(int idUser) async {
    final db = await instance.database;
    await db.delete('chat_history', where: 'id_user = ?', whereArgs: [idUser]);
  }
}
