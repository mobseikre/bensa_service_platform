import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Cost breakdown section showing service fees
class CostBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic> costData;

  const CostBreakdownWidget({
    super.key,
    required this.costData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceFee = (costData['service_fee'] as num?)?.toDouble() ?? 0.0;
    final prioritySurcharge =
        (costData['priority_surcharge'] as num?)?.toDouble() ?? 0.0;
    final total = serviceFee + prioritySurcharge;

    return Container(
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
          Text(
            'تفاصيل التكلفة',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCostRow(
            context,
            'رسوم الخدمة',
            serviceFee,
            theme,
          ),
          if (prioritySurcharge > 0) ...[
            SizedBox(height: 1.h),
            _buildCostRow(
              context,
              'رسوم الأولوية',
              prioritySurcharge,
              theme,
            ),
          ],
          Divider(height: 3.h),
          _buildCostRow(
            context,
            'الإجمالي',
            total,
            theme,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(
    BuildContext context,
    String label,
    double amount,
    ThemeData theme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        Text(
          '${amount.toStringAsFixed(2)} د.ل',
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
        ),
      ],
    );
  }
}
