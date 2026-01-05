import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Permission explanation widget
/// Shows Arabic headline and description based on user role
class PermissionExplanationWidget extends StatelessWidget {
  final String userRole;
  final bool permissionDenied;

  const PermissionExplanationWidget({
    super.key,
    required this.userRole,
    required this.permissionDenied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Headline
        Text(
          permissionDenied
              ? 'نحتاج إلى إذن الموقع'
              : 'السماح بالوصول إلى موقعك',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 2.h),

        // Description
        Text(
          _getDescriptionText(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        if (permissionDenied) ...[
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _getDeniedText(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getDescriptionText() {
    if (permissionDenied) {
      return userRole == 'technician'
          ? 'إذن الموقع ضروري لاستقبال طلبات العمل القريبة منك وزيادة فرص الحصول على وظائف'
          : 'إذن الموقع يساعدنا في إيجاد أقرب الفنيين المتاحين لك وتقديم خدمة أسرع';
    }

    return userRole == 'technician'
        ? 'نحتاج إلى موقعك دائماً لإرسال إشعارات بطلبات العمل القريبة منك. سيتم تحديث موقعك كل 30 ثانية عند تفعيل حالة "متاح"'
        : 'نحتاج إلى موقعك عند استخدام التطبيق لإيجاد أقرب الفنيين المتاحين وتقديم خدمة أفضل لك';
  }

  String _getDeniedText() {
    return userRole == 'technician'
        ? 'بدون إذن الموقع، لن تتمكن من استقبال طلبات العمل وستفقد فرص الربح'
        : 'بدون إذن الموقع، قد لا تتمكن من استخدام بعض الميزات مثل إيجاد الفنيين القريبين';
  }
}
