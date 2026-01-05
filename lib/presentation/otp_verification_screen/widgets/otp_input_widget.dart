import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

/// OTP input widget with 6-digit boxes and auto-focus advancement
class OtpInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final bool hasError;

  const OtpInputWidget({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(
          color: theme.colorScheme.error,
          width: 2,
        ),
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Pinput(
        controller: controller,
        length: 6,
        defaultPinTheme: hasError ? errorPinTheme : defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        errorPinTheme: errorPinTheme,
        onCompleted: onCompleted,
        keyboardType: TextInputType.number,
        autofocus: true,
        hapticFeedbackType: HapticFeedbackType.lightImpact,
        animationDuration: const Duration(milliseconds: 200),
        animationCurve: Curves.easeOut,
        pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
        showCursor: true,
        cursor: Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
