import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';

/// Technician profile card with contact information
class TechnicianProfileCardWidget extends StatelessWidget {
  final Map<String, dynamic>? technicianData;

  const TechnicianProfileCardWidget({
    super.key,
    this.technicianData,
  });

  @override
  Widget build(BuildContext context) {
    if (technicianData == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final rating = (technicianData!['rating'] as num?)?.toDouble() ?? 0.0;

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
            'الفني المعين',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: technicianData!['photo'] as String? ??
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(technicianData!['name'] as String? ?? 'فني')}&background=2563EB&color=fff',
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.cover,
                    semanticLabel:
                        technicianData!['photoSemanticLabel'] as String? ??
                            'صورة شخصية للفني',
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technicianData!['name'] as String? ?? 'فني',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return CustomIconWidget(
                            iconName:
                                index < rating.floor() ? 'star' : 'star_border',
                            color: const Color(0xFFF59E0B),
                            size: 16,
                          );
                        }),
                        SizedBox(width: 1.w),
                        Text(
                          rating.toStringAsFixed(1),
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
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () =>
                      _callTechnician(technicianData!['phone'] as String?),
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          if (technicianData!['phone'] != null) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'phone',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  technicianData!['phone'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _callTechnician(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
