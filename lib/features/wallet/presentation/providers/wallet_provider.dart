import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_provider.dart';
import '../../data/models/wallet_model.dart';

import 'package:duitly/features/user/presentation/providers/user_provider.dart';

final walletProvider = AsyncNotifierProvider<WalletNotifier, List<WalletModel>>(() {
  return WalletNotifier();
});

class WalletNotifier extends AsyncNotifier<List<WalletModel>> {
  @override
  FutureOr<List<WalletModel>> build() async {
    final user = ref.watch(userProvider).value;
    if (user == null || user.idUser == null) return [];
    
    final db = ref.read(databaseProvider);
    return await db.readAllWallets(user.idUser!);
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider).value;
    if (user == null || user.idUser == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      return await db.readAllWallets(user.idUser!);
    });
  }

  double getTotalBalance(List<WalletModel> wallets) {
    return wallets.fold(0, (sum, item) => sum + item.saldo);
  }
}
