import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/app_export.dart';
import './widgets/otp_input_widget.dart';
import './widgets/resend_button_widget.dart';
import './widgets/timer_widget.dart';
import './widgets/verify_button_widget.dart';

/// OTP Verification Screen for email-based verification
/// Handles 6-digit code input with timer and resend functionality
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  // Controllers and state
  final TextEditingController _otpController = TextEditingController();
  Timer? _timer;
  int _remainingSeconds = 120; // 2 minutes
  bool _isVerifying = false;
  bool _isResending = false;
  bool _hasError = false;
  String? _errorMessage;
  late AnimationController _shakeController;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;

  // Data from previous screen
  String? _registeredEmail;
  String? _userRole;
  bool _requiresApproval = false;
  int _retryAttempts = 0;
  final int _maxRetryAttempts = 3;
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Initialize notifications and load arguments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
      _loadArguments();
      _startTimer();
    });
  }

  /// Load arguments from navigation
  void _loadArguments() {
    if (!mounted) return;
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        final email = args['email'] as String?;
        if (email != null && email.isNotEmpty) {
          setState(() {
            _registeredEmail = email;
            _userRole = args['role'] as String?;
            _requiresApproval = args['requires_approval'] as bool? ?? false;
          });
          return;
        }
      }
      // If no valid arguments, show error and go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خطأ في البيانات. الرجاء المحاولة مرة أخرى'),
              backgroundColor: Color(0xFFEF4444),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading OTP arguments: $e');
      }
      // On error, go back to previous screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Initialize local notifications for timer expiration
  Future<void> _initializeNotifications() async {
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin?.initialize(initSettings);
    } catch (e) {
      // Silently fail - notifications are not critical
      if (kDebugMode) {
        print('Failed to initialize notifications: $e');
      }
    }
  }

  /// Start countdown timer
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 120;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _showExpirationNotification();
      }
    });
  }

  /// Show notification when OTP expires
  Future<void> _showExpirationNotification() async {
    if (_notificationsPlugin == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'otp_channel',
        'OTP Notifications',
        channelDescription: 'Notifications for OTP expiration',
        importance: Importance.high,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin!.show(
        0,
        'انتهت صلاحية رمز التحقق',
        'يرجى طلب رمز جديد للمتابعة',
        details,
      );
    } catch (e) {
      // Silently fail - notifications are not critical
      if (kDebugMode) {
        print('Failed to show notification: $e');
      }
    }
  }

  /// Handle OTP verification
  Future<void> _verifyOtp(String otp) async {
    if (_registeredEmail == null) {
      _showError('خطأ في البيانات. الرجاء المحاولة مرة أخرى');
      return;
    }

    if (_remainingSeconds <= 0) {
      _showError('انتهت صلاحية الرمز. يرجى طلب رمز جديد');
      return;
    }

    if (_retryAttempts >= _maxRetryAttempts) {
      _showError('تم تجاوز الحد الأقصى من المحاولات. يرجى طلب رمز جديد');
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Call backend API to verify OTP
      await _apiService.verifyOtp(
        email: _registeredEmail!,
        otp: otp,
      );

      // Success - show celebration and navigate
      HapticFeedback.heavyImpact();
      _showSuccessAnimation();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Navigate based on role and approval status
      if (_requiresApproval && _userRole == 'technician') {
        // Show approval pending message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم التحقق بنجاح! حسابك قيد المراجعة من قبل الإدارة'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
          ),
        );
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/login-screen');
      } else {
        // Navigate to location permission screen with role
        Navigator.pushReplacementNamed(
          context,
          '/location-permission-screen',
          arguments: {
            'role': _userRole ?? 'customer',
            'userRole': _userRole ?? 'customer',
          },
        );
      }
    } on ApiException catch (e) {
      // Error - show shake animation
      _retryAttempts++;
      HapticFeedback.vibrate();
      _shakeController.forward().then((_) => _shakeController.reverse());

      String errorMessage = e.message;
      if (e.message.contains('expired') || e.message.contains('انتهت')) {
        errorMessage = 'انتهت صلاحية الرمز. يرجى طلب رمز جديد';
      } else if (e.message.contains('Incorrect') || e.message.contains('غير صحيح')) {
        errorMessage = _retryAttempts >= _maxRetryAttempts
            ? 'تم تجاوز الحد الأقصى من المحاولات'
            : 'الرمز غير صحيح. المحاولات المتبقية: ${_maxRetryAttempts - _retryAttempts}';
      }

      setState(() {
        _isVerifying = false;
        _hasError = true;
        _errorMessage = errorMessage;
      });

      _otpController.clear();
    } catch (e) {
      _retryAttempts++;
      HapticFeedback.vibrate();
      _shakeController.forward().then((_) => _shakeController.reverse());

      setState(() {
        _isVerifying = false;
        _hasError = true;
        _errorMessage = 'حدث خطأ أثناء التحقق. الرجاء المحاولة مرة أخرى';
      });

      _otpController.clear();
    }
  }

  /// Handle resend OTP
  Future<void> _resendOtp() async {
    if (_registeredEmail == null) {
      _showError('خطأ في البيانات. الرجاء المحاولة مرة أخرى');
      return;
    }

    setState(() {
      _isResending = true;
      _hasError = false;
      _errorMessage = null;
      _retryAttempts = 0;
    });

    try {
      // Call backend API to resend OTP
      await _apiService.resendOtp(email: _registeredEmail!);

      if (mounted) {
        setState(() {
          _isResending = false;
        });

        _startTimer();
        _otpController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إرسال رمز جديد إلى $_registeredEmail'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });

        _showError('فشل إعادة إرسال الرمز. الرجاء المحاولة مرة أخرى');
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    HapticFeedback.vibrate();
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  /// Show success animation
  void _showSuccessAnimation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ).animate().scale(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final isOtpComplete = _otpController.text.length == 6;
      final canResend = _remainingSeconds <= 0 && !_isResending;

      // Show loading if email is not loaded yet
      if (_registeredEmail == null) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: CustomAppBar(
            style: CustomAppBarStyle.minimal,
            onBackPressed: () {
              Navigator.pop(context);
            },
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        style: CustomAppBarStyle.minimal,
        onBackPressed: () {
          _otpController.clear();
          _timer?.cancel();
          Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header section
              CustomIconWidget(
                iconName: 'mark_email_read',
                color: theme.colorScheme.primary,
                size: 64,
              ).animate().fadeIn(duration: 400.ms).scale(),

              SizedBox(height: 24),

              Text(
                'تحقق من بريدك الإلكتروني',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

              SizedBox(height: 12),

              Text(
                'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              SizedBox(height: 8),

              Text(
                _registeredEmail ?? 'example@email.com',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              SizedBox(height: 48),

              // OTP Input
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = _shakeController.value *
                      10 *
                      ((_shakeController.value * 4).floor() % 2 == 0 ? 1 : -1);
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: OtpInputWidget(
                  controller: _otpController,
                  onCompleted: _verifyOtp,
                  hasError: _hasError,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

              if (_hasError && _errorMessage != null) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'error',
                      color: theme.colorScheme.error,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).shake(),
              ],

              SizedBox(height: 32),

              // Timer
              TimerWidget(
                remainingSeconds: _remainingSeconds,
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

              SizedBox(height: 24),

              // Resend button
              ResendButtonWidget(
                isEnabled: canResend,
                isLoading: _isResending,
                onPressed: _resendOtp,
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

              SizedBox(height: 48),

              // Verify button
              VerifyButtonWidget(
                isEnabled: isOtpComplete && !_isVerifying,
                isLoading: _isVerifying,
                onPressed: () => _verifyOtp(_otpController.text),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),

              SizedBox(height: 24),

              // Help text
              Text(
                'لم تستلم الرمز؟ تحقق من مجلد البريد العشوائي',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      // If there's an error building the screen, show a simple error screen
      if (kDebugMode) {
        print('Error building OTP screen: $e');
        print('Stack trace: $stackTrace');
      }
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          style: CustomAppBarStyle.minimal,
          onBackPressed: () {
            Navigator.pop(context);
          },
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل الصفحة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'الرجاء المحاولة مرة أخرى',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
