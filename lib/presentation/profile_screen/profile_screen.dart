import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import '../../main.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/user_info_section_widget.dart';

/// Profile Screen for comprehensive account management
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentBottomNavIndex = 2; // Profile tab (3-item bar)
  final ApiService _apiService = ApiService();
  bool _didLoadRouteArgs = false;
  bool _isLoadingUserData = false;

  // User data - will be loaded from route arguments or API
  Map<String, dynamic> _userData = {
    "name": "العميل",
    "email": "",
    "phone": "",
    "role": "customer", // Default to customer
    "profileImage": null,
    "serviceCategories": [],
    "experienceLevel": "",
    "emailVerified": false,
    "phoneVerified": false,
  };
  int _availableJobsCount = 0;

  // No longer needed: _selectedLanguage and _isDarkMode are handled by MyApp

  @override
  void initState() {
    super.initState();
    // Reset data to ensure we don't show old user data
    _resetUserData();
    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  /// Reset user data to defaults
  void _resetUserData() {
    setState(() {
      _userData = {
        "name": "العميل",
        "email": "",
        "phone": "",
        "role": "customer",
        "profileImage": null,
        "serviceCategories": [],
        "experienceLevel": "",
        "emailVerified": false,
        "phoneVerified": false,
      };
      _didLoadRouteArgs = false;
    });
  }

  /// Load user data from route arguments first, then fetch from API if needed
  Future<void> _loadUserData() async {
    if (_didLoadRouteArgs) return;

    // Always fetch from API first to get the most up-to-date data
    // This ensures we get fresh data for the current logged-in user
    await _fetchUserDataFromAPI();

    // Only use route arguments as fallback if API fails
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      // Only use route arguments if we don't have complete data from API
      if ((_userData["email"] as String?)?.isEmpty != false ||
          (_userData["phone"] as String?)?.isEmpty != false) {
        setState(() {
          // Get user data from route arguments as fallback
          final userName =
              args['userName'] as String? ?? args['name'] as String?;
          final userEmail = args['email'] as String?;
          final userPhone = args['phone'] as String?;
          final userRole =
              args['role'] as String? ?? args['userRole'] as String?;

          if (userName != null &&
              userName.isNotEmpty &&
              (_userData["name"] as String?)?.isEmpty != false) {
            _userData["name"] = userName;
          }
          if (userEmail != null &&
              userEmail.isNotEmpty &&
              (_userData["email"] as String?)?.isEmpty != false) {
            _userData["email"] = userEmail;
          }
          if (userPhone != null &&
              userPhone.isNotEmpty &&
              (_userData["phone"] as String?)?.isEmpty != false) {
            _userData["phone"] = userPhone;
          }
          if (userRole != null && userRole.isNotEmpty) {
            _userData["role"] = userRole;
          }

          _userData["profileImage"] =
              args['profileImage'] as String? ?? _userData["profileImage"];

          // Set current index based on role
          if (_userData["role"] == "technician") {
            _currentBottomNavIndex = 3;
            // Set technician-specific data from arguments
            _userData["serviceCategories"] =
                args['serviceCategories'] as List? ??
                    _userData["serviceCategories"];
            _userData["experienceLevel"] = args['experienceLevel'] as String? ??
                _userData["experienceLevel"];
          } else {
            _currentBottomNavIndex = 2;
          }
        });
      }
    }

    _didLoadRouteArgs = true;
  }

  /// Fetch complete user data from API
  Future<void> _fetchUserDataFromAPI() async {
    if (_isLoadingUserData) return;

    setState(() {
      _isLoadingUserData = true;
    });

    try {
      final response = await _apiService.getCurrentUser();

      if (mounted) {
        // Handle different response formats
        final responseMap = Map<String, dynamic>.from(response);
        Map<String, dynamic> user;
        if (responseMap.containsKey('user') &&
            responseMap['user'] is Map<String, dynamic>) {
          user = responseMap['user'] as Map<String, dynamic>;
        } else if (responseMap.containsKey('data') &&
            responseMap['data'] is Map<String, dynamic>) {
          user = responseMap['data'] as Map<String, dynamic>;
        } else {
          user = responseMap;
        }

        setState(() {
          // Update all user data from API - always update if we have a value
          final nameValue = user['name'] as String? ??
              user['userName'] as String? ??
              user['full_name'] as String?;
          if (nameValue != null && nameValue.isNotEmpty) {
            _userData["name"] = nameValue;
          }

          final emailValue = user['email'] as String?;
          if (emailValue != null && emailValue.isNotEmpty) {
            _userData["email"] = emailValue;
          }

          final phoneValue =
              user['phone'] as String? ?? user['phone_number'] as String?;
          if (phoneValue != null && phoneValue.isNotEmpty) {
            _userData["phone"] = phoneValue;
          }
          if (user['role'] != null || responseMap['active_role'] != null) {
            _userData["role"] = user['role'] as String? ??
                responseMap['active_role'] as String? ??
                _userData["role"];

            // Update bottom nav index based on role
            if (_userData["role"] == "technician") {
              _currentBottomNavIndex = 3;
            } else {
              _currentBottomNavIndex = 2;
            }
          }
          if (user['profile_image'] != null ||
              user['avatar'] != null ||
              user['profileImage'] != null) {
            _userData["profileImage"] = user['profile_image'] as String? ??
                user['avatar'] as String? ??
                user['profileImage'] as String? ??
                _userData["profileImage"];
          }
          if (user['email_verified'] != null || user['emailVerified'] != null) {
            _userData["emailVerified"] = user['email_verified'] as bool? ??
                user['emailVerified'] as bool? ??
                _userData["emailVerified"];
          }
          if (user['phone_verified'] != null || user['phoneVerified'] != null) {
            _userData["phoneVerified"] = user['phone_verified'] as bool? ??
                user['phoneVerified'] as bool? ??
                _userData["phoneVerified"];
          }

          // Technician-specific data
          if (_userData["role"] == "technician") {
            if (user['service_categories'] != null ||
                user['serviceCategories'] != null) {
              final rawServiceCategories =
                  user['service_categories'] ?? user['serviceCategories'];

              // Handle backend sending list OR JSON/string representation gracefully
              List<String> parsedCategories = [];
              if (rawServiceCategories is List) {
                parsedCategories =
                    rawServiceCategories.map((e) => e.toString()).toList();
              } else if (rawServiceCategories is String &&
                  rawServiceCategories.trim().isNotEmpty) {
                try {
                  final decoded = jsonDecode(rawServiceCategories);
                  if (decoded is List) {
                    parsedCategories =
                        decoded.map((e) => e.toString()).toList();
                  } else if (decoded is Map) {
                    parsedCategories =
                        decoded.values.map((e) => e.toString()).toList();
                  }
                } catch (_) {
                  parsedCategories = rawServiceCategories
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                }
              }

              if (parsedCategories.isNotEmpty) {
                _userData["serviceCategories"] = parsedCategories;
              }
            }
            if (user['experience_level'] != null ||
                user['experienceLevel'] != null) {
              _userData["experienceLevel"] =
                  user['experience_level'] as String? ??
                      user['experienceLevel'] as String? ??
                      _userData["experienceLevel"];
            }
          }
        });

        // Fetch technician stats for bottom bar badge
        if (_userData["role"] == "technician") {
          try {
            final stats = await _apiService.getTechnicianStats();
            if (mounted) {
              setState(() {
                _availableJobsCount = stats['available_jobs_count'] ?? 0;
              });
            }
          } catch (e) {
            debugPrint('Failed to fetch technician stats on profile: $e');
          }
        }

        // Debug print to see what we got
        if (kDebugMode) {
          debugPrint('=== PROFILE DATA LOADED ===');
          debugPrint('Name: ${_userData["name"]}');
          debugPrint('Email: ${_userData["email"]}');
          debugPrint('Phone: ${_userData["phone"]}');
          debugPrint('Role: ${_userData["role"]}');
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error to user
        debugPrint('Failed to fetch user data: $e');
        final errorMessage = e.toString().contains('Unauthenticated')
            ? 'غير مصرح لك. يرجى تسجيل الدخول مرة أخرى'
            : 'فشل تحميل بيانات المستخدم: ${e.toString()}';

        if (kDebugMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                onPressed: () => _fetchUserDataFromAPI(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show loading indicator while fetching user data
    if (_isLoadingUserData &&
        (_userData["email"] == null || _userData["email"].toString().isEmpty)) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'الملف الشخصي',
          style: CustomAppBarStyle.standard,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'الملف الشخصي',
        style: CustomAppBarStyle.standard,
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/notifications-screen'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomIconWidget(
                  iconName: 'notifications',
                  size: 6.w,
                  color: theme.colorScheme.onSurface,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            ProfileHeaderWidget(
              profileImageUrl: _userData["profileImage"] as String?,
            ),

            SizedBox(height: 2.h),

            // User Information Section
            UserInfoSectionWidget(
              name: (_userData["name"] as String?)?.isNotEmpty == true
                  ? _userData["name"] as String
                  : 'العميل',
              email: (_userData["email"] as String?)?.isNotEmpty == true
                  ? _userData["email"] as String
                  : 'غير متوفر',
              phone: (_userData["phone"] as String?)?.isNotEmpty == true
                  ? _userData["phone"] as String
                  : 'غير متوفر',
              role: (_userData["role"] as String?)?.isNotEmpty == true
                  ? _userData["role"] as String
                  : 'customer',
              onEditName: () =>
                  _showEditDialog('الاسم', _userData["name"] as String? ?? ''),
              onEditEmail: () => _showEditDialog(
                  'البريد الإلكتروني', _userData["email"] as String? ?? ''),
              onEditPhone: () => _showEditDialog(
                  'رقم الهاتف', _userData["phone"] as String? ?? ''),
            ),

            SizedBox(height: 2.h),

            // Technician-specific information
            if (_userData["role"] == "technician") ...[
              _buildTechnicianInfoSection(theme),
              SizedBox(height: 2.h),
            ],

            // Account Settings Section
            SettingsSectionWidget(
              title: 'إعدادات الحساب',
              items: [
                SettingsItem(
                  icon: 'lock',
                  title: 'تغيير كلمة المرور',
                  subtitle: 'تحديث كلمة المرور الخاصة بك',
                  onTap: _handlePasswordChange,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Language & Preferences Section
            SettingsSectionWidget(
              title: 'اللغة والتفضيلات',
              items: [
                SettingsItem(
                  icon: 'language',
                  title: 'اللغة',
                  subtitle: Localizations.localeOf(context).languageCode == 'ar'
                      ? 'العربية'
                      : 'English',
                  onTap: _handleLanguageChange,
                ),
                SettingsItem(
                  icon: 'dark_mode',
                  title: 'الوضع الداكن',
                  subtitle: Theme.of(context).brightness == Brightness.dark
                      ? 'مفعل'
                      : 'معطل',
                  trailing: Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    onChanged: (value) {
                      MyApp.of(context).changeTheme(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Privacy & Security Section
            SettingsSectionWidget(
              title: 'الخصوصية والأمان',
              items: [
                SettingsItem(
                  icon: 'delete_forever',
                  title: 'حذف الحساب',
                  subtitle: 'حذف حسابك نهائياً',
                  iconColor: theme.colorScheme.error,
                  onTap: _handleAccountDeletion,
                ),
                SettingsItem(
                  icon: 'description',
                  title: 'الشروط والأحكام',
                  onTap: _handleTermsAndConditions,
                ),
                SettingsItem(
                  icon: 'privacy_tip',
                  title: 'سياسة الخصوصية',
                  onTap: _handlePrivacyPolicy,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Support Section
            SettingsSectionWidget(
              title: 'الدعم',
              items: [
                SettingsItem(
                  icon: 'help',
                  title: 'مركز المساعدة',
                  onTap: _handleHelpCenter,
                ),
                SettingsItem(
                  icon: 'contact_support',
                  title: 'اتصل بنا',
                  subtitle: 'support@bensa.ly',
                  onTap: _handleContactSupport,
                ),
                SettingsItem(
                  icon: 'info',
                  title: 'حول التطبيق',
                  subtitle: 'الإصدار 1.0.0',
                  onTap: _handleAboutApp,
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Logout Button
            _buildLogoutButton(theme),

            SizedBox(height: 4.h),

            // Bottom spacing to prevent overflow
            SizedBox(
              height: MediaQuery.of(context).padding.bottom + 100,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _userData["role"] == "customer"
            ? CustomerBottomBar(
                currentIndex: _currentBottomNavIndex,
                onTap: (index) {
                  setState(() => _currentBottomNavIndex = index);
                  // Navigate to customer screens
                  final args = ModalRoute.of(context)?.settings.arguments;
                  switch (index) {
                    case 0:
                      Navigator.pushNamed(
                        context,
                        '/customer-home-screen',
                        arguments: args,
                      );
                      break;
                    case 1:
                      Navigator.pushNamed(context, '/my-requests-screen');
                      break;
                    case 2:
                      // Already on profile
                      break;
                  }
                },
                style: CustomBottomBarStyle.floating,
              )
            : TechnicianBottomBar(
                currentIndex: _currentBottomNavIndex,
                onTap: (index) =>
                    setState(() => _currentBottomNavIndex = index),
                style: CustomBottomBarStyle.floating,
                availableJobsCount: _availableJobsCount,
              ),
      ),
    );
  }

  Widget _buildTechnicianInfoSection(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
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
            'معلومات الفني',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            theme,
            icon: 'build',
            label: 'فئات الخدمة',
            value: (_userData["serviceCategories"] as List).join(', '),
          ),
          SizedBox(height: 2.h),
          _buildInfoRow(
            theme,
            icon: 'star',
            label: 'مستوى الخبرة',
            value: _userData["experienceLevel"] as String,
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _handleCertificationUpload,
            icon: CustomIconWidget(
              iconName: 'upload_file',
              size: 5.w,
              color: theme.colorScheme.onPrimary,
            ),
            label: Text('رفع الشهادات'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: icon,
              size: 5.w,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: CustomIconWidget(
          iconName: 'logout',
          size: 5.w,
          color: theme.colorScheme.error,
        ),
        label: Text(
          'تسجيل الخروج',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, 6.h),
          side: BorderSide(color: theme.colorScheme.error, width: 1.5),
        ),
      ),
    );
  }

  // Handler methods
  void _showEditDialog(String field, String currentValue) {
    if (field != 'الاسم') return; // Only allow editing name

    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تعديل $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => _updateName(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateName(String newName) async {
    if (newName.isEmpty) return;

    Navigator.pop(context); // Close dialog

    setState(() {
      _isLoadingUserData = true;
    });

    try {
      await _apiService.updateProfile(name: newName);
      setState(() {
        _userData["name"] = newName;
        _isLoadingUserData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الاسم بنجاح')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تحديث الاسم: $e')),
        );
      }
    }
  }

  void _handlePasswordChange() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/change-password-screen');
  }

  void _handleLanguageChange() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                MyApp.of(context).changeLocale(const Locale('ar', 'SA'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              leading: Icon(
                Localizations.localeOf(context).languageCode == 'en'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                MyApp.of(context).changeLocale(const Locale('en', 'US'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccountDeletion() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد حذف الحساب'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف حسابك؟ هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoadingUserData = true;
              });

              try {
                await _apiService.deleteAccount();
                // Logout and go to splash
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/splash-screen',
                  (route) => false,
                );
              } catch (e) {
                setState(() {
                  _isLoadingUserData = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل حذف الحساب: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _handleTermsAndConditions() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح الشروط والأحكام'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handlePrivacyPolicy() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح سياسة الخصوصية'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleHelpCenter() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح مركز المساعدة'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleContactSupport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح صفحة الاتصال بالدعم'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleAboutApp() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حول التطبيق'),
        content: const Text(
          'منصة بنسة للخدمات\nالإصدار 1.0.0\n\nتطبيق شامل يربط العملاء بالفنيين المحترفين لتقديم خدمات الصيانة المنزلية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _handleCertificationUpload() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم فتح شاشة رفع الشهادات'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/splash-screen',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
