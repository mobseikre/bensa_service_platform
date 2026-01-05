import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Status filter widget with segment control
class StatusFilterWidget extends StatelessWidget {
  final String selectedStatus;
  final Map<String, int> statusCounts;
  final ValueChanged<String> onStatusChanged;

  const StatusFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.statusCounts,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              context,
              'all',
              'الكل',
              statusCounts['all'] ?? 0,
              theme,
            ),
            SizedBox(width: 2.w),
            _buildFilterChip(
              context,
              'active',
              'نشط',
              statusCounts['active'] ?? 0,
              theme,
            ),
            SizedBox(width: 2.w),
            _buildFilterChip(
              context,
              'completed',
              'مكتمل',
              statusCounts['completed'] ?? 0,
              theme,
            ),
            SizedBox(width: 2.w),
            _buildFilterChip(
              context,
              'cancelled',
              'ملغي',
              statusCounts['cancelled'] ?? 0,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String status,
    String label,
    int count,
    ThemeData theme,
  ) {
    final isSelected = selectedStatus == status;

    return Material(
      color: isSelected
          ? theme.colorScheme.primary
          : theme.brightness == Brightness.light
              ? const Color(0xFFF9FAFB)
              : const Color(0xFF374151),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onStatusChanged(status),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color:
                      isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              SizedBox(width: 1.5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        isSelected ? Colors.white : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
