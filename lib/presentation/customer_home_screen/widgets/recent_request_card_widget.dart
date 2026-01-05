import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Recent request card widget displaying request information
class RecentRequestCardWidget extends StatelessWidget {
  final String serviceType;
  final String status;
  final Color statusColor;
  final String? technicianName;
  final String? technicianAvatar;
  final String? technicianAvatarLabel;
  final String requestDate;
  final String location;
  final String priority;
  final VoidCallback onTap;

  const RecentRequestCardWidget({
    super.key,
    required this.serviceType,
    required this.status,
    required this.statusColor,
    this.technicianName,
    this.technicianAvatar,
    this.technicianAvatarLabel,
    required this.requestDate,
    required this.location,
    required this.priority,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
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
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: _getServiceIcon(serviceType),
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          serviceType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'location_on',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  requestDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 4.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: priority == 'عاجل'
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: priority == 'عاجل'
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            if (technicianName != null) ...[
              SizedBox(height: 1.5.h),
              Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
                height: 1,
              ),
              SizedBox(height: 1.5.h),
              Row(
                children: [
                  technicianAvatar != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomImageWidget(
                            imageUrl: technicianAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            semanticLabel:
                                technicianAvatarLabel ?? 'صورة الفني',
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CustomIconWidget(
                            iconName: 'person',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الفني',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          technicianName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'سباكة':
        return 'plumbing';
      case 'كهرباء':
        return 'electrical_services';
      case 'تنظيف':
        return 'cleaning_services';
      case 'تكييف':
        return 'ac_unit';
      case 'نجارة':
        return 'carpenter';
      default:
        return 'build';
    }
  }
}
