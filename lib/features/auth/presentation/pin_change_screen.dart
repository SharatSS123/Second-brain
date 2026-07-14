import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/pin_pad.dart';

enum PinChangeStep { verifyCurrent, enterNew, confirmNew }

class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen>
    with SingleTickerProviderStateMixin {
  static const _pinLength = 6;

  PinChangeStep _step = PinChangeStep.verifyCurrent;
  String _entered = '';
  String? _newPin;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;

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
    final service = ref.read(authServiceProvider);

    if (_step == PinChangeStep.verifyCurrent) {
      final isValid = await service.verifyPin(_entered);
      if (isValid) {
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() {
          _step = PinChangeStep.enterNew;
          _entered = '';
        });
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _hasError = true;
          _errorMessage = 'INCORRECT PIN';
          _entered = '';
        });
      }
    } else if (_step == PinChangeStep.enterNew) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _newPin = _entered;
        _step = PinChangeStep.confirmNew;
        _entered = '';
      });
    } else if (_step == PinChangeStep.confirmNew) {
      if (_entered == _newPin) {
        setState(() => _isSaving = true);
        await service.savePin(_entered);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN changed successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _shakeController.forward(from: 0);
        setState(() {
          _hasError = true;
          _errorMessage = "PINS DON'T MATCH";
          _entered = '';
        });
      }
    }
  }

  void _goBack() {
    setState(() {
      if (_step == PinChangeStep.confirmNew) {
        _step = PinChangeStep.enterNew;
      } else if (_step == PinChangeStep.enterNew) {
        _step = PinChangeStep.verifyCurrent;
      }
      _entered = '';
      _newPin = null;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    String titleText = 'Verify Current PIN';
    String subtitleText = 'Enter your current 6-digit secure PIN';
    String dotsLabel = 'CURRENT PIN';

    if (_step == PinChangeStep.enterNew) {
      titleText = 'Create New PIN';
      subtitleText = 'Choose a new 6-digit PIN to secure CORTEX';
      dotsLabel = 'NEW PIN';
    } else if (_step == PinChangeStep.confirmNew) {
      titleText = 'Confirm New PIN';
      subtitleText = 'Enter your new PIN once more to confirm';
      dotsLabel = 'CONFIRM NEW PIN';
    }

    if (_hasError) {
      dotsLabel = _errorMessage;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
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

                  // Back button
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textSecondary),
                        onPressed: _step == PinChangeStep.verifyCurrent
                            ? () => Navigator.pop(context)
                            : _goBack,
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // CORTEX logo
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
                  const SizedBox(height: 24),

                  // Step title
                  Text(
                    titleText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitleText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 1),

                  // PIN label
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: AppColors.divider, thickness: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          dotsLabel,
                          style: TextStyle(
                            color: _hasError ? AppColors.red : AppColors.textMuted,
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

                  const Spacer(flex: 2),

                  // Number pad
                  Center(
                    child: NumberPad(
                      onDigit: _onDigit,
                      onDelete: _onDelete,
                      showBiometric: false,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
