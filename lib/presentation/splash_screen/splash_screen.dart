import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';

/// Splash Screen - Branded app launch with initialization and role-based routing
///
/// Provides immersive full-screen launch experience while performing:
/// - JWT token validation
/// - User role detection
/// - Location permission status check
/// - Firebase initialization
///
/// Navigation Logic:
/// - Authenticated customers → Customer Home Screen
/// - Authenticated technicians → Technician Home Screen
/// - Unauthenticated users → Login Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showRetryButton = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization tasks (2-3 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Mock JWT token validation and role detection
      final bool isAuthenticated = await _validateToken();
      final String? userRole = await _getUserRole();

      if (!mounted) return;

      // Navigate based on authentication and role
      if (isAuthenticated && userRole != null) {
        if (userRole == 'customer') {
          Navigator.pushReplacementNamed(context, '/customer-home-screen');
        } else if (userRole == 'technician') {
          Navigator.pushReplacementNamed(context, '/technician-home-screen');
        } else {
          Navigator.pushReplacementNamed(context, '/login-screen');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login-screen');
      }
    } catch (e) {
      // Show retry button after 5 seconds on error
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _showRetryButton = true;
          _isInitializing = false;
        });
      }
    }
  }

  Future<bool> _validateToken() async {
    // Mock token validation - returns false for unauthenticated state
    await Future.delayed(const Duration(milliseconds: 500));
    return false; // Change to true to test authenticated flow
  }

  Future<String?> _getUserRole() async {
    // Mock role detection - returns null for unauthenticated
    await Future.delayed(const Duration(milliseconds: 300));
    return null; // Return 'customer' or 'technician' to test role-based routing
  }

  void _handleRetry() {
    setState(() {
      _showRetryButton = false;
      _isInitializing = true;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: theme.colorScheme.primary,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated Logo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildLogo(theme),
              ),

              SizedBox(height: 8.h),

              // App Name
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  );
                },
                child: Text(
                  'بنسا',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),

              SizedBox(height: 2.h),

              // Tagline
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value * 0.9,
                    child: child,
                  );
                },
                child: Text(
                  'منصة الخدمات المنزلية',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),

              const Spacer(flex: 2),

              // Loading Indicator or Retry Button
              _isInitializing
                  ? _buildLoadingIndicator(theme)
                  : _showRetryButton
                      ? _buildRetryButton(theme)
                      : const SizedBox.shrink(),

              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      width: 35.w,
      height: 35.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'home_repair_service',
          color: theme.colorScheme.primary,
          size: 18.w,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 10.w,
          height: 10.w,
          child: CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'جاري التحميل...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w400,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildRetryButton(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'فشل الاتصال',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          textDirection: TextDirection.rtl,
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: _handleRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'إعادة المحاولة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
