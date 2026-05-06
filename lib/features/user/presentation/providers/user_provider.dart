import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_model.dart';

final userProvider = Provider<AsyncValue<UserModel?>>((ref) {
  final user = ref.watch(authProvider);
  return AsyncValue.data(user);
});
