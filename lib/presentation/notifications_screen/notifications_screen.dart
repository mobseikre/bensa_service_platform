import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = response['data'] ?? [];
          _isLoading = false;
        });

        // Show success message if notifications are loaded
        if (_notifications.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم تحميل ${_notifications.length} إشعار'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show detailed error information in debug mode
        String errorMessage = 'فشل تحميل الإشعارات';
        if (e.toString().contains('ApiException')) {
          errorMessage = e.toString().replaceAll('ApiException: ', '');
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'لا يمكن الاتصال بالخادم. تأكد من الاتصال بالإنترنت';
        } else if (e.toString().contains('TimeoutException')) {
          errorMessage = 'انتهت مهلة الاتصال. حاول مرة أخرى';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: _loadNotifications,
            ),
          ),
        );

        // Print detailed error in debug mode
        debugPrint('=== NOTIFICATIONS ERROR ===');
        debugPrint('Error: $e');
        debugPrint('Error type: ${e.runtimeType}');
      }
    }
  }

  Future<void> _markAsRead(dynamic notification) async {
    if (notification['read_at'] != null) {
      // Already read, no need to do anything
      return;
    }

    try {
      await _apiService.markNotificationAsRead(notification['id']);

      setState(() {
        final index = _notifications.indexOf(notification);
        if (index != -1) {
          _notifications[index] = {
            ...notification,
            'read_at': DateTime.now().toIso8601String(),
          };
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحديث حالة الإشعار')),
        );
      }
    }
  }

  Future<void> _testApiConnection() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('اختبار الاتصال مع الخادم...'),
          ],
        ),
      ),
    );

    try {
      final result = await _apiService.testConnection();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result['success'] ? 'نجح الاتصال' : 'فشل الاتصال'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message']),
                const SizedBox(height: 8),
                Text('الخادم: ${result['baseUrl']}',
                    style: const TextStyle(fontSize: 12)),
                if (result['status'] != null)
                  Text('حالة الاستجابة: ${result['status']}',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
              if (!result['success'])
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _runFullDiagnostics();
                  },
                  child: const Text('تشخيص مفصل'),
                ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في الاختبار'),
            content: Text('حدث خطأ أثناء اختبار الاتصال:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _runFullDiagnostics() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري إجراء تشخيص شامل...'),
            SizedBox(height: 8),
            Text('قد يستغرق هذا بضع ثوان', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final result = await _apiService.getApiStatus();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تشخيص شامل للـ API'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الخادم: ${result['baseUrl']}'),
                    Text(
                        'الحالة العامة: ${result['summary']['overall_status']}'),
                    Text(
                        'معدل النجاح: ${(result['summary']['success_rate'] * 100).toStringAsFixed(1)}%'),
                    const Divider(),
                    const Text('تفاصيل الاختبارات:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...result['tests'].entries.map((entry) {
                      final test = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              test['success']
                                  ? Icons.check_circle
                                  : Icons.error,
                              color:
                                  test['success'] ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${entry.key}: ${test['message']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('خطأ في التشخيص'),
            content: Text('حدث خطأ أثناء التشخيص الشامل:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'الإشعارات',
        style: CustomAppBarStyle.standard,
        onBackPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.network_check),
            onPressed: _testApiConnection,
            tooltip: 'اختبار الاتصال مع الخادم',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState(theme)
              : _buildNotificationsList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'notifications_none',
            size: 20.w,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            'لا توجد إشعارات حالياً',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 8.w),
            child: ElevatedButton(
              onPressed: () async {
                await _loadNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'تفعيل تحميل الإشعارات',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(theme, notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(ThemeData theme, dynamic notification) {
    final bool isRead = notification['read_at'] != null;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _markAsRead(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: isRead
                        ? theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.1)
                        : theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: 'notifications',
                      size: 6.w,
                      color: isRead
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'تنبيه',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight:
                                    isRead ? FontWeight.w500 : FontWeight.bold,
                                color: isRead
                                    ? theme.colorScheme.onSurfaceVariant
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 2.w,
                              height: 2.w,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        notification['message'] ?? notification['body'] ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _formatRelativeTime(notification['created_at']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return 'منذ ${difference.inDays} يوم';
      }
    } catch (e) {
      return '';
    }
  }
}
