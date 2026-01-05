import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_export.dart';

/// Customer information card widget displaying profile, rating, and contact options
class CustomerInfoCardWidget extends StatefulWidget {
  final Map<String, dynamic> customerData;

  const CustomerInfoCardWidget({
    super.key,
    required this.customerData,
  });

  @override
  State<CustomerInfoCardWidget> createState() => _CustomerInfoCardWidgetState();
}

class _CustomerInfoCardWidgetState extends State<CustomerInfoCardWidget> {
  bool _isPhoneVisible = false;

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  String _getMaskedPhone(String phone) {
    if (phone.isEmpty || phone == 'غير متوفر') return phone;

    // Default masking: show first 5 characters and replace rest with *
    if (phone.length > 5) {
      return "${phone.substring(0, 5)}********";
    }
    return "********";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = widget.customerData['phone'] as String? ?? 'غير متوفر';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
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
                'معلومات العميل',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: CustomImageWidget(
                        imageUrl:
                            widget.customerData['profileImage'] as String? ??
                                '',
                        width: 15.w,
                        height: 15.w,
                        fit: BoxFit.cover,
                        semanticLabel:
                            widget.customerData['semanticLabel'] as String? ??
                                'صورة العميل الشخصية',
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customerData['name'] as String? ?? 'غير متوفر',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              color: const Color(0xFFF59E0B),
                              size: 16,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${widget.customerData['rating'] ?? 0.0} (${widget.customerData['reviewCount'] ?? 0} تقييم)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      _isPhoneVisible ? phone : _getMaskedPhone(phone),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        letterSpacing: _isPhoneVisible ? 0 : 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPhoneVisible = true;
                    });
                    _makePhoneCall(phone);
                  },
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                  label: Text(
                    'اتصل بالعميل',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
