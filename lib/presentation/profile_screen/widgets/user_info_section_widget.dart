import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// User information section with editable fields
class UserInfoSectionWidget extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String role;
  final VoidCallback onEditName;
  final VoidCallback onEditEmail;
  final VoidCallback onEditPhone;

  const UserInfoSectionWidget({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.onEditName,
    required this.onEditEmail,
    required this.onEditPhone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
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
          _buildInfoRow(
            context,
            icon: 'person',
            label: 'الاسم',
            value: name,
            onEdit: onEditName,
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            context,
            icon: 'email',
            label: 'البريد الإلكتروني',
            value: email,
            onEdit: null, // Read-only
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            context,
            icon: 'phone',
            label: 'رقم الهاتف',
            value: phone,
            onEdit: null, // Read-only
          ),
          SizedBox(height: 2.h),
          _buildRoleBadge(context, role),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: icon,
              size: 5.w,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: CustomIconWidget(
              iconName: 'edit',
              size: 5.w,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final theme = Theme.of(context);
    final isCustomer = role == 'customer';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: isCustomer
            ? theme.colorScheme.tertiary.withValues(alpha: 0.1)
            : theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: isCustomer ? 'person' : 'build',
            size: 4.w,
            color: isCustomer
                ? theme.colorScheme.tertiary
                : theme.colorScheme.secondary,
          ),
          SizedBox(width: 2.w),
          Text(
            isCustomer ? 'عميل' : 'فني',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isCustomer
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
