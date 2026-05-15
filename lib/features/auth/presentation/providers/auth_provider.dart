import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/user/data/models/user_model.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    return null; // Default: Not logged in on app start
  }

  void setInitialUser(UserModel user) {
    state = user;
  }

  Future<void> login(UserModel user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email);
  }

  Future<void> logout() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
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
