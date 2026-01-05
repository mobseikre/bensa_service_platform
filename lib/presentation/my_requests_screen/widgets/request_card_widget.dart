import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Request card widget displaying individual request information
class RequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onTap;

  const RequestCardWidget({
    super.key,
    required this.request,
    required this.onTap,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'pending':
        return const Color(0xFF2563EB);
      case 'assigned':
      case 'on_the_way':
      case 'started':
        return const Color(0xFFF59E0B);
      case 'completed':
      case 'work_done':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = request['status'] as String;
    final statusColor = _getStatusColor(status, theme);
    final hasTechnician = request['technicianName'] != null;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        shadowColor: theme.colorScheme.shadow,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Category icon
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: request['categoryIcon'] as String,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),

                    // Request info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['description'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatDate(request['createdAt'] as DateTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        request['statusArabic'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Technician info (if assigned)
                if (hasTechnician) ...[
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.light
                          ? const Color(0xFFF9FAFB)
                          : const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 5.w,
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          child: request['technicianAvatar'] != null
                              ? ClipOval(
                                  child: CustomImageWidget(
                                    imageUrl:
                                        request['technicianAvatar'] as String,
                                    width: 10.w,
                                    height: 10.w,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        request['technicianAvatarSemanticLabel']
                                            as String,
                                  ),
                                )
                              : CustomIconWidget(
                                  iconName: 'person',
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفني المعين',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                request['technicianName'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'chevron_left',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],

                // Priority indicator (if urgent)
                if (request['priority'] == 'urgent') ...[
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'priority_high',
                        color: const Color(0xFFEF4444),
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'طلب عاجل',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
