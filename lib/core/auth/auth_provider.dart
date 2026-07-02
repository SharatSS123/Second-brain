import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';

enum AuthStatus { unknown, profileNotSet, pinNotSet, biometricSetup, locked, unlocked }

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthNotifier extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    Future.microtask(_checkInitial);
    return AuthStatus.unknown;
  }

  Future<void> _checkInitial() async {
    final service = ref.read(authServiceProvider);
    final isProfileSet = await service.isProfileSet();
    if (!isProfileSet) {
      state = AuthStatus.profileNotSet;
      return;
    }
    final isPinSet = await service.isPinSet();
    state = isPinSet ? AuthStatus.locked : AuthStatus.pinNotSet;
  }

  Future<void> setupProfile(String name, String? email, String? dob) async {
    await ref.read(authServiceProvider).saveProfile(
          name: name,
          email: email,
          dob: dob,
        );
    state = AuthStatus.pinNotSet;
  }

  Future<void> setupPin(String pin) async {
    await ref.read(authServiceProvider).savePin(pin);
    state = AuthStatus.biometricSetup;
  }

  Future<void> finishBiometricSetup(bool enabled) async {
    await ref.read(authServiceProvider).setBiometricEnabled(enabled);
    state = AuthStatus.unlocked;
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

  void lock() => state = AuthStatus.locked;
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthStatus>(AuthNotifier.new);
