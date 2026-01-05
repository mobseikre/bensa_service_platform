import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displayed when no nearby jobs are available
class EmptyJobsWidget extends StatelessWidget {
  final bool isAvailable;

  const EmptyJobsWidget({
    super.key,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: isAvailable ? 'search' : 'work_off',
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              isAvailable ? 'لا توجد وظائف قريبة' : 'أنت غير متاح حاليًا',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              isAvailable
                  ? 'سنقوم بإعلامك عندما تكون هناك طلبات جديدة في منطقتك'
                  : 'قم بتشغيل التوفر للبدء في تلقي طلبات العمل',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isAvailable) ...[
              SizedBox(height: 3.h),
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'lightbulb_outline',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'نصائح لزيادة الطلبات',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildTipItem(
                      context,
                      'حافظ على تقييم عالٍ من خلال تقديم خدمة ممتازة',
                    ),
                    SizedBox(height: 1.h),
                    _buildTipItem(
                      context,
                      'قم بتوسيع منطقة الخدمة الخاصة بك',
                    ),
                    SizedBox(height: 1.h),
                    _buildTipItem(
                      context,
                      'كن متاحًا خلال ساعات الذروة',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 0.5.h),
          child: Container(
            width: 1.5.w,
            height: 1.5.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
