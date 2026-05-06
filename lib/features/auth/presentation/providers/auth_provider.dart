import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/user/data/models/user_model.dart';
import 'package:duitly/core/providers/database_provider.dart';

class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return null; // Default: Not logged in on app start
  }

  void login(UserModel user) {
    state = user;
  }

  void logout() {
    state = null;
  }

  Future<void> refreshUser() async {
    if (state != null) {
      final db = ref.read(databaseProvider);
      final updated = await db.readUserByEmail(state!.email);
      state = updated;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});
