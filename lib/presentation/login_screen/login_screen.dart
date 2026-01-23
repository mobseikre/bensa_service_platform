import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/notification_service.dart';

/// Login screen for existing users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Validation states
  String? _phoneError;
  String? _passwordError;

  final _apiService = ApiService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _phoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _phoneError == null &&
        _passwordError == null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    final phoneRegex = RegExp(r'^[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'رقم الهاتف يجب أن يكون 9 أرقام';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء إكمال جميع الحقول المطلوبة'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        phone: '+218${_phoneController.text.trim()}',
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Initialize Notification Service to sync FCM token now that we are authenticated
      try {
        await NotificationService().initialize();
        if (kDebugMode) {
          print('FCM Token synced after login');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to sync FCM token after login: $e');
        }
      }

      // Navigate based on user role
      final user = response['user'] as Map<String, dynamic>?;
      // Check multiple possible role fields
      final userRole = response['active_role'] as String? ??
          response['role'] as String? ??
          user?['role'] as String? ??
          user?['user_type'] as String? ??
          user?['userRole'] as String?;

      // Debug print to see what role we got
      if (kDebugMode) {
        print('=== LOGIN ROLE DETECTION ===');
        print('active_role: ${response['active_role']}');
        print('response role: ${response['role']}');
        print('user role: ${user?['role']}');
        print('user_type: ${user?['user_type']}');
        print('Final userRole: $userRole');
        print('User data: $user');
      }

      if (userRole?.toLowerCase() == 'technician') {
        // Navigate to technician home screen
        Navigator.pushReplacementNamed(
          context,
          '/technician-home-screen',
          arguments: {
            'userName': user?['name'],
            'email': user?['email'],
            'phone': user?['phone'],
            'role': 'technician',
            'userRole': 'technician',
          },
        );
      } else if (userRole?.toLowerCase() == 'customer' || userRole == null) {
        // Default to customer if role is customer or null
        Navigator.pushReplacementNamed(
          context,
          '/customer-home-screen',
          arguments: {
            'userName': user?['name'],
            'email': user?['email'],
            'phone': user?['phone'],
            'role': 'customer',
            'userRole': 'customer',
            // Fallbacks for location-related fields
            'currentLocation': user?['city'] ??
                user?['address'] ??
                user?['location'] ??
                'طرابلس، ليبيا',
          },
        );
      } else {
        // Unknown role - default to customer but log warning
        if (kDebugMode) {
          print('WARNING: Unknown role "$userRole", defaulting to customer');
        }
        Navigator.pushReplacementNamed(
          context,
          '/customer-home-screen',
          arguments: {
            'userName': user?['name'],
            'email': user?['email'],
            'phone': user?['phone'],
            'role': 'customer',
            'userRole': 'customer',
            'currentLocation': user?['city'] ??
                user?['address'] ??
                user?['location'] ??
                'طرابلس، ليبيا',
          },
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      String errorMessage = e.message;

      // Handle specific error messages
      if (e.statusCode == 403 && e.message.contains('معتمد')) {
        errorMessage = 'حساب غير معتمد. يمكنك تسجيل الدخول كعميل';
      } else if (e.statusCode == 401) {
        errorMessage = 'رقم الهاتف أو كلمة المرور غير صحيحة';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تسجيل الدخول. الرجاء المحاولة مرة أخرى'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              _buildHeader(theme),
              SizedBox(height: 4.h),
              _buildLoginForm(theme),
              SizedBox(height: 3.h),
              _buildLoginButton(theme),
              SizedBox(height: 2.h),
              _buildRegisterLink(theme),
              SizedBox(height: 3.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'login',
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'تسجيل الدخول',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'أدخل بياناتك للدخول إلى حسابك',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhoneField(theme),
          SizedBox(height: 2.h),
          _buildPasswordField(theme),
        ],
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'رقم الهاتف',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '+218',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.bodyMedium,
                enabled: !_isLoading,
                maxLength: 9,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  setState(() => _phoneError = _validatePhone(value));
                },
                decoration: InputDecoration(
                  hintText: '912345678',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'phone',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  errorText: _phoneError,
                  errorMaxLines: 2,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كلمة المرور',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodyMedium,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() => _passwordError = _validatePassword(value));
          },
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'lock',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: CustomIconWidget(
                iconName: _isPasswordVisible ? 'visibility' : 'visibility_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
                HapticFeedback.selectionClick();
              },
            ),
            errorText: _passwordError,
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(ThemeData theme) {
    final isEnabled = _isFormValid();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !_isLoading ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor:
              theme.colorScheme.outline.withValues(alpha: 0.3),
          disabledForegroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                'تسجيل الدخول',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme) {
    return Center(
      child: TextButton(
        onPressed: _isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                Navigator.pushReplacementNamed(context, '/registration-screen');
              },
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'ليس لديك حساب؟ '),
              TextSpan(
                text: 'إنشاء حساب جديد',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
