import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Profile header widget with large profile photo
class ProfileHeaderWidget extends StatelessWidget {
  final String? profileImageUrl;

  const ProfileHeaderWidget({
    super.key,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? CustomImageWidget(
                      imageUrl: profileImageUrl!,
                      width: 30.w,
                      height: 30.w,
                      fit: BoxFit.cover,
                      semanticLabel: "صورة الملف الشخصي للمستخدم",
                    )
                  : Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'person',
                          size: 15.w,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
