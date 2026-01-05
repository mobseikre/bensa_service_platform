import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Custody payment history section tracking commission payments to platform
class CustodyPaymentHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> custodyPayments;

  const CustodyPaymentHistoryWidget({
    super.key,
    required this.custodyPayments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
            child: Text(
              'سجل مدفوعات العهدة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          custodyPayments.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: custodyPayments.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final payment = custodyPayments[index];
                    return _buildCustodyPaymentItem(context, payment);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCustodyPaymentItem(
    BuildContext context,
    Map<String, dynamic> payment,
  ) {
    final theme = Theme.of(context);
    final status = payment['status'] as String;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${payment['amount']} د.ل',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'calendar_today',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      payment['date'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getStatusText(status),
              style: theme.textTheme.labelMedium?.copyWith(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4F46E5).withValues(alpha: 0.1),
                  const Color(0xFF7C3AED).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: CustomIconWidget(
              iconName: 'receipt_long',
              color: const Color(0xFF4F46E5).withValues(alpha: 0.7),
              size: 48,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'لا توجد مدفوعات عهدة بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'ستظهر هنا سجل دفعاتك للعهدة المستحقة للمنصة',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF10B981);
      case 'failed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return 'schedule';
      case 'processing':
        return 'sync';
      case 'completed':
        return 'check_circle';
      case 'failed':
        return 'error';
      default:
        return 'help';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'completed':
        return 'مكتمل';
      case 'failed':
        return 'فشل';
      default:
        return 'غير معروف';
    }
  }
}
