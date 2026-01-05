import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Service categories selector widget for technician registration
class ServiceCategoriesSelector extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onCategoriesChanged;

  const ServiceCategoriesSelector({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  // Service categories from backend
  static const List<Map<String, String>> serviceCategories = [
    {'icon': 'plumbing', 'name_ar': 'سباكة', 'name_en': 'plumbing'},
    {'icon': 'satellite', 'name_ar': 'تركيب ستالايت', 'name_en': 'satellite'},
    {'icon': 'electrical_services', 'name_ar': 'خدمات كهربائية', 'name_en': 'electrical'},
    {'icon': 'chair', 'name_ar': 'تركيب أثاث', 'name_en': 'furniture'},
    {'icon': 'router', 'name_ar': 'الشبكات والكاميرات', 'name_en': 'networking'},
    {'icon': 'format_paint', 'name_ar': 'الطلاء والجبس', 'name_en': 'painting'},
    {'icon': 'ac_unit', 'name_ar': 'تكييف وتبريد', 'name_en': 'ac'},
    {'icon': 'more_horiz', 'name_ar': 'خدمات أخرى', 'name_en': 'other'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'اختر الخدمات التي تقدمها',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 2.h,
          children: serviceCategories.map((category) {
            final categoryIcon = category['icon']!;
            final categoryNameAr = category['name_ar']!;
            final categoryNameEn = category['name_en']!;
            final isSelected = selectedCategories.contains(categoryNameEn);

            return GestureDetector(
              onTap: () {
                final newSelection = List<String>.from(selectedCategories);
                if (isSelected) {
                  newSelection.remove(categoryNameEn);
                } else {
                  newSelection.add(categoryNameEn);
                }
                onCategoriesChanged(newSelection);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: theme.colorScheme.primary,
                      )
                    else
                      CustomIconWidget(
                        iconName: categoryIcon,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    SizedBox(width: 2.w),
                    Text(
                      categoryNameAr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selectedCategories.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Text(
              'يجب اختيار خدمة واحدة على الأقل',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
