import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';

// Filter enum
enum TransactionFilter { week7, month1, month3, year1 }

// Filter state provider (Riverpod v3 compatible)
class FilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => TransactionFilter.month1;
  void setFilter(TransactionFilter f) => state = f;
}

final filterProvider = NotifierProvider<FilterNotifier, TransactionFilter>(() => FilterNotifier());

// Filtered transactions provider
final filteredTransactionProvider = FutureProvider<List<TransactionModel>>((ref) async {
  final user = ref.watch(authProvider);
  if (user == null || user.idUser == null) return [];
  
  final db = ref.read(databaseProvider);
  final filter = ref.watch(filterProvider);
  final all = await db.readAllTransactions(user.idUser!);

  final now = DateTime.now();
  late DateTime cutoff;

  switch (filter) {
    case TransactionFilter.week7:
      cutoff = now.subtract(const Duration(days: 7));
      break;
    case TransactionFilter.month1:
      cutoff = now.subtract(const Duration(days: 30));
      break;
    case TransactionFilter.month3:
      cutoff = now.subtract(const Duration(days: 90));
      break;
    case TransactionFilter.year1:
      cutoff = now.subtract(const Duration(days: 365));
      break;
  }

  return all.where((tx) => tx.timeStamp.isAfter(cutoff)).toList();
});

// Spending by category (for PieChart)
final spendingByCategoryProvider = FutureProvider<Map<int, double>>((ref) async {
  final transactions = await ref.watch(filteredTransactionProvider.future);
  final Map<int, double> categoryTotals = {};

  for (final tx in transactions) {
    if (tx.jenisArusKas == 'OUT') {
      categoryTotals[tx.idKategori] = (categoryTotals[tx.idKategori] ?? 0) + tx.nominal;
    }
  }
  return categoryTotals;
});
