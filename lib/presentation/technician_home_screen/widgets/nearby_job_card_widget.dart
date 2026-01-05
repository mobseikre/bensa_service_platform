import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for displaying a single nearby job request card
class NearbyJobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onViewDetails;
  final bool isLoading;

  const NearbyJobCardWidget({
    super.key,
    required this.job,
    required this.onViewDetails,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = job['priority'] as String? ?? 'normal';
    final distance = job['distance'] as double? ?? 0.0;
    final estimatedEarnings = job['estimatedEarnings'] as double? ?? 0.0;
    final customerRating = job['customerRating'] as double? ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priority == 'urgent'
              ? const Color(0xFFEF4444)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: priority == 'urgent' ? 2 : 1,
        ),
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
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName:
                            _getCategoryIcon(job['category'] as String? ?? ''),
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
                            job['category'] as String? ?? 'خدمة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'location_on',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                '${distance.toStringAsFixed(1)} كم',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (priority == 'urgent')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'priority_high',
                        color: const Color(0xFFEF4444),
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'عاجل',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            job['description'] as String? ?? 'لا يوجد وصف',
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'star',
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      customerRating.toStringAsFixed(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'تقييم العميل',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${estimatedEarnings.toStringAsFixed(0)} د.ل',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: isLoading ? null : onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'عرض التفاصيل',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'سباكة':
        return 'plumbing';
      case 'كهرباء':
        return 'electrical_services';
      case 'نجارة':
        return 'carpenter';
      case 'تكييف':
        return 'ac_unit';
      case 'دهان':
        return 'format_paint';
      default:
        return 'build';
    }
  }
}
