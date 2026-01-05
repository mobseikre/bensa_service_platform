import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Quick actions widget for emergency, scheduled requests, and address selection
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onEmergencyPressed;
  final VoidCallback onScheduledPressed;
  final VoidCallback onAddressPressed;
  final String defaultAddress;

  const QuickActionsWidget({
    super.key,
    required this.onEmergencyPressed,
    required this.onScheduledPressed,
    required this.onAddressPressed,
    required this.defaultAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          // Emergency and Scheduled Request Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'طلب عاجل',
                  icon: 'emergency',
                  color: const Color(0xFFEF4444),
                  onPressed: onEmergencyPressed,
                  description: 'خدمة عاجلة خلال 2-4 ساعات',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildActionButton(
                  context: context,
                  label: 'طلب مجدول',
                  icon: 'schedule',
                  color: theme.colorScheme.primary,
                  onPressed: onScheduledPressed,
                  description: 'خدمة عادية خلال 6-12 ساعة',
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Address Selector
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onAddressPressed();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomIconWidget(
                      iconName: 'home',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العنوان الافتراضي',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          defaultAddress,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'arrow_forward_ios',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required String icon,
    required Color color,
    required VoidCallback onPressed,
    String? description,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: color,
              size: 32,
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 9.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
