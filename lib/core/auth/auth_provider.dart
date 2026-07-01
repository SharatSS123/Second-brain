import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

enum AuthStatus { unknown, pinNotSet, locked, unlocked }

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    Future.microtask(_checkInitial);
    return AuthStatus.unknown;
  }

  Future<void> _checkInitial() async {
    final isPinSet = await ref.read(authServiceProvider).isPinSet();
    state = isPinSet ? AuthStatus.locked : AuthStatus.pinNotSet;
  }

  Future<bool> biometricAuth() async {
    final success =
        await ref.read(authServiceProvider).authenticateWithBiometric();
    if (success) state = AuthStatus.unlocked;
    return success;
  }

  Future<bool> pinAuth(String pin) async {
    final success = await ref.read(authServiceProvider).verifyPin(pin);
    if (success) state = AuthStatus.unlocked;
    return success;
  }

  Future<void> setupPin(String pin) async {
    await ref.read(authServiceProvider).savePin(pin);
    state = AuthStatus.unlocked;
  }

  void lock() => state = AuthStatus.locked;
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
