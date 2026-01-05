import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Password strength indicator widget
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int _calculateStrength() {
    if (password.isEmpty) return 0;

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    return strength;
  }

  String _getStrengthText() {
    final strength = _calculateStrength();
    switch (strength) {
      case 0:
      case 1:
        return 'ضعيفة';
      case 2:
        return 'متوسطة';
      case 3:
        return 'جيدة';
      case 4:
        return 'قوية';
      default:
        return '';
    }
  }

  Color _getStrengthColor(ThemeData theme) {
    final strength = _calculateStrength();
    switch (strength) {
      case 0:
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF10B981);
      case 4:
        return const Color(0xFF10B981);
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = _calculateStrength();

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 1.h),
        Row(
          children: List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 0.5.h,
                margin: EdgeInsets.only(left: index < 3 ? 1.w : 0),
                decoration: BoxDecoration(
                  color: index < strength
                      ? _getStrengthColor(theme)
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 0.5.h),
        Text(
          'قوة كلمة المرور: ${_getStrengthText()}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _getStrengthColor(theme),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
