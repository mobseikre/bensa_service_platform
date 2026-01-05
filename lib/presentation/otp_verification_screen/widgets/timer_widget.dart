import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Countdown timer widget with MM:SS format in Arabic numerals
class TimerWidget extends StatelessWidget {
  final int remainingSeconds;

  const TimerWidget({
    super.key,
    required this.remainingSeconds,
  });

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = remainingSeconds <= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomIconWidget(
          iconName: isExpired ? 'timer_off' : 'timer',
          color: isExpired
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          isExpired ? 'انتهت صلاحية الرمز' : _formatTime(remainingSeconds),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isExpired
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
