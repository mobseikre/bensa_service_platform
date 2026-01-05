import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/empty_state_widget.dart';
import './widgets/request_card_widget.dart';
import './widgets/skeleton_loading_widget.dart';
import './widgets/status_filter_widget.dart';

/// My Requests Screen - Displays paginated request history with filtering
/// Implements tab navigation with status-based filtering and real-time updates
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller for bottom navigation
  int _currentBottomIndex = 1; // My Requests tab

  // Status filter state
  String _selectedStatus = 'all';
  Map<String, int> _statusCounts = {
    'all': 0,
    'active': 0,
    'completed': 0,
    'cancelled': 0,
  };

  // Pagination state
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreData = true;

  // Search state
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  final ApiService _apiService = ApiService();

  // Requests data
  List<Map<String, dynamic>> _allRequests = [];
  List<Map<String, dynamic>> _filteredRequests = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1; // Always start from page 1
      _hasMoreData = true;
    });

    try {
      final response = await _apiService.getMyRequests(
        page: 1, // Always load page 1
        status: null, // Load all statuses to calculate counts correctly
      );

      final responseData = response['data'];
      List<dynamic> items = [];

      if (responseData != null) {
        if (responseData is List) {
          items = responseData;
          _hasMoreData = false;
        } else if (responseData is Map<String, dynamic>) {
          final nestedData = responseData['data'];
          if (nestedData is List) {
            items = nestedData;
          } else if (responseData['items'] is List) {
            items = responseData['items'];
          }

          // Robustly parse pagination metadata
          final lastPage =
              int.tryParse(responseData['last_page']?.toString() ?? '') ??
                  int.tryParse(response['last_page']?.toString() ?? '') ??
                  1;
          final currentPage =
              int.tryParse(responseData['current_page']?.toString() ?? '') ??
                  int.tryParse(response['current_page']?.toString() ?? '') ??
                  1;
          final total = int.tryParse(responseData['total']?.toString() ?? '') ??
              items.length;
          final perPage =
              int.tryParse(responseData['per_page']?.toString() ?? '') ?? 10;

          // Logic to decide if we have more data
          if (items.isEmpty ||
              items.length < perPage ||
              currentPage >= lastPage ||
              items.length >= total) {
            _hasMoreData = false;
          } else {
            _hasMoreData = true;
          }
        } else {
          _hasMoreData = false;
        }
      } else {
        // Check root level if data is null (some APIs put items at root)
        if (response['items'] is List) {
          items = response['items'];
        }
        _hasMoreData = false;
      }

      final mappedRequests = items.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        final status = m['status'] as String? ?? 'pending';

        final latStr =
            m['location_lat']?.toString() ?? m['latitude']?.toString();
        final lngStr =
            m['location_lng']?.toString() ?? m['longitude']?.toString();
        final latitude = latStr != null ? double.tryParse(latStr) : null;
        final longitude = lngStr != null ? double.tryParse(lngStr) : null;

        return {
          'id': m['id'],
          'category': m['category'] ?? m['service_type'] ?? '',
          'categoryIcon': 'plumbing',
          'description': m['description'] ?? '',
          'createdAt': DateTime.tryParse(m['created_at']?.toString() ?? '') ??
              DateTime.now(),
          'status': _getStatusLabel(status),
          'rawStatus': status,
          'statusArabic': m['status_ar'] ??
              m['status_arabic'] ??
              _getStatusLabel(status) ??
              'غير معروف',
          'priority': m['priority'] ?? 'normal',
          'technicianName': m['technician']?['name'] ?? m['technician_name'],
          'technicianAvatar':
              m['technician']?['avatar'] ?? m['technician_avatar'],
          'technicianPhone': m['technician']?['phone'] ?? m['technician_phone'],
          'location': m['address'] ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'raw': m,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allRequests = mappedRequests;
          _calculateStatusCounts();
          _filterRequests();
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error loading requests: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحميل الطلبات: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getMyRequests(
        page: nextPage,
      );

      final responseData = response['data'];
      List<dynamic> newItems = [];

      if (responseData != null) {
        if (responseData is List) {
          newItems = responseData;
          _hasMoreData = false;
        } else if (responseData is Map<String, dynamic>) {
          final nestedData = responseData['data'];
          if (nestedData is List) {
            newItems = nestedData;
          } else if (responseData['items'] is List) {
            newItems = responseData['items'];
          }

          final lastPage =
              int.tryParse(responseData['last_page']?.toString() ?? '') ??
                  int.tryParse(response['last_page']?.toString() ?? '') ??
                  nextPage;
          final currentPage =
              int.tryParse(responseData['current_page']?.toString() ?? '') ??
                  int.tryParse(response['current_page']?.toString() ?? '') ??
                  nextPage;
          final perPage =
              int.tryParse(responseData['per_page']?.toString() ?? '') ?? 10;

          if (newItems.isEmpty ||
              newItems.length < perPage ||
              currentPage >= lastPage) {
            _hasMoreData = false;
          } else {
            _hasMoreData = true;
          }
        }
      } else {
        _hasMoreData = false;
      }

      if (newItems.isEmpty) {
        _hasMoreData = false;
      } else {
        final newMappedRequests = newItems.map<Map<String, dynamic>>((raw) {
          final m = Map<String, dynamic>.from(raw as Map);
          final status = m['status'] as String? ?? 'pending';

          final latStr =
              m['location_lat']?.toString() ?? m['latitude']?.toString();
          final lngStr =
              m['location_lng']?.toString() ?? m['longitude']?.toString();
          final latitude = latStr != null ? double.tryParse(latStr) : null;
          final longitude = lngStr != null ? double.tryParse(lngStr) : null;

          return {
            'id': m['id'],
            'category': m['category'] ?? m['service_type'] ?? '',
            'categoryIcon': 'plumbing',
            'description': m['description'] ?? '',
            'createdAt': DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                DateTime.now(),
            'status': _getStatusLabel(status),
            'rawStatus': status,
            'statusArabic': m['status_ar'] ??
                m['status_arabic'] ??
                _getStatusLabel(status) ??
                'غير معروف',
            'priority': m['priority'] ?? 'normal',
            'technicianName': m['technician']?['name'] ?? m['technician_name'],
            'technicianAvatar':
                m['technician']?['avatar'] ?? m['technician_avatar'],
            'technicianPhone':
                m['technician']?['phone'] ?? m['technician_phone'],
            'location': m['address'] ?? '',
            'latitude': latitude,
            'longitude': longitude,
            'raw': m,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _currentPage = nextPage;
            _allRequests.addAll(newMappedRequests);
            _calculateStatusCounts();
            _filterRequests();
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading more requests: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });

    // Reload data from API
    await _loadInitialData();

    if (mounted) {
      // Data reloaded
    }
  }

  void _calculateStatusCounts() {
    int allCount = _allRequests.length;
    int activeCount = 0;
    int completedCount = 0;
    int cancelledCount = 0;

    for (var request in _allRequests) {
      final rawStatus = (request['rawStatus'] as String?) ?? '';

      if (rawStatus == 'pending' ||
          rawStatus == 'assigned' ||
          rawStatus == 'on_the_way' ||
          rawStatus == 'started') {
        activeCount++;
      } else if (rawStatus == 'completed' || rawStatus == 'work_done') {
        completedCount++;
      } else if (rawStatus == 'canceled') {
        cancelledCount++;
      }
    }

    setState(() {
      _statusCounts = {
        'all': allCount,
        'active': activeCount,
        'completed': completedCount,
        'cancelled': cancelledCount,
      };
    });
  }

  void _filterRequests() {
    List<Map<String, dynamic>> filtered = _allRequests;

    // Filter by status (use rawStatus which contains the status code)
    if (_selectedStatus != 'all') {
      if (_selectedStatus == 'active') {
        filtered = filtered.where((r) {
          final rawStatus =
              (r['rawStatus'] as String?) ?? r['status'] as String?;
          return rawStatus == 'pending' ||
              rawStatus == 'assigned' ||
              rawStatus == 'on_the_way' ||
              rawStatus == 'started';
        }).toList();
      } else if (_selectedStatus == 'completed') {
        // Treat both 'completed' and 'work_done' as completed requests
        filtered = filtered.where((r) {
          final rawStatus =
              (r['rawStatus'] as String?) ?? r['status'] as String?;
          return rawStatus == 'completed' || rawStatus == 'work_done';
        }).toList();
      } else if (_selectedStatus == 'cancelled') {
        // Filter for canceled requests (API uses 'canceled', filter uses 'cancelled')
        filtered = filtered.where((r) {
          final rawStatus =
              (r['rawStatus'] as String?) ?? r['status'] as String?;
          return rawStatus == 'canceled';
        }).toList();
      } else {
        filtered = filtered.where((r) {
          final rawStatus =
              (r['rawStatus'] as String?) ?? r['status'] as String?;
          return rawStatus == _selectedStatus;
        }).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final description = (r['description'] as String).toLowerCase();
        final technicianName =
            ((r['technicianName'] as String?) ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return description.contains(query) || technicianName.contains(query);
      }).toList();
    }

    setState(() {
      _filteredRequests = filtered;
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 1;
      _hasMoreData = true;
    });
    _filterRequests();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterRequests();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (!_isSearchExpanded) {
        _searchController.clear();
        _searchQuery = '';
        _filterRequests();
      }
    });
  }

  void _onRequestTap(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/request-details-screen',
      arguments: request,
    );
  }

  void _onCallTechnician(Map<String, dynamic> request) {
    HapticFeedback.mediumImpact();
    // Implement phone call functionality
    final phone = request['technicianPhone'] as String?;
    if (phone != null) {
      // Use url_launcher to make phone call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الاتصال بـ ${request['technicianName']}...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onCancelRequest(Map<String, dynamic> request) async {
    HapticFeedback.mediumImpact();

    final requestId = request['id'] as int?;
    if (requestId == null) {
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
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('نعم'),
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
      await _apiService.cancelRequest(requestId);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Reload requests to get updated status
        await _loadInitialData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الطلب بنجاح'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

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

  void _onRateRequest(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/request-details-screen',
      arguments: {'requestId': request['id'], 'showRating': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: _isSearchExpanded
            ? _buildSearchField(theme)
            : Text(
                'طلباتي',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: _isSearchExpanded ? 'close' : 'search',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _toggleSearch,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          StatusFilterWidget(
            selectedStatus: _selectedStatus,
            statusCounts: _statusCounts,
            onStatusChanged: _onStatusFilterChanged,
          ),
          SizedBox(height: 2.h),

          // Request list
          Expanded(
            child: _buildRequestList(theme),
          ),
        ],
      ),
      bottomNavigationBar: CustomerBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() {
            _currentBottomIndex = index;
          });
        },
        style: CustomBottomBarStyle.floating,
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Container(
      height: 6.h,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light
            ? const Color(0xFFF9FAFB)
            : const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF4B5563),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'بحث في الطلبات...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.brightness == Brightness.light
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
          prefixIcon: CustomIconWidget(
            iconName: 'search',
            color: theme.brightness == Brightness.light
                ? const Color(0xFF6B7280)
                : const Color(0xFF9CA3AF),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: 1.5.h,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestList(ThemeData theme) {
    if (_isLoading && _currentPage == 1) {
      return const SkeletonLoadingWidget();
    }

    if (_filteredRequests.isEmpty) {
      return EmptyStateWidget(
        selectedStatus: _selectedStatus,
        hasSearchQuery: _searchQuery.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        itemCount: _filteredRequests.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredRequests.length) {
            return _buildLoadingIndicator(theme);
          }

          final request = _filteredRequests[index];
          return _buildRequestCard(request, theme);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, ThemeData theme) {
    final status = request['status'] as String;
    final isActive = status == 'pending' ||
        status == 'assigned' ||
        status == 'on_the_way' ||
        status == 'started';
    final isCompleted = status == 'completed';
    final hasTechnician = request['technicianName'] != null;

    return Slidable(
      key: ValueKey(request['id']),
      startActionPane: isActive && hasTechnician
          ? ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _onCallTechnician(request),
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  icon: Icons.phone,
                  label: 'اتصال',
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (isActive)
            SlidableAction(
              onPressed: (_) => _onCancelRequest(request),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              icon: Icons.cancel,
              label: 'إلغاء',
              borderRadius: BorderRadius.circular(12),
            ),
          if (isCompleted && request['rating'] == null)
            SlidableAction(
              onPressed: (_) => _onRateRequest(request),
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              icon: Icons.star,
              label: 'تقييم',
              borderRadius: BorderRadius.circular(12),
            ),
        ],
      ),
      child: RequestCardWidget(
        request: request,
        onTap: () => _onRequestTap(request),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Center(
        child: SizedBox(
          width: 6.w,
          height: 6.w,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
