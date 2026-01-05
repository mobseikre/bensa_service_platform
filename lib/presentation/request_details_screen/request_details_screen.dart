import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/location_section_widget.dart';
import './widgets/rating_section_widget.dart';
import './widgets/service_info_card_widget.dart';
import './widgets/status_progress_widget.dart';
import './widgets/status_illustration_widget.dart';
import './widgets/technician_profile_card_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Request Details Screen - Comprehensive request information with real-time status tracking
class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({super.key});

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _requestData;
  bool _isLoading = true;
  String? _errorMessage;
  int? _requestId;
  Timer? _refreshTimer;
  final ScrollController _scrollController = ScrollController();

  bool _hasLoadedData = false;
  bool _hasScrolledToRating = false;

  @override
  void initState() {
    super.initState();
    // Don't load data here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedData) {
      _hasLoadedData = true;
      _loadRequestData();
    }
  }

  Future<void> _loadRequestData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Get request data from navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments;

    // Handle arguments
    Map<String, dynamic>? argsMap;
    if (args != null) {
      if (args is Map<String, dynamic>) {
        argsMap = args;
      } else if (args is Map) {
        argsMap = Map<String, dynamic>.from(args);
      }
    }

    // If we have full request data, use it immediately
    if (argsMap != null && argsMap.containsKey('id') && argsMap['id'] != null) {
      try {
        final data = argsMap; // Use local variable for null safety
        final rawStatus = data['rawStatus'] as String?;
        final statusLabel = data['status'] as String?;
        final finalStatus = rawStatus ??
            (statusLabel != null &&
                    !statusLabel.contains('قيد') &&
                    !statusLabel.contains('تم')
                ? statusLabel
                : 'pending');

        DateTime? createdAt;
        if (data['createdAt'] is DateTime) {
          createdAt = data['createdAt'] as DateTime;
        } else if (data['createdAt'] != null) {
          createdAt = DateTime.tryParse(data['createdAt'].toString());
        }

        dynamic latValue = data['latitude'];
        dynamic lngValue = data['longitude'];
        double? latitude = latValue is num
            ? latValue.toDouble()
            : (latValue is String ? double.tryParse(latValue) : null);
        double? longitude = lngValue is num
            ? lngValue.toDouble()
            : (lngValue is String ? double.tryParse(lngValue) : null);

        if (mounted && _requestData == null) {
          setState(() {
            _requestData = {
              'id': data['id'],
              'status': finalStatus,
              'category': data['category'] ?? '',
              'sub_service': data['sub_service'],
              'description': data['description'] ?? '',
              'priority': data['priority'] ?? 'normal',
              'created_at': createdAt?.toIso8601String() ??
                  DateTime.now().toIso8601String(),
              'location': {
                'address': data['location'] ?? '',
                'latitude': latitude,
                'longitude': longitude,
              },
              'technician': data['technicianName'] != null
                  ? {
                      'name': data['technicianName'],
                      'phone': data['technicianPhone'],
                    }
                  : null,
            };
            _requestId = data['id'] is int
                ? data['id'] as int
                : int.tryParse(data['id'].toString());
            _isLoading = false;
          });
        } else {
          _requestId = data['id'] is int
              ? data['id'] as int
              : int.tryParse(data['id'].toString());
        }
      } catch (e) {
        // If processing fails, try to get ID for API call
        _requestId = argsMap['id'] is int
            ? argsMap['id'] as int
            : int.tryParse(argsMap['id']?.toString() ?? '');
      }
    } else if (argsMap != null) {
      // Try to get ID from other possible keys
      _requestId = argsMap['requestId'] is int
          ? argsMap['requestId'] as int
          : int.tryParse(argsMap['requestId']?.toString() ?? '');
    }

    // If no ID found, show error
    if (_requestId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'رقم الطلب غير موجود';
          _isLoading = false;
        });
      }
      return;
    }

    // Fetch request details from API
    if (kDebugMode) {
      print('Fetching request details from API, ID: $_requestId');
    }

    try {
      final response = await _apiService.getRequestDetails(_requestId!);

      if (kDebugMode) {
        print('=== REQUEST DETAILS API RESPONSE ===');
        print('Response: $response');
      }

      // Transform API response to match expected format
      Map<String, dynamic>? apiData;
      apiData = response;

      final data = apiData; // Non-null since we checked
      final technicianData = data['technician'];

      if (mounted) {
        setState(() {
          _requestData = {
            'id': data['id'],
            'status': data['status'] ?? 'pending',
            'category': data['category'] ?? '',
            'sub_service': data['sub_service'],
            'description': data['description'] ?? '',
            'priority': data['priority'] ?? 'normal',
            'created_at': data['created_at']?.toString() ??
                data['createdAt']?.toString() ??
                DateTime.now().toIso8601String(),
            'location': {
              'address': data['address'] ?? '',
              'latitude': data['location_lat'] ?? data['latitude'],
              'longitude': data['location_lng'] ?? data['longitude'],
            },
            'technician': technicianData != null && technicianData is Map
                ? {
                    'name': technicianData['name'] ?? '',
                    'phone': technicianData['phone'] ?? '',
                  }
                : null,
            // No cost data for customer - technician sets the price
            // We only take commission from technician
          };
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('=== REQUEST DETAILS ERROR ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
      }

      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل بيانات الطلب: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _startAutoRefresh();

      // NEW: Auto-scroll to rating if job finished
      final status = _requestData?['status'] as String?;
      if ((status == 'completed' || status == 'work_done') &&
          !_hasScrolledToRating) {
        _scrollToRating();
      }
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    if (!mounted) return;

    // Refresh every 30 seconds if status is not final
    final status = _requestData?['status'] as String?;
    if (status != 'completed' &&
        status != 'cancelled' &&
        status != 'work_done') {
      _refreshTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          _loadRequestData();
        } else if (mounted) {
          _startAutoRefresh(); // Reschedule if not current but still mounted
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRating() {
    if (!mounted || _hasScrolledToRating) return;

    // Wait a brief moment for the UI to settle after status update
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _scrollController.hasClients) {
        setState(() => _hasScrolledToRating = true);
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل الطلب',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null || _requestData == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'تفاصيل الطلب',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'error_outline',
                color: theme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                _errorMessage ?? 'حدث خطأ',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadRequestData,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final status = _requestData!['status'] as String;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: CircleAvatar(
            backgroundColor: theme.colorScheme.surface,
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Support Icon
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: CustomIconWidget(
                  iconName: 'support_agent',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: _contactSupport,
              ),
            ),
          ),
          if (status == 'pending' || status == 'assigned')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: IconButton(
                  icon: CustomIconWidget(
                    iconName: 'phone',
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  onPressed: _showEmergencyContact,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequestData,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bold Status Header
              _buildHeader(status, theme),

              // 2. Integrated Progress & Illustration
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 2.h),
                    StatusProgressWidget(currentStatus: status),
                    StatusIllustrationWidget(status: status),
                    SizedBox(height: 2.h),

                    // 3. Details Section (Unified Area)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      child: Column(
                        children: [
                          _buildDetailsSection(status, theme),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String status, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 15.h, left: 6.w, right: 6.w, bottom: 5.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(status).withOpacity(0.1),
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getStatusTag(status, theme),
          SizedBox(height: 2.h),
          Text(
            _getStatusTitle(status),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'طلب رقم: #${_requestId ?? _requestData?['id']}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _getStatusSubtitle(status),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _getStatusTag(String status, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _getStatusLabel(status),
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'pending':
        return 'جاري البحث...';
      case 'assigned':
        return 'تم إيجاد فني';
      case 'on_the_way':
        return 'الفني في الطريق';
      case 'arrived':
        return 'وصل الفني إليك';
      case 'started':
        return 'بدأ العمل الآن';
      case 'work_done':
        return 'انتهى العمل';
      case 'completed':
        return 'تم بنجاح!';
      case 'cancelled':
        return 'تم إلغاء الطلب';
      default:
        return 'تفاصيل الطلب';
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'pending':
        return 'نحن نبحث عن أفضل فني متاح لك الآن';
      case 'assigned':
        return 'تم تعيين فني بنجاح لتنفيذ طلبك';
      case 'on_the_way':
        return 'الفني يقترب من موقعك، كن جاهزاً';
      case 'arrived':
        return 'الفني متواجد حالياً أمام منزلك';
      case 'started':
        return 'يتم تنفيذ الخدمة حالياً بأعلى جودة';
      case 'work_done':
        return 'شكراً لتعاملك معنا، نتمنى أن نكون عند حسن ظنك';
      case 'completed':
        return 'تم إغلاق الطلب، يسعدنا تقييمك للخدمة';
      case 'cancelled':
        return 'نأسف لإلغاء طلبك، نأمل خدمتك قريباً';
      default:
        return 'تابع حالة طلبك هنا بلحظة بلحظة';
    }
  }

  Widget _buildDetailsSection(String status, ThemeData theme) {
    return Column(
      children: [
        // Technician Card (if assigned)
        if (status != 'pending' && _requestData!['technician'] != null)
          TechnicianProfileCardWidget(
            technicianData: _requestData!['technician'] as Map<String, dynamic>,
          ),

        SizedBox(height: 2.h),

        // Service Info
        ServiceInfoCardWidget(requestData: _requestData!),

        SizedBox(height: 2.h),

        // Location
        if (_requestData!['location'] != null)
          LocationSectionWidget(
            locationData: _requestData!['location'] as Map<String, dynamic>,
          ),

        SizedBox(height: 3.h),

        // Actions
        ActionButtonsWidget(
          status: status,
          onCancelRequest: _cancelRequest,
          onTrackTechnician: _trackTechnician,
        ),

        // Rating
        if (status == 'completed' || status == 'work_done')
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: RatingSectionWidget(
              requestId: _requestId!,
              onSubmitRating: (rating, comment) =>
                  _submitRating(rating, comment),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'assigned':
      case 'on_the_way':
      case 'arrived':
        return const Color(0xFF2563EB);
      case 'started':
      case 'work_done':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'assigned':
        return 'تم التعيين';
      case 'on_the_way':
        return 'في الطريق';
      case 'arrived':
        return 'وصل الفني';
      case 'started':
        return 'بدأ العمل';
      case 'work_done':
        return 'انتهى العمل';
      case 'completed':
        return 'مكتمل';
      default:
        return 'غير معروف';
    }
  }

  Future<void> _cancelRequest() async {
    if (_requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('رقم الطلب غير موجود'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إلغاء الطلب'),
        content: Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: Text('نعم، إلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _apiService.cancelRequest(_requestId!);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close details screen

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إلغاء الطلب بنجاح'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إلغاء الطلب: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _trackTechnician() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري فتح خريطة التتبع...'),
        backgroundColor: const Color(0xFF2563EB),
      ),
    );
  }

  Future<void> _submitRating(int rating, String comment) async {
    try {
      await _apiService.submitRating(
        requestId: _requestId!,
        rating: rating,
        review: comment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('شكراً لتقييمك!'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );

        // Wait a small bit for the snackbar/feeling of success before navigating
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Navigate to home page and clear stack
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.customerHome,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال التقييم: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('التواصل مع الدعم'),
        content:
            Text('هل تواجه مشكلة في هذا الطلب؟ يمكنك التواصل مع الدعم الفني.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('جاري فتح محادثة الدعم...')),
              );
            },
            child: Text('تواصل الآن'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اتصال طارئ'),
        content: Text('هل تريد الاتصال بخدمة الطوارئ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Launch phone dialer
            },
            child: Text('اتصال'),
          ),
        ],
      ),
    );
  }
}
