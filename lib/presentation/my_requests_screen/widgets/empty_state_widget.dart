import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Empty state widget for different filter scenarios
class EmptyStateWidget extends StatelessWidget {
  final String selectedStatus;
  final bool hasSearchQuery;

  const EmptyStateWidget({
    super.key,
    required this.selectedStatus,
    this.hasSearchQuery = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String description;
    String iconName;

    if (hasSearchQuery) {
      title = 'لا توجد نتائج';
      description = 'لم نتمكن من العثور على أي طلبات تطابق بحثك';
      iconName = 'search_off';
    } else if (selectedStatus == 'all') {
      title = 'لا توجد طلبات';
      description = 'ابدأ بإنشاء طلب خدمة جديد';
      iconName = 'inbox';
    } else if (selectedStatus == 'active') {
      title = 'لا توجد طلبات نشطة';
      description = 'جميع طلباتك مكتملة أو ملغاة';
      iconName = 'check_circle_outline';
    } else if (selectedStatus == 'completed') {
      title = 'لا توجد طلبات مكتملة';
      description = 'لم تكمل أي طلبات بعد';
      iconName = 'task_alt';
    } else {
      title = 'لا توجد طلبات ملغاة';
      description = 'لم تقم بإلغاء أي طلبات';
      iconName = 'cancel';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: iconName,
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (selectedStatus == 'all' && !hasSearchQuery) ...[
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/create-request-screen');
                },
                icon: CustomIconWidget(
                  iconName: 'add',
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text('إنشاء طلب جديد'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.8.h,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
