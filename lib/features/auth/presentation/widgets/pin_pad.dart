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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 7),
          width: isFilled ? 13 : 12,
          height: isFilled ? 13 : 12,
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
                      : AppColors.border,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

// ── Number Pad ────────────────────────────────────────────────────────────────

const _kButtonSize = 68.0;
const _kGap = 14.0;

class NumberPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;
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
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3']),
        const SizedBox(height: _kGap),
        _row(['4', '5', '6']),
        const SizedBox(height: _kGap),
        _row(['7', '8', '9']),
        const SizedBox(height: _kGap),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            showBiometric
                ? _KeyButton.icon(
                    icon: biometricIcon,
                    color: AppColors.primary,
                    onTap: onBiometric ?? () {},
                  )
                : const SizedBox(width: _kButtonSize, height: _kButtonSize),
            const SizedBox(width: _kGap),
            _KeyButton(label: '0', onTap: () => onDigit('0')),
            const SizedBox(width: _kGap),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: _kGap),
          _KeyButton(label: digits[i], onTap: () => onDigit(digits[i])),
        ],
      ],
    );
  }
}

// ── Key Button ────────────────────────────────────────────────────────────────

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _KeyButton({required this.label, required this.onTap})
      : icon = null,
        color = null;

  const _KeyButton.icon({required this.icon, required this.color, required this.onTap})
      : label = null;

  @override
  Widget build(BuildContext context) {
    final isIcon = icon != null;

    return SizedBox(
      width: _kButtonSize,
      height: _kButtonSize,
      child: Material(
        color: isIcon ? Colors.transparent : AppColors.surface,
        borderRadius: BorderRadius.circular(_kButtonSize / 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kButtonSize / 2),
          splashColor: AppColors.primary.withValues(alpha: 0.15),
          highlightColor: AppColors.primary.withValues(alpha: 0.08),
          child: Container(
            decoration: isIcon
                ? null
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(_kButtonSize / 2),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
