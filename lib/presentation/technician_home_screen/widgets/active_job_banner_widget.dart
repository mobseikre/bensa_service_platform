import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displaying active job banner with customer info and navigation
class ActiveJobBannerWidget extends StatefulWidget {
  final Map<String, dynamic> activeJob;
  final VoidCallback onViewDetails;

  const ActiveJobBannerWidget({
    super.key,
    required this.activeJob,
    required this.onViewDetails,
  });

  @override
  State<ActiveJobBannerWidget> createState() => _ActiveJobBannerWidgetState();
}

class _ActiveJobBannerWidgetState extends State<ActiveJobBannerWidget> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerName = widget.activeJob['customerName'] as String? ?? 'عميل';
    final customerPhone = widget.activeJob['customerPhone'] as String? ?? '';
    final status = widget.activeJob['status'] as String? ?? 'assigned';
    final address = widget.activeJob['address'] as String? ?? 'لا يوجد عنوان';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B),
            const Color(0xFFF59E0B).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'work',
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لديك وظيفة نشطة',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getStatusText(status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'person',
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        customerName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (customerPhone.isNotEmpty)
                      InkWell(
                        onTap: () => _makePhoneCall(customerPhone),
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CustomIconWidget(
                            iconName: 'phone',
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'location_on',
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        address,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                // Add distance and ETA display
                Row(
                  children: [
                    // Distance display
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'straighten',
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _formatDistance(widget.activeJob['distance']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // ETA display
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'access_time',
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _calculateETA(widget.activeJob['distance']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          // Single details button (removed navigation button)
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton.icon(
              onPressed: widget.onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: CustomIconWidget(
                iconName: 'visibility',
                color: const Color(0xFFF59E0B),
                size: 20,
              ),
              label: Text(
                'عرض التفاصيل',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'assigned':
        return 'تم التعيين';
      case 'on_the_way':
        return 'في الطريق';
      case 'arrived':
        return 'وصلت';
      case 'started':
        return 'بدأ العمل';
      case 'work_done':
        return 'العمل منتهي';
      default:
        return 'نشط';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }


  /// Format distance for proper display
  String _formatDistance(dynamic distance) {
    if (distance == null) return '0.0 كم';

    double distanceValue = 0.0;
    if (distance is num) {
      distanceValue = distance.toDouble();
    } else if (distance is String) {
      distanceValue = double.tryParse(distance) ?? 0.0;
    }

    // Format to 1 decimal place maximum
    if (distanceValue < 1.0) {
      return '${(distanceValue * 1000).round()} م'; // Show in meters if less than 1 km
    } else {
      return '${distanceValue.toStringAsFixed(1)} كم';
    }
  }

  /// Calculate estimated time of arrival based on distance
  String _calculateETA(dynamic distance) {
    if (distance == null) return '0 دقيقة';

    double distanceValue = 0.0;
    if (distance is num) {
      distanceValue = distance.toDouble();
    } else if (distance is String) {
      distanceValue = double.tryParse(distance) ?? 0.0;
    }

    // Calculate ETA assuming average speed of 40 km/h in city
    const averageSpeed = 40.0; // km/h
    final timeInHours = distanceValue / averageSpeed;
    final timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes == 0) {
      return 'أقل من دقيقة';
    } else if (timeInMinutes < 60) {
      return '$timeInMinutes دقيقة';
    } else {
      final hours = timeInMinutes ~/ 60;
      final minutes = timeInMinutes % 60;
      if (minutes == 0) {
        return '$hours ساعة';
      } else {
        return '$hours س $minutes د';
      }
    }
  }
}
