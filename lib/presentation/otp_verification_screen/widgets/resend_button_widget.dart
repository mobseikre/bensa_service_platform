import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Resend OTP button with loading state
class ResendButtonWidget extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const ResendButtonWidget({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: isEnabled && !isLoading
          ? () {
              HapticFeedback.lightImpact();
              onPressed();
            }
          : null,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        disabledForegroundColor:
            theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.38),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'refresh',
                  color: isEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.38),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'إعادة إرسال الرمز',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
    );
  }
}
