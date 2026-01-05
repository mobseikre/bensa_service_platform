import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Status update section widget with action buttons for workflow progression
class StatusUpdateSectionWidget extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusUpdate;

  const StatusUpdateSectionWidget({
    super.key,
    required this.currentStatus,
    required this.onStatusUpdate,
  });

  Map<String, dynamic> _getNextAction() {
    switch (currentStatus.toLowerCase()) {
      case 'assigned':
      case 'مقبول':
        return {
          'action': 'on_the_way',
          'label': 'في الطريق',
          'icon': 'directions_car',
          'color': const Color(0xFF2563EB),
        };
      case 'on_the_way':
      case 'في الطريق':
        return {
          'action': 'arrived',
          'label': 'وصلت',
          'icon': 'location_on',
          'color': const Color(0xFFF59E0B),
        };
      case 'arrived':
      case 'وصلت':
        return {
          'action': 'started',
          'label': 'بدء العمل',
          'icon': 'build',
          'color': const Color(0xFF10B981),
        };
      case 'started':
      case 'بدأ العمل':
        return {
          'action': 'work_done',
          'label': 'العمل منتهي',
          'icon': 'check_circle',
          'color': const Color(0xFF10B981),
        };
      default:
        return {
          'action': '',
          'label': 'مكتمل',
          'icon': 'done_all',
          'color': const Color(0xFF10B981),
        };
    }
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String action,
    String label,
  ) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'تأكيد الحالة',
          style: theme.textTheme.titleLarge,
        ),
        content: Text(
          'هل أنت متأكد من تحديث الحالة إلى "$label"؟',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'إلغاء',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, true);
            },
            child: Text(
              'تأكيد',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onStatusUpdate(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextAction = _getNextAction();

    if (nextAction['action'] == '') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تحديث الحالة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 7.h,
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmationDialog(
                context,
                nextAction['action'] as String,
                nextAction['label'] as String,
              ),
              icon: CustomIconWidget(
                iconName: nextAction['icon'] as String,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              label: Text(
                nextAction['label'] as String,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: nextAction['color'] as Color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
