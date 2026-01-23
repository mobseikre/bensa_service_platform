import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/active_request_banner_widget.dart';
import './widgets/greeting_header_widget.dart';
import './widgets/service_category_card_widget.dart';
import './widgets/promo_carousel_widget.dart';
import './widgets/location_confirmation_widget.dart';

/// Customer Home Screen - Primary dashboard for service request creation and management
/// Implements bottom tab navigation with Home, My Requests, and Profile tabs
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentBottomIndex = 0;

  // User-specific data (to be provided from login/navigation arguments)
  String _userName = 'العميل';
  String _currentLocation = 'جاري تحديد الموقع...';
  String _userRole = 'customer'; // Default to customer
  String? _userEmail;
  String? _userPhone;
  bool _didLoadRouteArgs = false;
  static bool _locationConfirmed = false;
  bool _isShowingLocationConfirmation = false;
  int _unreadNotificationsCount = 0;

  // Data loading states
  final ApiService _apiService = ApiService();

  // Data loading states
  bool _isLoadingUserData = false;
  bool _isLoadingRequests = false;
  bool _isLoadingCategories = false;

  List<Map<String, dynamic>> _serviceCategories = [];

  // Recent requests (loaded from API)
  List<Map<String, dynamic>> _recentRequests = [];

  // Active requests list
  List<Map<String, dynamic>> _activeRequests = [];

  // Animated Header State
  final List<String> _headerServiceNames = [
    'سباكة',
    'كهرباء واتصالات',
    'صيانة منازل',
    'طلاء وأعمال ديكور',
    'تكييف وتبريد',
  ];
  int _currentHeaderServiceIndex = 0;
  Timer? _headerTextTimer;

  @override
  void initState() {
    super.initState();
    _loadServiceCategories();
    _loadRequests();
    _loadUserDataAndNotifications(); // Load user data and notifications
    _startAutoRefresh();
    _loadDefaultLocation();
    _loadDefaultAddress(); // Fetch default address from API
    _loadPersistedUserName(); // Load name from storage
    _startHeaderTextAnimation();
  }

  @override
  void dispose() {
    _headerTextTimer?.cancel();
    super.dispose();
  }

  void _startHeaderTextAnimation() {
    _headerTextTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentHeaderServiceIndex =
              (_currentHeaderServiceIndex + 1) % _headerServiceNames.length;
        });
      }
    });
  }

  Future<void> _loadPersistedUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('persisted_user_name');
    if (savedName != null && savedName.isNotEmpty) {
      setState(() {
        _userName = savedName;
      });
    }
  }

  Future<void> _persistUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_user_name', name);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadRouteArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final passedName = (args['userName'] as String?)?.trim();
      if (passedName != null && passedName.isNotEmpty) {
        setState(() {
          _userName = passedName;
        });
        _persistUserName(passedName); // Save for later
      }

      setState(() {
        _currentLocation =
            (args['currentLocation'] as String?)?.trim().isNotEmpty == true
                ? (args['currentLocation'] as String).trim()
                : _currentLocation;
        _userRole = args['role'] as String? ??
            args['userRole'] as String? ??
            'customer';
        _userEmail = args['email'] as String?;
        _userPhone = args['phone'] as String?;
      });
    }

    _didLoadRouteArgs = true;
  }

  Future<void> _loadDefaultLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble('default_latitude');
    final savedLng = prefs.getDouble('default_longitude');
    if (savedLat != null && savedLng != null) {
      // Coordinates are saved to SharedPreferences but not currently used in state
    }
  }

  Future<void> _loadDefaultAddress() async {
    // If already confirmed in this session, we still want to fetch the address name for the header,
    // but we won't show the confirmation sheet again.

    try {
      final response = await _apiService.getAddresses();
      final List<dynamic> addresses = response['data'] ?? [];

      final defaultAddr = addresses.firstWhere(
        (a) => a['is_default'] == 1 || a['is_default'] == true,
        orElse: () => null,
      );

      if (defaultAddr != null && mounted) {
        final title = defaultAddr['title'] ?? defaultAddr['label'] ?? 'موقعي';
        setState(() {
          _currentLocation = title;
        });

        // Save to prefs for offline/fast load
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('default_address_label', _currentLocation);

        // Show confirmation sheet if not already confirmed in this session
        if (!_locationConfirmed && mounted) {
          _showLocationConfirmation(title);
        }
      }
    } catch (e) {
      debugPrint('Error loading default address: $e');
    }
  }

  void _showLocationConfirmation(String label) {
    if (_locationConfirmed || _isShowingLocationConfirmation) return;

    setState(() {
      _isShowingLocationConfirmation = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationConfirmationWidget(
        addressLabel: label,
        onConfirm: () {
          _locationConfirmed = true;
          if (mounted) {
            setState(() {
              _isShowingLocationConfirmation = false;
            });
          }
          Navigator.pop(context);
        },
        onChange: () {
          if (mounted) {
            setState(() {
              _isShowingLocationConfirmation = false;
            });
          }
          Navigator.pop(context);
          _navigateToManageAddresses();
        },
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isShowingLocationConfirmation = false;
        });
      }
    });
  }

  void _navigateToManageAddresses() {
    _navigateToMyAddresses();
  }

  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase().trim();
    // Satellite Installation - تركيب ستالايت (Clear satellite dish icon)
    if (name.contains('ستالايت') || name.contains('satellite')) {
      return 'satellite';
    }

    // Furniture Installation - تركيب أثاث (Clear furniture icon - chair_alt is better than chair)
    if (name.contains('تركيب أثاث') ||
        (name.contains('أثاث') && name.contains('تركيب'))) {
      return 'chair_alt'; // More descriptive furniture icon
    }

    // Painting and Gypsum combined - الطلاء والجبس (Paint brush is most descriptive)
    if (name.contains('الطلاء') && name.contains('جبس')) {
      return 'format_paint'; // Paint brush icon - very clear
    }

    // Electrical Services - خدمات كهربائية (Lightning bolt icon)
    if ((name.contains('كهرب') || name.contains('electrical')) &&
        (name.contains('خدمات') || name.contains('service'))) {
      return 'electrical_services'; // Lightning bolt - very clear
    }

    // Chemistry/Chemical Services - كمياء / خدمات كميائية (Science flask icon)
    if (name.contains('كمياء') ||
        name.contains('كيميائية') ||
        name.contains('chemistry') ||
        name.contains('chemical')) {
      return 'science'; // Flask/beaker icon - very clear for chemistry
    }

    // Carpentry/Installation - نجارة / تركيب (Construction icon - saw and hammer)
    if ((name.contains('نجارة') || name.contains('carpenter')) &&
        (name.contains('تركيب') || name.contains('installation'))) {
      return 'construction'; // Construction tools - very clear
    }

    // Now check individual service types with CLEAR, DESCRIPTIVE icons

    // Plumbing - سباكة (Wrench icon - VERY clear for plumbing)
    if (name.contains('سباكة') ||
        name.contains('plumbing') ||
        name.contains('سباك')) {
      return 'plumbing'; // Wrench icon - unmistakable for plumbing
    }

    // Electrical - كهرباء (Lightning/plug icon - VERY clear)
    if (name.contains('كهرباء') ||
        name.contains('electrical') ||
        name.contains('كهرب')) {
      return 'electrical_services'; // Lightning bolt icon - unmistakable
    }

    // Cleaning - تنظيف (Broom/dustpan icon - VERY clear)
    if (name.contains('تنظيف') || name.contains('cleaning')) {
      return 'cleaning_services'; // Broom icon - unmistakable
    }

    // AC & Refrigeration - تكييف وتبريد (AC unit icon - VERY clear)
    if (name.contains('تكييف') ||
        name.contains('تبريد') ||
        name.contains('ac') ||
        name.contains('air') ||
        name.contains('refrigeration') ||
        name.contains('cooling')) {
      return 'ac_unit'; // AC unit icon - unmistakable
    }

    // Carpentry - نجارة (Saw/hammer icon - VERY clear for carpentry)
    if (name.contains('نجارة') || name.contains('carpenter')) {
      return 'construction'; // Construction tools - unmistakable for carpentry
    }

    // Installation - تركيب (Toolbox icon - VERY clear for installation)
    if (name.contains('تركيب')) {
      return 'handyman'; // Toolbox icon - unmistakable for installation
    }

    // Painting - دهان / طلاء (Paint brush icon - VERY clear)
    if (name.contains('دهان') ||
        name.contains('طلاء') ||
        name.contains('paint')) {
      return 'format_paint'; // Paint brush icon - unmistakable
    }

    // Gypsum - جبس (Wall/construction icon - clear for drywall/gypsum work)
    if (name.contains('جبس') || name.contains('gypsum')) {
      return 'home_repair_service'; // Home repair icon - clear for gypsum work
    }

    // Networks - شبكات (Router/WiFi icon - VERY clear for networks)
    if (name.contains('شبكات') ||
        name.contains('network') ||
        name.contains('الشبكات')) {
      return 'router'; // Router icon - unmistakable for networks
    }

    // Camera - كاميرا (Camera icon - VERY clear)
    if (name.contains('كاميرا') || name.contains('camera')) {
      return 'videocam'; // Camera icon - unmistakable
    }

    // Other Services - خدمات أخرى (More options icon)
    if (name.contains('خدمات أخرى') ||
        (name.contains('خدمات') && name.contains('أخرى'))) {
      return 'more_horiz'; // More options - clear for "other services"
    }

    // General Services - خدمات (Services icon - clear for general services)
    if (name.contains('خدمات')) {
      return 'miscellaneous_services'; // Services icon - clear
    }

    // Default fallback - use a clear repair/tool icon (NEVER use question mark)
    return 'build'; // Tool/wrench icon - clear fallback, not confusing
  }

  int _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase().trim();

    // Plumbing - سباكة
    if (name.contains('سباكة') ||
        name.contains('plumbing') ||
        name.contains('سباك')) {
      return 0xFF2563EB; // Blue
    }

    // Electrical - كهرباء
    if (name.contains('كهرباء') ||
        name.contains('electrical') ||
        name.contains('كهرب')) {
      return 0xFFF59E0B; // Amber/Orange
    }

    // Cleaning - تنظيف
    if (name.contains('تنظيف') || name.contains('cleaning')) {
      return 0xFF10B981; // Green
    }

    // AC & Refrigeration - تكييف وتبريد
    if (name.contains('تكييف') ||
        name.contains('تبريد') ||
        name.contains('ac') ||
        name.contains('air') ||
        name.contains('refrigeration') ||
        name.contains('cooling')) {
      return 0xFF06B6D4; // Cyan
    }

    // Carpentry/Furniture - نجارة / تركيب أثاث
    if (name.contains('نجارة') ||
        name.contains('أثاث') ||
        name.contains('furniture') ||
        name.contains('carpenter') ||
        name.contains('تركيب أثاث') ||
        name.contains('تركيب/')) {
      return 0xFFEF4444; // Red
    }

    // Painting - دهان / طلاء
    if (name.contains('دهان') ||
        name.contains('طلاء') ||
        name.contains('paint') ||
        name.contains('الطلاء')) {
      return 0xFFEC4899; // Pink
    }

    // Gypsum - جبس
    if (name.contains('جبس') ||
        name.contains('gypsum') ||
        name.contains('والجبس')) {
      return 0xFFF59E0B; // Amber
    }

    // Networks - شبكات
    if (name.contains('شبكات') ||
        name.contains('network') ||
        name.contains('الشبكات')) {
      return 0xFF3B82F6; // Blue
    }

    // Camera - كاميرا
    if (name.contains('كاميرا') || name.contains('camera')) {
      return 0xFF6366F1; // Indigo
    }

    // Satellite - ستالايت
    if (name.contains('ستالايت') ||
        name.contains('satellite') ||
        name.contains('تركيب ستالايت')) {
      return 0xFF8B5CF6; // Purple
    }

    // Installation - تركيب
    if (name.contains('تركيب') &&
        !name.contains('أثاث') &&
        !name.contains('ستالايت')) {
      return 0xFF14B8A6; // Teal
    }

    // Other Services - خدمات أخرى
    if (name.contains('خدمات أخرى') ||
        (name.contains('خدمات') && name.contains('أخرى'))) {
      return 0xFF64748B; // Slate
    }

    // General Services - خدمات
    if (name.contains('خدمات') && !name.contains('أخرى')) {
      return 0xFF8B5CF6; // Purple
    }

    // Default fallback - nice gray
    return 0xFF6B7280;
  }

  Future<void> _loadUserDataAndNotifications() async {
    if (_isLoadingUserData) return;

    if (mounted) {
      setState(() {
        _isLoadingUserData = true;
      });
    }

    try {
      // Fetch user profile
      final profileResponse = await _apiService.getProfile();
      if (kDebugMode) {
        print('=== USER PROFILE LOADED ===');
        print('Profile Data: ${profileResponse['data']}');
      }

      final userData = profileResponse['data'] as Map<String, dynamic>?;

      if (userData != null && mounted) {
        setState(() {
          // Only update if current name is default or empty to prevent over-writing route args
          if (_userName == 'العميل' || _userName.isEmpty) {
            _userName = userData['name'] ?? _userName;
          }
          _userEmail = userData['email'] ?? _userEmail;
          _userPhone = userData['phone'] ?? _userPhone;
        });

        // Persist the name if we got it
        if (userData['name'] != null) {
          _persistUserName(userData['name']);
        }
      }

      // Fetch notifications to check for unread
      final notificationsResponse = await _apiService.getNotifications(page: 1);
      if (mounted) {
        setState(() {
          _unreadNotificationsCount =
              notificationsResponse['unread_count'] ?? 0;
        });
      }

      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _loadServiceCategories() async {
    if (_isLoadingCategories) return;

    if (mounted) {
      setState(() {
        _isLoadingCategories = true;
      });
    }

    try {
      final response = await _apiService.getServiceCategories();
      final categories = response['data'] as List<dynamic>?;

      if (categories == null) {
        throw Exception('Response data is null. Response: $response');
      }

      if (kDebugMode) {
        print('=== SERVICE CATEGORIES LOADED ===');
        print('Categories count: ${categories.length}');
      }

      // Map API response to expected format
      final mappedCategories = categories.map<Map<String, dynamic>>((cat) {
        final category = cat as Map<String, dynamic>;
        final nameAr = category['name_ar'] as String? ?? '';
        final nameEn =
            category['name'] as String? ?? category['name_en'] as String? ?? '';
        final categoryName = nameAr.isNotEmpty ? nameAr : nameEn;

        // Use our smart icon mapping
        final iconName = _getCategoryIcon(categoryName);

        // Safely convert base_price
        double? basePrice;
        try {
          final priceValue = category['base_price'] ??
              category['basePrice'] ??
              category['price'];
          if (priceValue != null) {
            // Remove any currency symbols or non-numeric characters except dot
            final cleanPrice =
                priceValue.toString().replaceAll(RegExp(r'[^0-9.]'), '');
            basePrice = double.tryParse(cleanPrice);
          }
        } catch (e) {
          debugPrint('Error parsing price for $categoryName: $e');
          basePrice = null;
        }

        return {
          'id': category['id'],
          'name': categoryName,
          'name_en': nameEn, // Critical for backend matching
          'icon': iconName,
          'color': _getCategoryColor(categoryName),
          'isPopular': category['is_popular'] ?? category['isPopular'] ?? false,
          'base_price': basePrice, // can be null (Price on Request)
          'description': category['description'] ??
              category['description_ar'] ??
              category['description_en'] ??
              '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _serviceCategories = mappedCategories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading service categories: $e');
      }
      if (mounted) {
        setState(() {
          _serviceCategories = [];
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    if (_isLoadingRequests) return;

    setState(() {
      _isLoadingRequests = true;
    });

    try {
      final response = await _apiService.getMyRequests(page: 1);
      final data = response['data'] as List<dynamic>? ?? [];

      // Map API response to expected format
      final List<Map<String, dynamic>> mappedRequests = [];

      // Fetch saved addresses to match labels
      List<dynamic> savedAddresses = [];
      try {
        final addrResponse = await _apiService.getAddresses();
        savedAddresses = addrResponse['data'] ?? [];
      } catch (e) {
        debugPrint('Error loading addresses in _loadRequests: $e');
      }

      for (var req in data) {
        final request = req as Map<String, dynamic>;
        final status = request['status'] as String? ?? 'pending';
        final reqAddress = request['address'] as String? ?? '';
        final reqLat = request['location_lat'];
        final reqLng = request['location_lng'];

        String displayLocation = reqAddress;

        // Try to find a matching label from saved addresses
        if (savedAddresses.isNotEmpty) {
          final match = savedAddresses.firstWhere(
            (a) {
              // Match by label/title first if stored in request (unlikely currently)
              // Match by coordinates (with small tolerance)
              if (reqLat != null &&
                  reqLng != null &&
                  a['latitude'] != null &&
                  a['longitude'] != null) {
                final double latDiff = (reqLat is num
                        ? reqLat.toDouble()
                        : double.tryParse(reqLat.toString()) ?? 0.0) -
                    (a['latitude'] is num
                        ? a['latitude'].toDouble()
                        : double.tryParse(a['latitude'].toString()) ?? 0.0);
                final double lngDiff = (reqLng is num
                        ? reqLng.toDouble()
                        : double.tryParse(reqLng.toString()) ?? 0.0) -
                    (a['longitude'] is num
                        ? a['longitude'].toDouble()
                        : double.tryParse(a['longitude'].toString()) ?? 0.0);
                return latDiff.abs() < 0.001 && lngDiff.abs() < 0.001;
              }
              return false;
            },
            orElse: () => null,
          );

          if (match != null) {
            displayLocation = match['title'] ?? match['label'] ?? reqAddress;
          }
        }

        mappedRequests.add({
          'id': request['id'],
          'serviceType': request['category'] ?? '',
          'status': _getStatusLabel(status),
          'statusColor': _getStatusColor(status),
          'technicianName': request['technician']?['name'],
          'technicianAvatar': request['technician']?['avatar'],
          'requestDate': request['created_at']?.toString().split('T')[0] ?? '',
          'location': displayLocation,
          'priority': request['priority'] == 'urgent' ? 'عاجل' : 'عادي',
          'rawStatus': status,
        });
      }

      // Check for active request (including pending)
      final activeRequest = mappedRequests.firstWhere(
        (req) => ['pending', 'assigned', 'on_the_way', 'arrived', 'started']
            .contains(req['rawStatus']),
        orElse: () => <String, dynamic>{},
      );

      if (mounted) {
        setState(() {
          _recentRequests = mappedRequests;
          _activeRequests = activeRequest.isNotEmpty ? [activeRequest] : [];
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentRequests = [];
          _activeRequests = [];
          _isLoadingRequests = false;
        });
      }
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
        return 'قيد التنفيذ';
      case 'work_done':
        return 'انتهى العمل';
      case 'completed':
        return 'مكتمل';
      case 'canceled':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  int _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return 0xFFF59E0B;
      case 'assigned':
      case 'on_the_way':
      case 'arrived':
        return 0xFF2563EB;
      case 'started':
        return 0xFF10B981;
      case 'work_done':
      case 'completed':
        return 0xFF10B981;
      case 'canceled':
        return 0xFFEF4444;
      default:
        return 0xFF6B7280;
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadRequests(); // Only refresh requests, not user data
        _startAutoRefresh();
      }
    });
  }

  String _getEtaForStatus(String status) {
    switch (status) {
      case 'pending':
        return 'في انتظار التعيين';
      case 'assigned':
        return 'جاري التنسيق';
      case 'on_the_way':
        return '15 دقيقة';
      case 'arrived':
        return 'وصل الفني';
      case 'started':
        return 'جاري العمل';
      default:
        return 'قيد المعالجة';
    }
  }

  Future<void> _navigateToMyAddresses() async {
    await Navigator.pushNamed(context, '/my-addresses-screen');
    // Refresh address and requests when returning
    _loadDefaultAddress();
    _loadRequests();
  }

  Future<void> _refreshData() async {
    await _loadRequests();
    // Removed _loadUserDataAndNotifications() to keep name static
  }

  void _navigateToCreateRequest(
      {String? selectedCategory, String? priority, bool isScheduled = false}) {
    HapticFeedback.mediumImpact();

    try {
      Navigator.pushNamed(
        context,
        '/create-request-screen',
        arguments: {
          'selectedCategory': selectedCategory,
          'priority': priority,
          'isScheduled': isScheduled,
        },
      ).catchError((error) {
        debugPrint('Navigation error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('حدث خطأ في التنقل إلى صفحة الطلب'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error initiating navigation: $e');
    }
  }

  void _navigateToRequestDetails(int requestId) {
    // Find the request data to pass to details screen
    final request = _recentRequests.firstWhere(
      (r) => r['id'] == requestId,
      orElse: () => <String, dynamic>{'id': requestId},
    );

    Navigator.pushNamed(
      context,
      '/request-details-screen',
      arguments: request,
    );
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
                    color: Theme.of(context).colorScheme.primary,
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
              if (await canLaunchUrl(launchUri)) {
                await launchUrl(launchUri);
              }
            },
            icon: const Icon(Icons.phone),
            label: const Text('اتصال الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentBottomIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/my-requests-screen');
        break;
      case 2:
        Navigator.pushNamed(
          context,
          '/profile-screen',
          arguments: {
            'userName': _userName,
            'name': _userName,
            'email': _userEmail,
            'phone': _userPhone,
            'currentLocation': _currentLocation,
            'role': _userRole, // Pass customer role
            'userRole': _userRole,
          },
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 50.w,
        leading: GestureDetector(
          onTap: _navigateToMyAddresses,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نخدمك في',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _currentLocation.isEmpty
                                  ? 'اختر عنواناً'
                                  : _currentLocation,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                fontSize: 13.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 1.w),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        titleWidget: const SizedBox.shrink(),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                iconSize: 26,
                color: theme.colorScheme.primary,
                onPressed: () async {
                  await Navigator.pushNamed(context, '/notifications-screen');
                  // Refresh unread count when returning
                  _loadUserDataAndNotifications();
                },
              ),
              if (_unreadNotificationsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadNotificationsCount > 99
                          ? '99+'
                          : '$_unreadNotificationsCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            iconSize: 26,
            color: theme.colorScheme.primary,
            onPressed: _showCustomerSupportDialog,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: _isLoadingUserData
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: GreetingHeaderWidget(
                        userName: _userName,
                        currentLocation: _currentLocation,
                      ),
                    ),

                    // Promotional Carousel
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2.h), // Only top padding
                        child: const PromoCarouselWidget(),
                      ),
                    ),

                    // Active Request Banner (if exists)
                    if (_activeRequests.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: ActiveRequestBannerWidget(
                          technicianName: (_activeRequests.first['rawStatus'] ==
                                      'pending' ||
                                  _activeRequests.first['technicianName'] ==
                                      null)
                              ? 'جاري البحث عن فني لخدمة ${_activeRequests.first['serviceType'] ?? ''}'
                              : (_activeRequests.first['technicianName'] ??
                                  'فني بنسا'),
                          eta: _getEtaForStatus(
                              _activeRequests.first['rawStatus'] ?? 'pending'),
                          currentLocation:
                              _activeRequests.first['location'] ?? '',
                          status: _activeRequests.first['status'],
                          avatarUrl: _activeRequests.first['technicianAvatar'],
                          onTrackPressed: () => _navigateToRequestDetails(
                              _activeRequests.first['id'] as int),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],

                    // Consolidated Sections: Services + Divider + Why Bensa
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.only(
                            bottom: 2.h), // No top padding/margin
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Services Header
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'خدماتنا',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 600),
                                            layoutBuilder: (child,
                                                List<Widget> previousChildren) {
                                              return Stack(
                                                alignment:
                                                    Alignment.centerRight,
                                                children: <Widget>[
                                                  ...previousChildren,
                                                  if (child != null) child,
                                                ],
                                              );
                                            },
                                            transitionBuilder: (Widget child,
                                                Animation<double> animation) {
                                              final positionAnimation =
                                                  Tween<Offset>(
                                                begin: const Offset(0.0, 0.2),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutCubic,
                                              ));

                                              return FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: positionAnimation,
                                                  child: child,
                                                ),
                                              );
                                            },
                                            child: Text(
                                              _headerServiceNames[
                                                  _currentHeaderServiceIndex],
                                              key: ValueKey<int>(
                                                  _currentHeaderServiceIndex),
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme
                                                    .primary, // Using theme primary blue
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushNamed(context,
                                              '/create-request-screen');
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'عرض الكل',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 0.5.w),
                                            Icon(
                                              Icons.arrow_back_ios,
                                              size: 12,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'اختر الخدمة التي تحتاجها وسنوفر لك أفضل فني',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 3.h),

                            // Grid of services
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: _serviceCategories.isEmpty
                                  ? _isLoadingCategories
                                      ? Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4.h),
                                            child: CircularProgressIndicator(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 4.h),
                                            child: Text(
                                              'جاري تحميل الخدمات...',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        )
                                  : GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 2.2,
                                      ),
                                      itemCount: _serviceCategories.length,
                                      itemBuilder: (context, index) {
                                        final category =
                                            _serviceCategories[index];
                                        return ServiceCategoryCardWidget(
                                          name: category["name"] as String,
                                          iconName: category["icon"] as String,
                                          color:
                                              Color(category["color"] as int),
                                          isPopular:
                                              category["isPopular"] as bool,
                                          onTap: () => _navigateToCreateRequest(
                                              selectedCategory:
                                                  category['name_en']),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom spacing - reduced to end the page cleanly
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomerBottomBar(
          currentIndex: _currentBottomIndex,
          onTap: _handleBottomNavTap,
          style: CustomBottomBarStyle.floating,
        ),
      ),
    );
  }
}
