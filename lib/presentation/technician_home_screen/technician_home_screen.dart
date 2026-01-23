import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/active_job_banner_widget.dart';
import './widgets/availability_toggle_widget.dart';
import './widgets/earnings_card_widget.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _currentBottomIndex = 0;
  bool _isAvailable = false;
  bool _isTogglingAvailability = false;
  bool _isLoadingJobs = false;
  bool _isRefreshing = false;
  int _availableJobsCount = 0;
  Timer? _locationUpdateTimer;
  Timer? _jobRefreshTimer;
  final ApiService _apiService = ApiService();

  // Stats data loaded from API
  final Map<String, dynamic> _statsData = {
    'completedJobs': 0,
    'averageRating': 0.0,
    'total_ratings':
        0, // FIXED: Match backend field name if needed, but we map below
    'pendingCustody': 0.0,
    'pendingCustodyCount': 0,
  };

  Map<String, dynamic>? _activeJob;
  bool _hasShownBlockWarning = false;
  int _unreadNotificationsCount = 0;

  // Current technician location for distance calculation
  Position? _currentTechnicianPosition;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // AUTOMATIC LOCATION: Start location updates immediately for technicians
    // No need for separate location settings - location always on
    _startLocationUpdates();
    debugPrint('=== TECHNICIAN LOCATION AUTO-ENABLED ===');

    // Safety mechanism: Force loading to false after 30 seconds
    Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoadingJobs) {
        debugPrint('=== SAFETY: FORCING LOADING TO FALSE ===');
        setState(() => _isLoadingJobs = false);
      }
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _jobRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    debugPrint('=== STARTING INITIAL DATA LOAD ===');
    if (mounted) {
      setState(() => _isLoadingJobs = true);
    }

    try {
      debugPrint('Loading technician stats...');
      await _loadStats().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Stats loading timeout'),
      );
      debugPrint('Stats loaded successfully');

      // Removed: Force Offline on Startup
      // We want to RESPECT the state from the server or active job status.

      debugPrint('Loading active job...');
      await _loadActiveJob().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Active job loading timeout'),
      );
      debugPrint('Active job loaded successfully');

      // Load unread notifications count
      try {
        final notificationsResponse =
            await _apiService.getNotifications(page: 1);
        if (mounted) {
          setState(() {
            _unreadNotificationsCount =
                notificationsResponse['unread_count'] ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Error loading notifications count: $e');
      }

      debugPrint('=== INITIAL DATA LOAD COMPLETED ===');
    } catch (e) {
      debugPrint('=== ERROR IN INITIAL DATA LOAD ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل البيانات: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      debugPrint('=== SETTING LOADING TO FALSE ===');
      if (mounted) {
        setState(() {
          _isLoadingJobs = false;
        });
        debugPrint('Loading state updated to false');
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final response = await _apiService.getTechnicianStats();

      if (mounted) {
        setState(() {
          // Map backend response to frontend format
          _statsData['completedJobs'] = response['completed_jobs'] ?? 0;
          _statsData['averageRating'] =
              (response['average_rating'] ?? 0.0).toDouble();
          _statsData['totalRatings'] = response['total_ratings'] ?? 0;
          _availableJobsCount = response['available_jobs_count'] ?? 0;
          _statsData['pendingCustody'] =
              (response['pending_custody']?['amount'] ?? 0.0).toDouble();
          _statsData['pendingCustodyCount'] =
              response['pending_custody']?['count'] ?? 0;
          _statsData['isBlocked'] = response['is_blocked'] ?? false;
          _statsData['workWindow'] = response['work_window'];
          _statsData['pending_settlement'] = response['pending_custody'];

          // Immediate Warning if Blocked
          if (_statsData['isBlocked'] == true && !_hasShownBlockWarning) {
            _hasShownBlockWarning = true;
            _showBlockWarning(_statsData['pending_settlement']);
          }

          // Sync availability with backend
          final backendAvailability = response['is_available'];
          final isBlocked = response['is_blocked'] ?? false;
          _isAvailable =
              (backendAvailability == 1 || backendAvailability == true);

          // LOGIC: Sync availability with backend but enforce blocks
          if (isBlocked && _isAvailable) {
            _isAvailable = false; // Force visual offline if blocked
          }

          // LOGIC: Sync availability with backend.
          // If there's pending custody, the backend will return is_available: false,
          // and we MUST respect that to block the technician.
          debugPrint('=== AVAILABILITY SYNC ===');
          debugPrint('Backend availability value: $backendAvailability');
          debugPrint('Parsed availability: $_isAvailable');
          debugPrint('Is Blocked: ${_statsData['isBlocked']}');
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      // Keep default values on error
    }
  }

  Future<void> _loadActiveJob() async {
    try {
      final response = await _apiService.getCurrentJob();

      if (mounted) {
        if (response['current_job'] != null) {
          final jobData =
              Map<String, dynamic>.from(response['current_job'] as Map);

          // Ensure all required fields are present for JobDetailsScreen
          jobData['customerName'] = jobData['customer']?['name'] ?? 'عميل';
          jobData['customerPhone'] = jobData['customer']?['phone'] ?? '';
          jobData['customerEmail'] = jobData['customer']?['email'] ?? '';

          // Ensure location fields are properly formatted
          jobData['latitude'] = jobData['location_lat'] ?? 0.0;
          jobData['longitude'] = jobData['location_lng'] ?? 0.0;
          jobData['address'] = jobData['address'] ?? 'العنوان غير متوفر';

          // Add service data if missing
          if (!jobData.containsKey('service')) {
            jobData['service'] = {
              'category': jobData['category'] ?? 'خدمة',
              'description': jobData['description'] ?? '',
              'priority': jobData['priority'] ?? 'normal',
              'estimated_duration': jobData['estimated_duration'] ?? 60,
            };
          }

          setState(() {
            _activeJob = jobData;
            // FORCE ONLINE VISUALLY IF ACTIVE JOB EXISTS
            // This ensures that even if backend state is lagging, the UI shows the technician as busy/online
            // preventing them from seeing "Offline" while working.
            if (_activeJob != null) {
              _isAvailable = true;
            }
          });

          debugPrint('=== ACTIVE JOB LOADED ===');
          debugPrint('Job ID: ${_activeJob?['id']}');
          debugPrint('Customer: ${_activeJob?['customerName']}');
          debugPrint(
              'Location: ${_activeJob?['latitude']}, ${_activeJob?['longitude']}');
          debugPrint('Distance: ${_activeJob?['distance']} km');
        } else {
          setState(() {
            _activeJob = null;
          });
          debugPrint('No current active job found');
        }
      }
    } catch (e) {
      debugPrint('Error loading current job: $e');
      if (mounted) {
        setState(() {
          _activeJob = null;
        });
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Prevent turning off if there is an active job
    if (!value && _activeJob != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لديك طلب نشط، لا يمكنك إغلاق حالة التوفر.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Ensure UI reflects the forced ON state
      setState(() => _isAvailable = true);
      return;
    }

    setState(() => _isTogglingAvailability = true);

    try {
      // FIXED: Use real Backend API instead of simulation
      debugPrint('=== UPDATING AVAILABILITY IN BACKEND ===');
      debugPrint('Setting availability to: $value');

      await _apiService.toggleTechnicianAvailability(
        isAvailable: value,
        currentLat: _currentTechnicianPosition?.latitude,
        currentLng: _currentTechnicianPosition?.longitude,
      );

      if (mounted) {
        setState(() {
          _isAvailable = value;
          _isTogglingAvailability = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'تم تفعيل التوفر بنجاح' : 'تم إيقاف التوفر بنجاح',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // Handle API error
      debugPrint('Error updating availability: $e');

      if (mounted) {
        setState(() {
          _isTogglingAvailability = false;
          // Revert to previous state on error
          _isAvailable = !value;
        });

        // Check if it's a block error (403)
        if (e.toString().contains('403') ||
            (e is ApiException && e.statusCode == 403)) {
          // If we tried to go ONLINE and failed due to block, show the warning
          if (value) {
            _showBlockWarning(_statsData['pending_settlement']);
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث حالة التوفر: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return; // Exit early on error
    }

    // Only execute this if API call succeeded
    if (mounted) {
      if (_isAvailable) {
        _startLocationUpdates();
        _startJobRefresh();
        // Load active job when becoming available
        await _loadActiveJob();
        debugPrint('=== AVAILABILITY ENABLED ===');
      } else {
        _stopLocationUpdates();
        _stopJobRefresh();
        // Clear active job when becoming unavailable
        if (mounted) {
          setState(() {
            _activeJob = null;
          });
        }
      }
    }
  }

  /// Start continuous location updates for technician
  /// Location is ALWAYS ON for technicians - no user settings needed
  void _startLocationUpdates() {
    debugPrint('=== STARTING CONTINUOUS LOCATION UPDATES ===');
    debugPrint(
        'Technician location will update every 30 seconds automatically');

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        await _updateTechnicianLocation();
      },
    );

    // Update location immediately when starting
    _updateTechnicianLocation();
  }

  /// Get current location and update backend
  Future<void> _updateTechnicianLocation() async {
    try {
      // Check permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied');
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));

      _currentTechnicianPosition = position;

      // Update backend with current location
      await _apiService.updateTechnicianLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      debugPrint('=== LOCATION UPDATED ===');
      debugPrint('Lat: ${position.latitude}, Lng: ${position.longitude}');
      debugPrint('Updated backend successfully');
    } catch (e) {
      debugPrint('Error updating location: $e');
      // Continue silently - don't show error to user for location updates
    }
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  void _startJobRefresh() {
    _jobRefreshTimer?.cancel();
    _jobRefreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) {
        if (!_isRefreshing) {
          _refreshJobs(silent: true);
        }
      },
    );
  }

  void _stopJobRefresh() {
    _jobRefreshTimer?.cancel();
  }

  Future<void> _refreshJobs({bool silent = false}) async {
    if (!silent) {
      setState(() => _isRefreshing = true);
    }

    try {
      // FIXED: Load stats first, then active job, then notifications
      await _loadStats();
      await _loadActiveJob();

      // Refresh unread notifications count
      try {
        final notificationsResponse =
            await _apiService.getNotifications(page: 1);
        if (mounted) {
          setState(() {
            _unreadNotificationsCount =
                notificationsResponse['unread_count'] ?? 0;
          });
        }
      } catch (e) {
        debugPrint('Error refreshing notifications count: $e');
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحديث البيانات: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _viewJobDetails([Map<String, dynamic>? job]) {
    if (job != null) {
      Navigator.pushNamed(
        context,
        '/job-details-screen',
        arguments: job,
      );
    } else {
      Navigator.pushNamed(context, '/job-details-screen');
    }
  }

  void _showCustomerSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مركز المساعدة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يمكنك التواصل مع الدعم الفني عبر الرقم التالي:'),
            const SizedBox(height: 16),
            Text(
              '0921111111',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF4F46E5),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final Uri launchUri = Uri(
                scheme: 'tel',
                path: '0921111111',
              );
              // ignore: deprecated_member_use
              if (await canLaunchUrl(launchUri)) {
                // ignore: deprecated_member_use
                await launchUrl(launchUri);
              }
            },
            icon: const Icon(Icons.phone),
            label: const Text('اتصال الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light gray background
      appBar: TechnicianAppBar(
        title: 'الرئيسية',
        notificationCount: _unreadNotificationsCount,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: _showCustomerSupportDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshJobs(silent: false),
        color: const Color(0xFF4F46E5),
        strokeWidth: 2.5,
        child: _isLoadingJobs
            ? Center(
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF4F46E5).withValues(alpha: 0.1),
                              const Color(0xFF7C3AED).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: CircularProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4F46E5),
                          ),
                          strokeWidth: 3.0,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'جاري تحميل البيانات...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Main content with enhanced spacing and design
                  SliverPadding(
                    padding: EdgeInsets.all(4.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Enhanced Availability Toggle with better spacing
                        Container(
                          margin: EdgeInsets.only(bottom: 3.h),
                          child: AvailabilityToggleWidget(
                            isAvailable: _isAvailable,
                            onToggle: _toggleAvailability,
                            isLoading: _isTogglingAvailability,
                          ),
                        ),

                        // Enhanced Stats Card with shadow and gradient
                        Container(
                          margin: EdgeInsets.only(bottom: 4.h),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.1),
                                offset: const Offset(0, 8),
                                blurRadius: 24,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: EarningsCardWidget(
                            completedJobs: _statsData['completedJobs'] as int,
                            averageRating:
                                _statsData['averageRating'] as double,
                            pendingCustody:
                                _statsData['pendingCustody'] as double,
                            pendingCustodyCount:
                                _statsData['pendingCustodyCount'] as int,
                            isBlocked:
                                _statsData['isBlocked'] as bool? ?? false,
                            workWindow: _statsData['workWindow']
                                as Map<String, dynamic>?,
                          ),
                        ),

                        // Enhanced Active Job Banner with improved design
                        if (_activeJob != null) ...[
                          Container(
                            margin: EdgeInsets.only(bottom: 4.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.2),
                                  offset: const Offset(0, 8),
                                  blurRadius: 24,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: ActiveJobBannerWidget(
                              activeJob: _activeJob!,
                              onViewDetails: () => _viewJobDetails(_activeJob!),
                            ),
                          ),
                        ] else ...[
                          // Beautiful empty state when no active job
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(8.w),
                            margin: EdgeInsets.only(bottom: 4.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  const Color(0xFFF8FAFC),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF64748B)
                                      .withValues(alpha: 0.05),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF6366F1)
                                            .withValues(alpha: 0.1),
                                        const Color(0xFF8B5CF6)
                                            .withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: CustomIconWidget(
                                    iconName: 'work_outline',
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.7),
                                    size: 48,
                                  ),
                                ),
                                SizedBox(height: 3.h),
                                Text(
                                  'لا يوجد طلب نشط حالياً',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  _isAvailable
                                      ? 'أنت متاح الآن وستتلقى الطلبات تلقائياً'
                                      : 'فعّل التوفر لتلقي طلبات الخدمة',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Add some bottom spacing
                        SizedBox(height: 4.h),
                      ]),
                    ),
                  ),

                  // Extra bottom spacing for floating elements
                  SliverToBoxAdapter(
                    child: SizedBox(height: 12.h),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: TechnicianBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() => _currentBottomIndex = index);

          // Handle technician-specific navigation
          if (index != _currentBottomIndex) {
            switch (index) {
              case 0:
                // Already on technician home, no action needed
                break;
              case 1:
                // Navigate to technician jobs
                Navigator.pushNamed(context, '/technician-jobs-screen');
                break;
              case 2:
                // Navigate to earnings
                Navigator.pushNamed(context, '/earnings-screen');
                break;
              case 3:
                // Navigate to profile with technician role
                Navigator.pushNamed(
                  context,
                  '/profile-screen',
                  arguments: {
                    'role': 'technician',
                    'userRole': 'technician',
                  },
                );
                break;
            }
          }
        },
        availableJobsCount: _availableJobsCount,
      ),
    );
  }

  void _showBlockWarning(Map<String, dynamic>? settlementData) {
    if (settlementData == null) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 28),
              SizedBox(width: 2.w),
              const Text('تنبيه: تسوية مطلوبة'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'يجب عليك تسوية المبالغ المستحقة للمنصة لتتمكن من استقبال طلبات جديدة.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildSettlementDetail('المبلغ المطلوب:',
                  '${settlementData['amount'] ?? 0} ${settlementData['currency'] ?? 'LYD'}'),
              _buildSettlementDetail('عدد الطلبات:',
                  '${settlementData['count'] ?? settlementData['orders_count'] ?? 0}'),
              if (settlementData['old_debt'] != null &&
                  (settlementData['old_debt'] as num) > 0)
                _buildSettlementDetail('ديون سابقة:',
                    '${settlementData['old_debt']} ${settlementData['currency'] ?? 'LYD'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('فهمت'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentBottomIndex =
                    2); // Switch to Earnings tab (index 2)
                Navigator.pushNamed(context, '/earnings-screen');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('التوجه للتسوية'),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSettlementDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
