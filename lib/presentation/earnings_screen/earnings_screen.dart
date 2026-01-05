import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/earnings_chart_widget.dart';
import './widgets/earnings_header_widget.dart';
import './widgets/earnings_summary_cards_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/time_period_selector_widget.dart';
import './widgets/transaction_history_widget.dart';
import './widgets/withdrawal_history_widget.dart';

/// Earnings Screen - Comprehensive financial dashboard with custody management
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 2;
  String _selectedPeriod = 'الأسبوع';
  late TabController _tabController;

  // API service for backend communication
  final ApiService _apiService = ApiService();

  // Custody and performance data (loaded from backend)
  String _custodyBalance = '0'; // Current pending custody amount
  String _totalPaidCustody = '0'; // Total custody paid to platform
  int _completedJobs = 0;
  String _averageCustodyPerJob = '0'; // Average custody per completed job
  double _customerRating = 0.0;
  double _weeklyGoalProgress = 0.0;
  String _topServiceCategory = '-';
  String _peakEarningHours = '-';
  int _availableJobsCount = 0;
  Map<String, dynamic>? _workWindow;

  List<Map<String, dynamic>> _chartData = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _custodyPayments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustodyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load custody data and stats from backend
  Future<void> _loadCustodyData() async {
    try {
      if (kDebugMode) {
        print('=== LOADING CUSTODY DATA ===');
      }

      // Load technician stats (includes custody information)
      final statsResponse = await _apiService.getTechnicianStats();

      // Try to load earnings/custody history (optional)
      Map<String, dynamic>? earningsResponse;
      try {
        earningsResponse = await _apiService.getTechnicianEarnings();
      } catch (earningsError) {
        debugPrint('Earnings API not available: $earningsError');
        // Continue without earnings data - not critical
      }

      if (mounted) {
        setState(() {
          // Update stats from backend response
          _completedJobs = statsResponse['completed_jobs'] ?? 0;
          _customerRating = (statsResponse['average_rating'] ?? 0.0).toDouble();
          _availableJobsCount = statsResponse['available_jobs_count'] ?? 0;

          // Update custody balance
          final pendingCustody = statsResponse['pending_custody'] ?? {};
          _custodyBalance = (pendingCustody['amount'] ?? 0.0).toString();
          _workWindow = statsResponse['work_window'];

          // Load custody payments history (if available)
          if (earningsResponse != null &&
              earningsResponse['success'] == true &&
              earningsResponse['data'] != null) {
            final earningsData = earningsResponse['data'];

            // Update summary stats
            final summary = earningsData['summary'] ?? {};
            _totalPaidCustody = (summary['settled_custody'] ?? 0).toString();

            if (earningsData['recent_earnings'] is List) {
              final List rawList = earningsData['recent_earnings'];
              final mappedList = rawList
                  .map<Map<String, dynamic>>(
                      (earning) => Map<String, dynamic>.from(earning))
                  .toList();

              // Transactions tab shows everything (all work counts)
              _transactions = mappedList;

              // History tab ONLY shows "Settled" payments to the platform
              // We check both status and is_settled for maximum reliability
              _custodyPayments = mappedList.where((e) {
                final isSettled = e['is_settled'];
                final status = e['status'];
                return isSettled == true ||
                    isSettled == 1 ||
                    isSettled.toString() == 'true' ||
                    isSettled.toString() == '1' ||
                    status == 'completed' ||
                    status == 'settled';
              }).toList();
            }

            // Calculate average
            _averageCustodyPerJob = _completedJobs > 0
                ? (double.parse(_totalPaidCustody) / _completedJobs)
                    .toStringAsFixed(1)
                : '0';
          } else {
            // Default to empty if earnings API not available
            _custodyPayments = [];
            _transactions = [];
          }
        });
      }

      if (kDebugMode) {
        print('=== CUSTODY DATA LOADED ===');
        print('Completed jobs: $_completedJobs');
        print('Customer rating: $_customerRating');
        print('Pending custody: $_custodyBalance');
        print('Custody payments count: ${_custodyPayments.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('=== ERROR LOADING CUSTODY DATA ===');
        print('Error: $e');
      }

      if (mounted) {
        String errorMessage = 'فشل تحميل بيانات العهدة';

        if (e.toString().contains('Unauthenticated')) {
          errorMessage = 'جلسة العمل منتهية. يرجى تسجيل الدخول مرة أخرى';
        } else if (e.toString().contains('could not be found')) {
          errorMessage = 'خدمة العهدة غير متوفرة حالياً';
        } else if (e.toString().contains('Unauthorized')) {
          errorMessage = 'غير مصرح لك بالوصول لهذه البيانات';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              onPressed: _loadCustodyData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  void _handleTransactionTap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsBottomSheet(),
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري تصدير البيانات...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'العهدة والإحصائيات',
        style: CustomAppBarStyle.standard,
        automaticallyImplyLeading: false, // إزالة زر الرجوع للفني
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications-screen');
                },
              ),
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
                    '2',
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
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleExport,
          ),
          SizedBox(width: 2.w),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'العهدة والإحصائيات'),
            Tab(text: 'سجل المدفوعات'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCustodyData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEarningsTab(),
            _buildWithdrawalsTab(),
          ],
        ),
      ),
      bottomNavigationBar: TechnicianBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
        },
        style: CustomBottomBarStyle.floating,
        availableJobsCount: _availableJobsCount,
      ),
    );
  }

  Widget _buildEarningsTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8FAFC), // Very light gray
            const Color(0xFFF1F5F9), // Light gray
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            EarningsHeaderWidget(
              custodyBalance: _custodyBalance,
              workWindow: _workWindow,
            ),
            TimePeriodSelectorWidget(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) {
                setState(() => _selectedPeriod = period);
              },
            ),
            EarningsSummaryCardsWidget(
              totalIncome: _totalPaidCustody,
              completedJobs: _completedJobs,
              averageJobValue: _averageCustodyPerJob,
              customerRating: _customerRating,
            ),
            EarningsChartWidget(
              chartData: _chartData,
              period: _selectedPeriod,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                  child: Text(
                    'سجل دفعات العهدة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _handleFilter,
                  icon: CustomIconWidget(
                    iconName: 'filter_list',
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  label: Text(
                    'تصفية',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            TransactionHistoryWidget(
              transactions: _transactions,
              onTransactionTap: _handleTransactionTap,
            ),
            QuickStatsWidget(
              weeklyGoalProgress: _weeklyGoalProgress,
              topServiceCategory: _topServiceCategory,
              peakEarningHours: _peakEarningHours,
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          CustodyPaymentHistoryWidget(custodyPayments: _custodyPayments),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsBottomSheet() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'تفاصيل المعاملة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          _buildDetailRow('الرسوم الأساسية', '150 د.ل'),
          _buildDetailRow('المكافآت', '20 د.ل'),
          _buildDetailRow('خصم العمولة', '-15 د.ل'),
          Divider(height: 3.h),
          _buildDetailRow(
            'صافي الدفع',
            '155 د.ل',
            isTotal: true,
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
              ),
              child: const Text('إغلاق'),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isTotal
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isTotal
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    final theme = Theme.of(context);
    String selectedCategory = 'الكل';
    String selectedStatus = 'الكل';

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'تصفية المعاملات',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'فئة الخدمة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: ['الكل', 'سباكة', 'كهرباء', 'نجارة', 'تكييف']
                    .map((category) {
                  final isSelected = selectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        selectedCategory = category;
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 2.h),
              Text(
                'حالة الدفع',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Wrap(
                spacing: 2.w,
                runSpacing: 1.h,
                children: ['الكل', 'مدفوع', 'قيد الانتظار'].map((status) {
                  final isSelected = selectedStatus == status;
                  return FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() {
                        selectedStatus = status;
                      });
                    },
                    backgroundColor: theme.colorScheme.surface,
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.2),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          selectedCategory = 'الكل';
                          selectedStatus = 'الكل';
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('إعادة تعيين'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم تطبيق التصفية'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('تطبيق'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}
