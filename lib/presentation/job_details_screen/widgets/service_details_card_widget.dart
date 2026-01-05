import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Service details card widget displaying job information and photos
class ServiceDetailsCardWidget extends StatelessWidget {
  final Map<String, dynamic> serviceData;

  const ServiceDetailsCardWidget({
    super.key,
    required this.serviceData,
  });

  Color _getPriorityColor(String priority, ThemeData theme) {
    switch (priority.toLowerCase()) {
      case 'عاجل':
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'عالي':
      case 'high':
        return const Color(0xFFF59E0B);
      case 'متوسط':
      case 'medium':
        return const Color(0xFF10B981);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos =
        (serviceData['photos'] as List?)?.cast<Map<String, dynamic>>() ?? [];

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
            'تفاصيل الخدمة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildDetailRow(
            context,
            'الفئة',
            serviceData['category'] as String? ?? 'غير محدد',
            'category',
          ),
          SizedBox(height: 1.5.h),
          _buildDetailRow(
            context,
            'الأولوية',
            serviceData['priority'] as String? ?? 'متوسط',
            'priority',
            valueColor: _getPriorityColor(
              serviceData['priority'] as String? ?? 'متوسط',
              theme,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildDetailRow(
            context,
            'الوقت المطلوب',
            serviceData['requestedTime'] as String? ?? 'غير محدد',
            'schedule',
          ),
          SizedBox(height: 2.h),
          Text(
            'الوصف',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            serviceData['description'] as String? ?? 'لا يوجد وصف',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          if (photos.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              'صور الخدمة',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            SizedBox(
              height: 20.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (context, index) => SizedBox(width: 2.w),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomImageWidget(
                      imageUrl: photo['url'] as String? ?? '',
                      width: 30.w,
                      height: 20.h,
                      fit: BoxFit.cover,
                      semanticLabel: photo['semanticLabel'] as String? ??
                          'صورة الخدمة ${index + 1}',
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    String iconName, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.primary,
          size: 18,
        ),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
