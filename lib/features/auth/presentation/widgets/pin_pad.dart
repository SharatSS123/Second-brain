import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool hasError;

  const PinDots({
    super.key,
    required this.length,
    required this.filled,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final isFilled = i < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasError
                ? AppColors.red
                : isFilled
                    ? AppColors.primary
                    : Colors.transparent,
            border: Border.all(
              color: hasError
                  ? AppColors.red
                  : isFilled
                      ? AppColors.primary
                      : AppColors.textMuted,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class NumberPad extends StatelessWidget {
  final VoidCallback? onBiometric;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool showBiometric;
  final IconData biometricIcon;

  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.showBiometric = false,
    this.biometricIcon = Icons.fingerprint_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: 12),
        _row(['4', '5', '6']),
        const SizedBox(height: 12),
        _row(['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Biometric or empty
            showBiometric
                ? _KeyButton.icon(
                    icon: biometricIcon,
                    color: AppColors.primary,
                    onTap: onBiometric ?? () {},
                  )
                : const SizedBox(width: 80),
            const SizedBox(width: 12),
            _KeyButton(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: 12),
            _KeyButton.icon(
              icon: Icons.backspace_outlined,
              color: AppColors.textSecondary,
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
          child: _KeyButton(label: e.value, onTap: () => onDigit(e.value)),
        );
      }).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _KeyButton({this.label, required this.onTap})
      : icon = null,
        color = null;

  const _KeyButton.icon({required this.icon, required this.color, required this.onTap})
      : label = null;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        splashColor: AppColors.primary.withValues(alpha: 0.2),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                    ),
                  )
                : Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }
}
