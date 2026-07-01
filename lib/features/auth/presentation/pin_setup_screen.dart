import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/pin_pad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  static const _pinLength = 6;

  String _entered = '';
  String? _firstPin;
  bool _hasError = false;
  bool _isSaving = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  bool get _isConfirmStep => _firstPin != null;

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_entered.length >= _pinLength || _isSaving) return;
    setState(() {
      _entered += d;
      _hasError = false;
    });
    if (_entered.length == _pinLength) _handleComplete();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      _hasError = false;
    });
  }

  Future<void> _handleComplete() async {
    if (!_isConfirmStep) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _firstPin = _entered;
        _entered = '';
      });
    } else {
      if (_entered == _firstPin) {
        setState(() => _isSaving = true);
        await ref.read(authNotifierProvider.notifier).setupPin(_entered);
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _hasError = true;
          _entered = '';
        });
      }
    }
  }

  void _goBack() {
    setState(() {
      _firstPin = null;
      _entered = '';
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                  const SizedBox(height: 12),

                  // Back button on confirm step
                  SizedBox(
                    height: 44,
                    child: _isConfirmStep
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: AppColors.textSecondary),
                              onPressed: _goBack,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const Spacer(flex: 2),

                  // CORTEX logo
                  const CortexLogo(size: 80),
                  const SizedBox(height: 18),
                  const Text(
                    'CORTEX',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 7,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Step title
                  Text(
                    _isConfirmStep ? 'Confirm PIN' : 'Create PIN',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isConfirmStep
                        ? 'Enter your PIN once more to confirm'
                        : 'Choose a $_pinLength-digit PIN to secure CORTEX',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // PIN label
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.divider, thickness: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          _hasError
                              ? "PINS DON'T MATCH"
                              : _isConfirmStep
                                  ? 'CONFIRM PIN'
                                  : 'NEW PIN',
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

                  // Step dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepDot(active: !_isConfirmStep, done: _isConfirmStep),
                      const SizedBox(width: 8),
                      _StepDot(active: _isConfirmStep, done: false),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Number pad
                  NumberPad(
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    showBiometric: false,
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

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: done || active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
