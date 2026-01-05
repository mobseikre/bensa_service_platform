import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Time period selector for filtering earnings data
class TimePeriodSelectorWidget extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const TimePeriodSelectorWidget({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periods = ['اليوم', 'الأسبوع', 'الشهر', 'السنة'];

    return Container(
      height: 7.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period;

          return Expanded(
            child: GestureDetector(
              onTap: () => onPeriodChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4F46E5),
                            const Color(0xFF7C3AED),
                          ],
                        )
                      : null,
                  color: !isSelected ? Colors.transparent : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                  border: !isSelected
                      ? Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        period,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(height: 0.3.h),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
