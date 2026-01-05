import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displaying technician's custody summary (commission owed)
class EarningsCardWidget extends StatelessWidget {
  final int completedJobs;
  final double averageRating;
  final double pendingCustody;
  final int pendingCustodyCount;
  final bool isBlocked;
  final Map<String, dynamic>? workWindow;

  const EarningsCardWidget({
    super.key,
    required this.completedJobs,
    required this.averageRating,
    required this.pendingCustody,
    required this.pendingCustodyCount,
    this.isBlocked = false,
    this.workWindow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'العهدة المعلقة',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pendingCustody.toStringAsFixed(2),
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 2.w),
              Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  'د.ل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          if (pendingCustodyCount > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isBlocked
                    ? Colors.red.withValues(alpha: 0.25)
                    : Colors.orange.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(isBlocked ? Icons.block : Icons.info_outline,
                      color: Colors.white, size: 16),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      isBlocked
                          ? 'موقوف لعدم التسوية'
                          : 'لديك $pendingCustodyCount طلب يحتاج تسوية',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight:
                            isBlocked ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (workWindow != null && workWindow!['start'] != null)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: Colors.white70, size: 14),
                    SizedBox(width: 2.w),
                    Text(
                      'ساعات العمل: ${workWindow!['start']} - ${workWindow!['end'] ?? '00:00'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'check_circle',
                  label: 'مكتمل',
                  value: '$completedJobs',
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: _buildStatItem(
                  context,
                  icon: 'star',
                  label: 'التقييم',
                  value: averageRating.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
