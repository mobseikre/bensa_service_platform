import 'dart:io';
import 'package:flutter/foundation.dart';

/// Platform-aware API configuration
/// Automatically detects the platform and uses the correct base URL
///
/// For Herd users:
/// - Web (Chrome): Uses http://localhost/api
/// - iOS Simulator: Uses http://localhost/api
/// - Android Emulator: Uses http://10.0.2.2/api (special emulator IP)
///
/// If localhost doesn't work with Herd, you may need to:
/// 1. Configure Herd to respond to localhost, OR
/// 2. Use your machine's IP address (e.g., http://192.168.1.100/api)
///    To find your IP: ifconfig | grep "inet " | grep -v 127.0.0.1
class ApiConfig {
  // Herd/Laravel local development URLs
  static const String _herdUrl = 'https://bensa.test/api';
  static const String _localhostUrl = 'http://localhost:8000/api';

  // Android Emulator special IP (maps to host machine's localhost)
  // Note: 10.0.2.2 is the special IP that Android emulator uses to access host machine
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000/api';

  // Production URL (uncomment when deploying)
  // static const String _productionUrl = 'https://bensa-production.up.railway.app/api';

  // Manual override (set this if localhost doesn't work with your Herd setup)
  // ✅ UNIFIED SETUP: Works for both Chrome and iOS Simulator
  // Run: cd ~/Bensa && php artisan serve --host=0.0.0.0 --port=8000
  // Current IP: 172.20.10.2 (updated automatically when network changes)
  static const String? _manualOverride = 'http://172.20.10.2:8000/api';
  // static const String? _manualOverride = 'http://172.20.10.2:8000/api';

  /// Get the appropriate base URL based on the current platform
  static String get baseUrl {
    // Manual override (if set, use it for all platforms)
    if (_manualOverride != null) {
      if (kDebugMode) {
        debugPrint('🔧 Using manual override: $_manualOverride');
      }
      return _manualOverride!;
    }

    // Production mode - uncomment when deploying
    // if (kReleaseMode) {
    //   return _productionUrl;
    // }

    // Web platform (Chrome, Safari, etc.)
    if (kIsWeb) {
      // For web, use localhost (bensa.test won't resolve in browsers)
      if (kDebugMode) {
        debugPrint('🌐 Platform: Web (Chrome) - Using localhost');
      }
      return _localhostUrl;
    }

    // iOS Platform
    if (Platform.isIOS) {
      // iOS Simulator can access localhost directly
      if (kDebugMode) {
        debugPrint('📱 Platform: iOS Simulator - Using localhost');
      }
      return _localhostUrl;
    }

    // Android Platform
    if (Platform.isAndroid) {
      // Android Emulator uses special IP to access host machine
      if (kDebugMode) {
        debugPrint('🤖 Platform: Android Emulator - Using 10.0.2.2');
      }
      return _androidEmulatorUrl;
    }

    // Fallback for other platforms (macOS, Linux, Windows)
    if (kDebugMode) {
      debugPrint('💻 Platform: Desktop - Using localhost');
    }
    return _localhostUrl;
  }

  /// Get the Herd URL (for reference/testing)
  static String get herdUrl => _herdUrl;

  /// Check if running in development mode
  static bool get isDevelopment => kDebugMode;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
}
