import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/customer_info_card_widget.dart';
import './widgets/earnings_breakdown_widget.dart';
import './widgets/job_status_stepper_widget.dart';
import './widgets/location_card_widget.dart';
import './widgets/service_details_card_widget.dart';
import './widgets/status_update_section_widget.dart';

/// Job Details Screen - Comprehensive job management with status updates
class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  String _currentStatus = 'assigned';
  int _jobDurationMinutes = 0;
  bool _isLoading = false;

  // Job data to be provided via route arguments or loaded from backend
  Map<String, dynamic>? _jobData;

  Timer? _jobTimer;

  @override
  void initState() {
    super.initState();
    _startJobTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Read job data from route arguments ONCE here, not in build()
    if (_jobData == null) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic> && args.isNotEmpty) {
          _jobData = args;
          // Sync current status from backend data if available
          final status = _jobData!['status'] as String?;
          if (status != null && status.isNotEmpty) {
            setState(() {
              _currentStatus = status;
            });
          }
        }
      } catch (e) {
        debugPrint('Error reading job data: $e');
      }
    }
  }

  @override
  void dispose() {
    _jobTimer?.cancel();
    super.dispose();
  }

  void _startJobTimer() {
    _jobTimer?.cancel();
    _jobTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStatus != 'work_done' && _currentStatus != 'completed') {
        if (mounted) {
          setState(() => _jobDurationMinutes++);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _updateJobStatus(String newStatus) async {
    if (_jobData == null) return;

    setState(() => _isLoading = true);

    try {
      final jobId = _jobData!['id'];
      if (jobId == null) {
        throw Exception('Job ID not found');
      }

      // FIXED: Send real API call to backend
      debugPrint('=== UPDATING JOB STATUS ===');
      debugPrint('Job ID: $jobId');
      debugPrint('New Status: $newStatus');

      final apiService = ApiService();
      final response = await apiService.updateRequestStatus(
        requestId: jobId,
        status: newStatus,
      );

      if (mounted) {
        debugPrint('=== API RESPONSE RECEIVED ===');
        debugPrint('Response: $response');
        debugPrint('Response type: ${response.runtimeType}');

        // Handle different response formats from backend
        bool isSuccess = false;
        String message = 'تم تحديث حالة الطلب بنجاح';

        // Check various success indicators
        isSuccess = response['success'] == true ||
                   response.containsKey('data') ||
                   (!response.containsKey('error') && !response.containsKey('errors'));

        if (response['message'] != null) {
          message = response['message'].toString();
        }

        if (isSuccess) {
          setState(() {
            _currentStatus = newStatus;
            _isLoading = false;
          });

          HapticFeedback.mediumImpact();
          Fluttertoast.showToast(
            msg: message,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFF10B981),
            textColor: Colors.white,
          );

          debugPrint('Status updated successfully in backend');

          // Navigate to earnings screen if work is done
          if (newStatus == 'work_done') {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/earnings-screen');
              }
            });
          }
        } else {
          // Handle API failure
          setState(() => _isLoading = false);

          final errorMessage = response['message'] ?? response['error'] ?? 'خطأ غير معروف';

          Fluttertoast.showToast(
            msg: 'فشل تحديث الحالة: $errorMessage',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: const Color(0xFFEF4444),
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('=== ERROR UPDATING JOB STATUS ===');
      debugPrint('Error: $e');

      if (mounted) {
        setState(() => _isLoading = false);

        Fluttertoast.showToast(
          msg: 'فشل تحديث الحالة: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          textColor: Colors.white,
        );
      }
    }
  }

  /// Format location data from backend response to match LocationCardWidget expectations
  Map<String, dynamic> _formatLocationData(Map<String, dynamic> jobData) {
    // Try to get location from nested 'location' key first
    final location = jobData['location'] as Map<String, dynamic>?;

    if (location != null) {
      return {
        'address':
            location['address'] ?? jobData['address'] ?? 'العنوان غير متوفر',
        'latitude': location['latitude'] ??
            location['location_lat'] ??
            location['lat'] ??
            jobData['location_lat'] ??
            jobData['latitude'] ??
            0.0,
        'longitude': location['longitude'] ??
            location['location_lng'] ??
            location['lng'] ??
            jobData['location_lng'] ??
            jobData['longitude'] ??
            0.0,
        'distance': location['distance'] ?? jobData['distance'] ?? 0.0,
      };
    }

    // Fallback: get location directly from jobData
    return {
      'address': jobData['address'] ?? 'العنوان غير متوفر',
      'latitude': jobData['location_lat'] ??
          jobData['latitude'] ??
          jobData['lat'] ??
          0.0,
      'longitude': jobData['location_lng'] ??
          jobData['longitude'] ??
          jobData['lng'] ??
          0.0,
      'distance': jobData['distance'] ?? 0.0,
    };
  }

  Future<void> _showEmergencyContact() async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'الاتصال بالدعم',
          style: theme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل تحتاج إلى مساعدة؟',
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Text(
              'رقم الدعم: +218912345678',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger phone call
            },
            child: Text(
              'اتصل الآن',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Check if we have job data (loaded in didChangeDependencies)
    if (_jobData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'تفاصيل الطلب',
          style: CustomAppBarStyle.standard,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                'بيانات الطلب غير متوفرة',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'يرجى المحاولة مرة أخرى',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    final hasJob = _jobData != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'تفاصيل الطلب',
        style: CustomAppBarStyle.standard,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'support_agent',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: _showEmergencyContact,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : !hasJob
              ? Center(
                  child: Text(
                    'لا توجد بيانات متاحة لهذا الطلب.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job ID and Timer
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'work',
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  (_jobData!['jobId'] ?? _jobData!['id'] ?? '')
                                      .toString(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'timer',
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '$_jobDurationMinutes دقيقة',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),

                      // Status Stepper
                      JobStatusStepperWidget(currentStatus: _currentStatus),
                      SizedBox(height: 2.h),

                      // Customer Info
                      CustomerInfoCardWidget(
                        customerData:
                            (_jobData!['customer'] as Map<String, dynamic>?) ??
                                <String, dynamic>{},
                      ),
                      SizedBox(height: 2.h),

                      // Service Details
                      ServiceDetailsCardWidget(
                        serviceData:
                            (_jobData!['service'] as Map<String, dynamic>?) ??
                                <String, dynamic>{},
                      ),
                      SizedBox(height: 2.h),

                      // Location - Format location data from backend
                      LocationCardWidget(
                        locationData: _formatLocationData(_jobData!),
                      ),
                      SizedBox(height: 2.h),

                      // Status Update
                      StatusUpdateSectionWidget(
                        currentStatus: _currentStatus,
                        onStatusUpdate: _updateJobStatus,
                      ),
                      SizedBox(height: 2.h),

                      // Earnings Breakdown
                      EarningsBreakdownWidget(
                        earningsData:
                            (_jobData!['earnings'] as Map<String, dynamic>?) ??
                                <String, dynamic>{},
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
    );
  }
}
