import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/api_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../technician_home_screen/widgets/empty_jobs_widget.dart';

class TechnicianJobsScreen extends StatefulWidget {
  const TechnicianJobsScreen({super.key});

  @override
  State<TechnicianJobsScreen> createState() => _TechnicianJobsScreenState();
}

class _TechnicianJobsScreenState extends State<TechnicianJobsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _currentBottomIndex = 1; // Jobs tab

  List<Map<String, dynamic>> _jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      // Use the specific endpoint for technician assigned orders
      final response = await _apiService.getTechnicianAssignedOrders();

      List<dynamic> items = [];

      // Handle different response formats
      if (response['requests'] is List) {
        items = response['requests'] as List<dynamic>;
      } else if (response['data'] is List) {
        items = response['data'] as List<dynamic>;
      } else if (response is List) {
        items = response as List<dynamic>;
      }

      _jobs = items.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return m;
      }).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل تحميل الطلبات: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadJobs();
  }

  void _onJobTap(Map<String, dynamic> job) {
    Navigator.pushNamed(
      context,
      '/job-details-screen',
      arguments: job,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: TechnicianAppBar(
        title: 'الطلبات',
        notificationCount: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
            : _jobs.isEmpty
                ? const EmptyJobsWidget(isAvailable: true)
                : ListView.separated(
                    padding: EdgeInsets.all(4.w),
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      final status = (job['status'] ?? '').toString();
                      final bool isFinished = status == 'completed';

                      return ListTile(
                        onTap: () => _onJobTap(job),
                        tileColor:
                            theme.colorScheme.surface.withValues(alpha: 0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          job['category']?.toString() ??
                              job['service_type']?.toString() ??
                              'خدمة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 0.5.h),
                            Text(
                              job['description']?.toString() ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              status,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isFinished
                                    ? const Color(0xFF10B981)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        trailing: CustomIconWidget(
                          iconName: 'chevron_left',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
                    itemCount: _jobs.length,
                  ),
      ),
      bottomNavigationBar: TechnicianBottomBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() => _currentBottomIndex = index);
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/technician-home-screen');
          }
        },
        availableJobsCount: _jobs.length,
      ),
    );
  }
}
