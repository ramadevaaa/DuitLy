import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/user/presentation/providers/user_provider.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';

final transactionProvider = AsyncNotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});

class TransactionNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  FutureOr<List<TransactionModel>> build() async {
    final user = ref.watch(userProvider).value;
    if (user == null || user.idUser == null) return [];
    
    final db = ref.read(databaseProvider);
    return await db.readAllTransactions(user.idUser!);
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider).value;
    if (user == null || user.idUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      return await db.readAllTransactions(user.idUser!);
    });
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final db = ref.read(databaseProvider);

    await db.insertTransactionAndUpdateWallet(transaction);

    // Refresh transaction list
    await refresh();

    // Refresh wallet saldo (D2)
    ref.read(walletProvider.notifier).refresh();

    // Refresh total_kekayaan user (D1) — sinkron dengan Proses 3.2 DFD
    await ref.read(authProvider.notifier).refreshUser();
  }
}
