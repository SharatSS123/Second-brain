import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/pin_pad.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  static const _pinLength = 6;

  String _entered = '';
  bool _hasError = false;
  bool _biometricAvailable = false;
  IconData _biometricIcon = Icons.fingerprint_rounded;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _checkBiometric();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final service = ref.read(authServiceProvider);
    final enabled = await service.isBiometricEnabled();
    if (!enabled || !mounted) return;
    final available = await service.isBiometricAvailable();
    if (!available || !mounted) return;
    final types = await service.availableBiometrics();
    setState(() {
      _biometricAvailable = true;
      _biometricIcon = types.contains(BiometricType.face)
          ? Icons.face_rounded
          : Icons.fingerprint_rounded;
    });
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    await ref.read(authNotifierProvider.notifier).biometricAuth();
  }

  void _onDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _hasError = false;
    });
    if (_entered.length == _pinLength) _verifyPin();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    final success =
        await ref.read(authNotifierProvider.notifier).pinAuth(_entered);
    if (!success && mounted) {
      _shakeController.forward(from: 0);
      setState(() {
        _hasError = true;
        _entered = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Purple radial glow behind the logo
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
                    AppColors.primary.withValues(alpha: 0.25),
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
                  const Spacer(flex: 2),

                  // Logo + name
                  const CortexLogo(size: 88),
                  const SizedBox(height: 20),
                  const Text(
                    'CORTEX',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your intelligent second brain',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Divider with "ENTER PIN"
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.divider, thickness: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _hasError ? 'INCORRECT PIN' : 'ENTER PIN',
                          style: TextStyle(
                            color: _hasError
                                ? AppColors.red
                                : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: AppColors.divider, thickness: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // PIN dots with shake
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          _shakeController.isAnimating
                              ? _shakeAnimation.value *
                                  ((_shakeController.value * 10).round().isEven
                                      ? 1
                                      : -1)
                              : 0,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: PinDots(
                      length: _pinLength,
                      filled: _entered.length,
                      hasError: _hasError,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Number pad
                  NumberPad(
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    showBiometric: _biometricAvailable,
                    biometricIcon: _biometricIcon,
                    onBiometric: _tryBiometric,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
