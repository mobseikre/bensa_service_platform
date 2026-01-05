import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Permission illustration widget
/// Shows location pin with service icons around it
class PermissionIllustrationWidget extends StatelessWidget {
  const PermissionIllustrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 80.w,
      height: 30.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),

          // Center location pin
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CustomIconWidget(
              iconName: 'location_on',
              color: theme.colorScheme.onPrimary,
              size: 48,
            ),
          ),

          // Service icons around the center
          ..._buildServiceIcons(theme),
        ],
      ),
    );
  }

  /// Build service icons positioned around the center
  List<Widget> _buildServiceIcons(ThemeData theme) {
    final icons = [
      {'icon': 'plumbing', 'angle': 0.0},
      {'icon': 'electrical_services', 'angle': 1.57},
      {'icon': 'carpenter', 'angle': 3.14},
      {'icon': 'cleaning_services', 'angle': 4.71},
    ];

    return icons.map((iconData) {
      final angle = iconData['angle'] as double;
      final iconName = iconData['icon'] as String;

      return Positioned(
        left: 40.w +
            (25.w *
                (angle == 0.0 || angle == 3.14 ? (angle == 0.0 ? 1 : -1) : 0)),
        top: 15.h +
            (12.5.w *
                (angle == 1.57 || angle == 4.71
                    ? (angle == 1.57 ? 1 : -1)
                    : 0)),
        child: Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
      );
    }).toList();
  }
}
