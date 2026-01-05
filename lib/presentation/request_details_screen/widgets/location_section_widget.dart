import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';

/// Location section with address and map navigation
class LocationSectionWidget extends StatelessWidget {
  final Map<String, dynamic> locationData;

  const LocationSectionWidget({
    super.key,
    required this.locationData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawLat = locationData['latitude'];
    final rawLng = locationData['longitude'];

    final double? latitude = rawLat is num
        ? rawLat.toDouble()
        : (rawLat is String ? double.tryParse(rawLat) : null);
    final double? longitude = rawLng is num
        ? rawLng.toDouble()
        : (rawLng is String ? double.tryParse(rawLng) : null);

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
          Row(
            children: [
              CustomIconWidget(
                iconName: 'location_on',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'الموقع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            locationData['address'] as String? ?? 'لا يوجد عنوان',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (latitude != null && longitude != null) ...[
            SizedBox(height: 2.h),
            Container(
              height: 20.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImageWidget(
                  imageUrl:
                      'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=15&size=600x400&markers=color:red%7C$latitude,$longitude&key=YOUR_API_KEY',
                  width: double.infinity,
                  height: 20.h,
                  fit: BoxFit.cover,
                  semanticLabel: 'خريطة توضح موقع الخدمة المطلوبة',
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(latitude, longitude),
                icon: CustomIconWidget(
                  iconName: 'map',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text('فتح في الخرائط'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openInMaps(double latitude, double longitude) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
