import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Summary cards displaying key earnings metrics
class EarningsSummaryCardsWidget extends StatelessWidget {
  final String totalIncome;
  final int completedJobs;
  final String averageJobValue;
  final double customerRating;

  const EarningsSummaryCardsWidget({
    super.key,
    required this.totalIncome,
    required this.completedJobs,
    required this.averageJobValue,
    required this.customerRating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'إجمالي العهدة المسددة',
                  '$totalIncome د.ل',
                  CustomIconWidget(
                    iconName: 'trending_up',
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                  theme.colorScheme.tertiary.withValues(alpha: 0.1),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'الوظائف المكتملة',
                  '$completedJobs',
                  CustomIconWidget(
                    iconName: 'check_circle',
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                  theme.colorScheme.tertiary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'متوسط العهدة بالطلب',
                  '$averageJobValue د.ل',
                  CustomIconWidget(
                    iconName: 'receipt',
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'تقييم العملاء',
                  customerRating.toStringAsFixed(1),
                  CustomIconWidget(
                    iconName: 'star',
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    Widget icon,
    Color backgroundColor,
  ) {
    final theme = Theme.of(context);

    // Define card gradient colors based on the title
    List<Color> gradientColors;
    Color iconColor;

    if (title.contains('إجمالي العهدة المسددة')) {
      gradientColors = [
        const Color(0xFF10B981).withValues(alpha: 0.1), // Emerald - paid custody
        const Color(0xFF059669).withValues(alpha: 0.05),
      ];
      iconColor = const Color(0xFF10B981);
    } else if (title.contains('الوظائف المكتملة')) {
      gradientColors = [
        const Color(0xFF3B82F6).withValues(alpha: 0.1), // Blue
        const Color(0xFF2563EB).withValues(alpha: 0.05),
      ];
      iconColor = const Color(0xFF3B82F6);
    } else if (title.contains('متوسط العهدة')) {
      gradientColors = [
        const Color(0xFFF59E0B).withValues(alpha: 0.1), // Amber - custody per job
        const Color(0xFFD97706).withValues(alpha: 0.05),
      ];
      iconColor = const Color(0xFFF59E0B);
    } else {
      gradientColors = [
        const Color(0xFFEC4899).withValues(alpha: 0.1), // Pink
        const Color(0xFFDB2777).withValues(alpha: 0.05),
      ];
      iconColor = const Color(0xFFEC4899);
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced icon container
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  iconColor.withValues(alpha: 0.2),
                  iconColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: CustomIconWidget(
              iconName: _getIconName(title),
              color: iconColor,
              size: 24,
            ),
          ),

          SizedBox(height: 2.h),

          // Title with enhanced styling
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 11.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 1.h),

          // Value with enhanced styling
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              fontSize: 18.sp,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 1.h),

          // Progress indicator (decorative)
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  iconColor,
                  iconColor.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconName(String title) {
    if (title.contains('إجمالي العهدة المسددة')) {
      return 'trending_up';
    } else if (title.contains('الوظائف المكتملة')) {
      return 'check_circle';
    } else if (title.contains('متوسط العهدة')) {
      return 'receipt';
    } else {
      return 'star';
    }
  }
}
