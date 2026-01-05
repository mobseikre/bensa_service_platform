import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for technician availability toggle with status indicator
class AvailabilityToggleWidget extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onToggle;
  final bool isLoading;

  const AvailabilityToggleWidget({
    super.key,
    required this.isAvailable,
    required this.onToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAvailable
              ? [
                  const Color(0xFF10B981), // Green gradient for available
                  const Color(0xFF059669),
                  const Color(0xFF047857),
                ]
              : [
                  Colors.white, // Clean white for unavailable
                  const Color(0xFFF8FAFC),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable
                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                : const Color(0xFF64748B).withValues(alpha: 0.1),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CustomIconWidget(
                            iconName: isAvailable
                                ? 'check_circle'
                                : 'radio_button_unchecked',
                            color: isAvailable
                                ? Colors.white
                                : const Color(0xFF4F46E5),
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حالة التوفر',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isAvailable
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 0.3.h),
                            Text(
                              isAvailable
                                  ? 'متاح للعمل الآن'
                                  : 'غير متاح حالياً',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isAvailable
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              isLoading
                  ? Container(
                      width: 24.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAvailable
                                  ? Colors.white
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      width: 24.w, // Increased width to fit "غير متاح"
                      height: 5.h, // Slightly reduced height for sleeker look
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isAvailable
                              ? [
                                  Colors.white.withValues(alpha: 0.9),
                                  Colors.white
                                ]
                              : [
                                  const Color(0xFF4F46E5),
                                  const Color(0xFF7C3AED)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(30), // Pill shape
                        boxShadow: [
                          BoxShadow(
                            color: (isAvailable
                                    ? Colors.white
                                    : const Color(0xFF4F46E5))
                                .withValues(alpha: 0.3),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onToggle(!isAvailable),
                          borderRadius: BorderRadius.circular(30),
                          child: Center(
                            child: Text(
                              isAvailable ? 'متاح' : 'غير متاح',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: isAvailable
                                    ? const Color(0xFF10B981)
                                    : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11
                                    .sp, // Slightly smaller font for better fit
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          if (isAvailable) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.5.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'location_searching',
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الموقع النشط',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 0.3.h),
                        Text(
                          'موقعك يُحدث تلقائياً - لا حاجة لإعدادات إضافية',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
