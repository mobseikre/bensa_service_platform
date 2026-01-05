import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Action buttons based on request status
class ActionButtonsWidget extends StatelessWidget {
  final String status;
  final VoidCallback? onCancelRequest;
  final VoidCallback? onTrackTechnician;

  const ActionButtonsWidget({
    super.key,
    required this.status,
    this.onCancelRequest,
    this.onTrackTechnician,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
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
        children: [
          if (status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCancelRequest,
                icon: CustomIconWidget(
                  iconName: 'cancel',
                  color: theme.colorScheme.onError,
                  size: 20,
                ),
                label: Text('إلغاء الطلب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
          ],
          if (status == 'on_the_way') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTrackTechnician,
                icon: CustomIconWidget(
                  iconName: 'my_location',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text('تتبع الفني'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
