import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Permission buttons widget
/// Shows primary and secondary action buttons
class PermissionButtonsWidget extends StatelessWidget {
  final bool isLoading;
  final bool permissionDenied;
  final String userRole;
  final VoidCallback onRequestPermission;
  final VoidCallback onLearnMore;
  final VoidCallback onOpenSettings;
  final VoidCallback onManualAddress;
  final VoidCallback onChangeRole;

  const PermissionButtonsWidget({
    super.key,
    required this.isLoading,
    required this.permissionDenied,
    required this.userRole,
    required this.onRequestPermission,
    required this.onLearnMore,
    required this.onOpenSettings,
    required this.onManualAddress,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Primary button
        SizedBox(
          width: double.infinity,
          height: 6.h,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : (permissionDenied ? onOpenSettings : onRequestPermission),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              permissionDenied ? 'فتح الإعدادات' : 'السماح بالوصول',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Secondary button - Learn More or Alternative options
        if (!permissionDenied)
          TextButton(
            onPressed: onLearnMore,
            child: Text(
              'معرفة المزيد',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else ...[
          // Alternative options for denied permission
          if (userRole == 'customer')
            TextButton(
              onPressed: onManualAddress,
              child: Text(
                'إدخال العنوان يدوياً',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            TextButton(
              onPressed: onChangeRole,
              child: Text(
                'التسجيل كعميل بدلاً من ذلك',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
