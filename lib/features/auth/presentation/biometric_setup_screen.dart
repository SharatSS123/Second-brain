import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_setup_screen.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _enabled = false;
  bool _available = false;
  bool _isFace = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final service = ref.read(authServiceProvider);
    final available = await service.isBiometricAvailable();
    if (!mounted) return;
    if (available) {
      final types = await service.availableBiometrics();
      setState(() {
        _available = true;
        _isFace = types.contains(BiometricType.face);
      });
    }
  }

  Future<void> _finish(bool enable) async {
    setState(() => _saving = true);
    await ref.read(authNotifierProvider.notifier).finishBiometricSetup(enable);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final biometricIcon = _isFace ? Icons.face_rounded : Icons.fingerprint_rounded;
    final biometricLabel = _isFace ? 'Face ID' : 'Fingerprint';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Purple glow
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
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  const CortexLogo(size: 72),
                  const SizedBox(height: 16),
                  const Text(
                    'CORTEX',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 7,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Biometric icon circle
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.card,
                      border: Border.all(
                        color: _enabled
                            ? AppColors.primary
                            : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      biometricIcon,
                      size: 48,
                      color: _enabled ? AppColors.primary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _available
                        ? 'Enable $biometricLabel'
                        : 'Biometrics Unavailable',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _available
                        ? 'Unlock CORTEX faster without typing\nyour PIN every time.'
                        : 'Your device doesn\'t support biometric\nauthentication. You can use your PIN.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  if (_available) ...[
                    // Toggle card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _enabled
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(biometricIcon,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Use $biometricLabel',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const Text('Quick unlock on app open',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: (v) => setState(() => _enabled = v),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Primary action button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : () => _finish(_enabled),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _enabled ? 'Enable & Continue' : 'Continue',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),

                  if (_available) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : () => _finish(false),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Step indicator
                  const OnboardingSteps(current: 2),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
