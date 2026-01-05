import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Notification preferences with toggle switches
class NotificationPreferencesWidget extends StatefulWidget {
  final bool jobAlerts;
  final bool customerMessages;
  final bool earningsUpdates;
  final bool promotionalContent;
  final ValueChanged<bool> onJobAlertsChanged;
  final ValueChanged<bool> onCustomerMessagesChanged;
  final ValueChanged<bool> onEarningsUpdatesChanged;
  final ValueChanged<bool> onPromotionalContentChanged;

  const NotificationPreferencesWidget({
    super.key,
    required this.jobAlerts,
    required this.customerMessages,
    required this.earningsUpdates,
    required this.promotionalContent,
    required this.onJobAlertsChanged,
    required this.onCustomerMessagesChanged,
    required this.onEarningsUpdatesChanged,
    required this.onPromotionalContentChanged,
  });

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'تفضيلات الإشعارات',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildNotificationToggle(
            context,
            icon: 'work',
            title: 'تنبيهات الوظائف',
            subtitle: 'إشعارات الوظائف الجديدة القريبة منك',
            value: widget.jobAlerts,
            onChanged: widget.onJobAlertsChanged,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildNotificationToggle(
            context,
            icon: 'message',
            title: 'رسائل العملاء',
            subtitle: 'إشعارات الرسائل الجديدة من العملاء',
            value: widget.customerMessages,
            onChanged: widget.onCustomerMessagesChanged,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildNotificationToggle(
            context,
            icon: 'account_balance_wallet',
            title: 'تحديثات الأرباح',
            subtitle: 'إشعارات الدفعات والأرباح الجديدة',
            value: widget.earningsUpdates,
            onChanged: widget.onEarningsUpdatesChanged,
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildNotificationToggle(
            context,
            icon: 'campaign',
            title: 'المحتوى الترويجي',
            subtitle: 'العروض والتحديثات الترويجية',
            value: widget.promotionalContent,
            onChanged: widget.onPromotionalContentChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: icon,
                size: 5.w,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
