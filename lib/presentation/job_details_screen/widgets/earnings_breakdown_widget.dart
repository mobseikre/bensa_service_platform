import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Earnings breakdown widget displaying job payment details
class EarningsBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic> earningsData;

  const EarningsBreakdownWidget({
    super.key,
    required this.earningsData,
  });

  /// Safely parse a value to double, handling both String and num types
  double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseFee = _parseDouble(earningsData['baseFee']);
    final priorityBonus = _parseDouble(earningsData['priorityBonus']);
    final distanceCompensation =
        _parseDouble(earningsData['distanceCompensation']);
    final completionBonus = _parseDouble(earningsData['completionBonus']);
    final total =
        baseFee + priorityBonus + distanceCompensation + completionBonus;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
              CustomIconWidget(
                iconName: 'account_balance_wallet',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'تفاصيل الأرباح',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildEarningRow(
            context,
            'الرسوم الأساسية',
            baseFee,
          ),
          if (priorityBonus > 0) ...[
            SizedBox(height: 1.h),
            _buildEarningRow(
              context,
              'مكافأة الأولوية',
              priorityBonus,
              isBonus: true,
            ),
          ],
          if (distanceCompensation > 0) ...[
            SizedBox(height: 1.h),
            _buildEarningRow(
              context,
              'تعويض المسافة',
              distanceCompensation,
              isBonus: true,
            ),
          ],
          if (completionBonus > 0) ...[
            SizedBox(height: 1.h),
            _buildEarningRow(
              context,
              'مكافأة الإنجاز',
              completionBonus,
              isBonus: true,
            ),
          ],
          SizedBox(height: 1.5.h),
          Divider(color: theme.colorScheme.outline),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الإجمالي المتوقع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} د.ل',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningRow(
    BuildContext context,
    String label,
    double amount, {
    bool isBonus = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${isBonus ? '+' : ''}${amount.toStringAsFixed(2)} د.ل',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isBonus ? const Color(0xFF10B981) : null,
          ),
        ),
      ],
    );
  }
}
