import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/permission_buttons_widget.dart';
import './widgets/permission_explanation_widget.dart';
import './widgets/permission_illustration_widget.dart';

/// Location Permission Screen
/// Requests GPS access with clear Arabic explanations and role-specific permission requirements
/// Full-screen modal presentation prevents navigation until permission granted
class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;
  bool _permissionDenied = false;
  String _userRole = 'customer'; // Default role, should be passed from registration
  bool _didLoadRouteArgs = false;

  @override
  void initState() {
    super.initState();
    // Load role from route arguments first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoleFromArguments();
      _checkExistingPermission();
    });
  }

  /// Load user role from route arguments
  void _loadRoleFromArguments() {
    if (_didLoadRouteArgs) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final role = args['role'] as String? ??
                   args['userRole'] as String?;
      if (role != null && role.isNotEmpty) {
        setState(() {
          _userRole = role.toLowerCase();
        });
        if (kDebugMode) {
          print('=== LOCATION PERMISSION SCREEN ===');
          print('Loaded role from arguments: $_userRole');
        }
      }
    }
    _didLoadRouteArgs = true;
  }

  /// Check if location permission is already granted
  Future<void> _checkExistingPermission() async {
    // Make sure role is loaded first
    if (!_didLoadRouteArgs) {
      _loadRoleFromArguments();
      // Wait a bit for state to update
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final status = await Permission.location.status;
    if (status.isGranted) {
      _navigateToHome();
    }
  }

  /// Request location permission based on user role
  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    try {
      // Add haptic feedback
      HapticFeedback.lightImpact();

      PermissionStatus status;

      if (_userRole == 'technician') {
        // Technicians need always permission for background updates
        status = await Permission.locationAlways.request();

        // If always permission denied, try when-in-use as fallback
        if (status.isDenied || status.isPermanentlyDenied) {
          status = await Permission.locationWhenInUse.request();
        }
      } else {
        // Customers only need when-in-use permission
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isGranted) {
        // Permission granted - navigate to appropriate home screen
        _navigateToHome();
      } else if (status.isDenied) {
        // Permission denied - show alternative flow
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied - show settings option
        setState(() {
          _permissionDenied = true;
          _isLoading = false;
        });
        _showSettingsDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ أثناء طلب إذن الموقع');
    }
  }

  /// Navigate to appropriate home screen based on user role
  void _navigateToHome() {
    // Ensure role is loaded before navigating
    if (!_didLoadRouteArgs) {
      _loadRoleFromArguments();
    }

    if (kDebugMode) {
      print('=== NAVIGATING TO HOME ===');
      print('User role: $_userRole');
    }

    if (_userRole.toLowerCase() == 'technician') {
      Navigator.pushReplacementNamed(
        context,
        '/technician-home-screen',
        arguments: {
          'role': 'technician',
          'userRole': 'technician',
        },
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        '/customer-home-screen',
        arguments: {
          'role': 'customer',
          'userRole': 'customer',
        },
      );
    }
  }

  /// Show settings dialog for permanently denied permission
  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'إذن الموقع مطلوب',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.right,
        ),
        content: Text(
          'يرجى تفعيل إذن الموقع من إعدادات الجهاز للمتابعة',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_userRole == 'customer') {
                _showManualAddressOption();
              } else {
                _showRoleChangeOption();
              }
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// Show manual address entry option for customers
  void _showManualAddressOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إدخال العنوان يدوياً',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.right,
        ),
        content: Text(
          'يمكنك المتابعة بإدخال عنوانك يدوياً، ولكن قد لا تتمكن من استخدام بعض الميزات',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/customer-home-screen');
            },
            child: const Text('المتابعة'),
          ),
        ],
      ),
    );
  }

  /// Show role change suggestion for technicians
  void _showRoleChangeOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'إذن الموقع ضروري للفنيين',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.right,
        ),
        content: Text(
          'إذن الموقع ضروري لاستقبال طلبات العمل القريبة. هل تريد التسجيل كعميل بدلاً من ذلك؟',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _userRole = 'customer';
                _permissionDenied = false;
              });
            },
            child: const Text('التسجيل كعميل'),
          ),
        ],
      ),
    );
  }

  /// Show learn more bottom sheet
  void _showLearnMoreBottomSheet() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: 70.h,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 1.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'لماذا نحتاج إلى موقعك؟',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.right,
                    ),
                    SizedBox(height: 2.h),
                    _buildInfoSection(
                      theme,
                      'استخدام البيانات',
                      'نستخدم موقعك فقط لربطك بأقرب الفنيين المتاحين وتقديم خدمة أسرع وأفضل',
                      'location_on',
                    ),
                    _buildInfoSection(
                      theme,
                      'حماية الخصوصية',
                      'بياناتك محمية بالكامل ولا نشاركها مع أي طرف ثالث. يتم تخزين الموقع محلياً على جهازك',
                      'security',
                    ),
                    _buildInfoSection(
                      theme,
                      'التخزين المحلي',
                      'يتم حفظ موقعك على جهازك فقط ولا يتم إرساله إلى خوادمنا إلا عند طلب خدمة',
                      'storage',
                    ),
                    if (_userRole == 'technician') ...[
                      _buildInfoSection(
                        theme,
                        'تحديثات الموقع للفنيين',
                        'يتم تحديث موقعك كل 30 ثانية عند تفعيل حالة "متاح" لاستقبال طلبات العمل القريبة',
                        'update',
                      ),
                      _buildInfoSection(
                        theme,
                        'تأثير على الأرباح',
                        'الفنيون الذين يفعلون خدمة الموقع يحصلون على طلبات أكثر بنسبة 70% ويزيدون أرباحهم',
                        'trending_up',
                      ),
                    ],
                    SizedBox(height: 2.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('فهمت'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info section for bottom sheet
  Widget _buildInfoSection(
    ThemeData theme,
    String title,
    String description,
    String iconName,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'جاري طلب إذن الموقع...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Column(
                  children: [
                    SizedBox(height: 4.h),

                    // Illustration
                    PermissionIllustrationWidget(),

                    SizedBox(height: 4.h),

                    // Explanation
                    PermissionExplanationWidget(
                      userRole: _userRole,
                      permissionDenied: _permissionDenied,
                    ),

                    SizedBox(height: 4.h),

                    // Buttons
                    PermissionButtonsWidget(
                      isLoading: _isLoading,
                      permissionDenied: _permissionDenied,
                      userRole: _userRole,
                      onRequestPermission: _requestLocationPermission,
                      onLearnMore: _showLearnMoreBottomSheet,
                      onOpenSettings: () async {
                        await openAppSettings();
                      },
                      onManualAddress: _showManualAddressOption,
                      onChangeRole: _showRoleChangeOption,
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }
}
