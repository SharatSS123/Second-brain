import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _pinHashKey = 'sb_pin_hash';
  static const _pinSetKey = 'sb_pin_set';
  static const _profileNameKey = 'sb_profile_name';
  static const _profileEmailKey = 'sb_profile_email';
  static const _profileDobKey = 'sb_profile_dob';
  static const _biometricEnabledKey = 'sb_biometric_enabled';

  final _localAuth = LocalAuthentication();

  Future<bool> isProfileSet() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_profileNameKey) ?? '').isNotEmpty;
  }

  Future<void> saveProfile({
    required String name,
    String? email,
    String? dob,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_profileEmailKey, email);
    }
    if (dob != null && dob.isNotEmpty) {
      await prefs.setString(_profileDobKey, dob);
    }
  }

  Future<String?> getProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_profileNameKey);
    return (name == null || name.isEmpty) ? null : name;
  }

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetKey) ?? false;
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(pin));
    await prefs.setBool(_pinSetKey, true);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinHashKey);
    return stored != null && stored == _hash(pin);
  }

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to open CORTEX',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
