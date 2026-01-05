import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Priority level selector with color-coded badges
class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final ValueChanged<String> onChanged;

  const PrioritySelector({
    super.key,
    required this.selectedPriority,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Backend supports two priority types: normal, urgent
    final priorities = [
      {
        'value': 'normal',
        'label': 'عادي',
        'description': 'خلال 24 ساعة',
        'color': theme.colorScheme.tertiary,
        'icon': 'schedule',
      },
      {
        'value': 'urgent',
        'label': 'عاجل',
        'description': 'خلال 6 ساعات',
        'color': theme.colorScheme.secondary,
        'icon': 'access_time',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأولوية *',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: (priorities).map((priority) {
            final isSelected = selectedPriority == priority['value'];
            final color = priority['color'] as Color;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onChanged(priority['value'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected ? color : theme.colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: priority['icon'] as String,
                          color: isSelected
                              ? color
                              : theme.colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priority['label'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priority['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
