import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'pin_change_screen.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _isFace = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ref.read(authServiceProvider);
    final available = await service.isBiometricAvailable();
    final enabled = await service.isBiometricEnabled();
    if (available) {
      final types = await service.availableBiometrics();
      setState(() {
        _biometricAvailable = true;
        _biometricEnabled = enabled;
        _isFace = types.contains(BiometricType.face);
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final service = ref.read(authServiceProvider);
    // If enabling, verify with biometric first to ensure it's valid
    if (value) {
      final success = await service.authenticateWithBiometric();
      if (!success) return; // User cancelled or failed auth
    }
    await ref.read(authNotifierProvider.notifier).finishBiometricSetup(value);
    setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final biometricIcon = _isFace ? Icons.face_rounded : Icons.fingerprint_rounded;
    final biometricLabel = _isFace ? 'Face ID' : 'Fingerprint';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Purple glow background
          Positioned(
            top: -size.height * 0.15,
            left: size.width * 0.5 - 200,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 10),
                const Text(
                  'ACCESS PROTECTION',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // PIN change card
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                    title: const Text(
                      'Change Secure PIN',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Update your 6-digit access PIN',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PinChangeScreen()),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                if (_biometricAvailable) ...[
                  const Text(
                    'BIOMETRICS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Biometrics toggle card
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border, width: 0.5),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(biometricIcon, color: AppColors.green, size: 20),
                      ),
                      title: Text(
                        'Enable $biometricLabel',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Unlock CORTEX using your $biometricLabel',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      value: _biometricEnabled,
                      activeColor: AppColors.green,
                      onChanged: _toggleBiometrics,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
