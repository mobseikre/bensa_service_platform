import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Terms and conditions checkbox widget
class TermsCheckboxWidget extends StatelessWidget {
  final bool isAccepted;
  final ValueChanged<bool?> onChanged;

  const TermsCheckboxWidget({
    super.key,
    required this.isAccepted,
    required this.onChanged,
  });

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 70.h,
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الشروط والأحكام',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _getTermsText(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTermsText() {
    return '''
شروط وأحكام استخدام منصة بنسة للخدمات

1. القبول بالشروط
باستخدامك لمنصة بنسة، فإنك توافق على الالتزام بهذه الشروط والأحكام.

2. الخدمات المقدمة
توفر منصة بنسة خدمات ربط العملاء بالفنيين المتخصصين في مجالات الصيانة المختلفة.

3. التسجيل والحساب
- يجب تقديم معلومات صحيحة ودقيقة عند التسجيل
- أنت مسؤول عن الحفاظ على سرية حسابك
- يجب أن تكون فوق 18 عامًا للتسجيل

4. مسؤوليات المستخدم
- استخدام المنصة بطريقة قانونية ومسؤولة
- عدم إساءة استخدام الخدمات أو التلاعب بالنظام
- احترام الفنيين والعملاء الآخرين

5. الدفع والرسوم
- يتم الدفع مباشرة للفني بعد إتمام الخدمة
- تحتفظ المنصة بنسبة عمولة من كل خدمة

6. الإلغاء والاسترداد
- يمكن إلغاء الطلب قبل قبول الفني له
- سياسة الاسترداد تخضع لتقييم كل حالة على حدة

7. الخصوصية وحماية البيانات
- نحن نحترم خصوصيتك ونحمي بياناتك الشخصية
- راجع سياسة الخصوصية للمزيد من التفاصيل

8. التعديلات على الشروط
نحتفظ بالحق في تعديل هذه الشروط في أي وقت.

9. إنهاء الحساب
يمكننا إنهاء أو تعليق حسابك في حالة انتهاك الشروط.

10. القانون الساري
تخضع هذه الشروط للقوانين المعمول بها في ليبيا.

للاستفسارات: support@bensa.ly
''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: isAccepted,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'أوافق على '),
                TextSpan(
                  text: 'الشروط والأحكام',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showTermsDialog(context),
                ),
                const TextSpan(text: ' الخاصة بالمنصة'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
