import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// API Service for backend communication
class ApiService {
  // Platform-aware base URL - automatically detects Chrome, iOS Simulator, Android, etc.
  static String get baseUrl => ApiConfig.baseUrl;

  // PRODUCTION - Uncomment when deploying
  // static const String baseUrl = 'https://bensa-production.up.railway.app/api';

  static const String _tokenKey = 'auth_token';

  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add auth interceptor to include token in requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  /// Get stored authentication token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Store authentication token
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('Failed to save token: $e');
    }
  }

  /// Clear authentication token
  Future<void> _clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      debugPrint('Failed to clear token: $e');
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? city,
    String? nationality,
    List<String>? serviceCategories,
  }) async {
    try {
      // Backend expects: role, service_categories as array (Laravel auto-converts to JSON via model cast)
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'role':
            role, // Backend gets role from $request->input('role', 'customer')
      };

      if (role == 'technician') {
        if (city != null) data['city'] = city;
        if (nationality != null) data['nationality'] = nationality;
        if (serviceCategories != null && serviceCategories.isNotEmpty) {
          // Backend validation requires array, and User model has 'service_categories' => 'array' cast
          // Laravel will automatically convert array to JSON string when saving to database
          data['service_categories'] = serviceCategories;

          if (kDebugMode) {
            print('=== REGISTRATION DATA (matching backend) ===');
            print('Role: $role');
            print('Service categories (array): $serviceCategories');
            print(
                'Backend User model has array cast - will auto-convert to JSON');
          }
        }
      }

      if (kDebugMode) {
        print('=== REGISTRATION REQUEST ===');
        print('URL: $baseUrl/auth/register');
        print('Role being sent: $role');
        print('Full Data: $data');
      }

      final response = await _dio.post(
        '/auth/register',
        data: data,
      );

      if (kDebugMode) {
        print('=== REGISTRATION RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
        // Check if role was saved correctly
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          final user = responseData['user'] as Map<String, dynamic>?;
          final savedRole = user?['role'] ?? responseData['role'];
          final savedActiveRole =
              user?['active_role'] ?? responseData['active_role'];
          print('=== ROLE VERIFICATION ===');
          print('Requested role: $role');
          print('Saved role: $savedRole');
          print('Saved active_role: $savedActiveRole');
          if (savedRole != role) {
            print(
                '⚠️ WARNING: Role mismatch! Requested "$role" but got "$savedRole"');
          }
        }
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== REGISTRATION ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }

      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Registration failed: $e');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final data = {
        'phone': phone,
        'password': password,
      };

      if (kDebugMode) {
        print('=== LOGIN REQUEST ===');
        print('URL: $baseUrl/auth/login');
        print('Data: $data');
      }

      final response = await _dio.post(
        '/auth/login',
        data: data,
      );

      if (kDebugMode) {
        print('=== LOGIN RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Store authentication token if present
        final token = data['token'] as String? ??
            data['access_token'] as String? ??
            data['auth_token'] as String?;
        if (token != null) {
          await _saveToken(token);
          if (kDebugMode) {
            print('=== TOKEN SAVED ===');
          }
        }

        return data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== LOGIN ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }

      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Login failed: $e');
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final data = {
        'email': email,
        'otp': otp,
      };

      if (kDebugMode) {
        print('=== OTP VERIFICATION REQUEST ===');
        print('URL: $baseUrl/auth/verify-otp');
        print('Data: $data');
      }

      final response = await _dio.post(
        '/auth/verify-otp',
        data: data,
      );

      if (kDebugMode) {
        print('=== OTP VERIFICATION RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== OTP VERIFICATION ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }

      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('OTP verification failed: $e');
    }
  }

  /// Get service categories (requires authentication)
  /// Returns: {success: true, data: [...]}
  Future<Map<String, dynamic>> getServiceCategories() async {
    try {
      if (kDebugMode) {
        print('=== GET SERVICE CATEGORIES REQUEST ===');
        print('URL: $baseUrl/service-categories');
        final token = await _getToken();
        print('Has Auth Token: ${token != null}');
      }

      final response = await _dio.get('/service-categories');

      if (kDebugMode) {
        print('=== SERVICE CATEGORIES RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Response Type: ${response.data.runtimeType}');
        if (response.data is Map) {
          print('Response Keys: ${(response.data as Map).keys.toList()}');
          if ((response.data as Map).containsKey('data')) {
            final data = (response.data as Map)['data'];
            print('Data Type: ${data.runtimeType}');
            if (data is List) {
              print('Categories Count: ${data.length}');
            }
          }
        }
        print('Full Response: ${response.data}');
      }

      // Validate response format
      if (response.data is! Map<String, dynamic>) {
        throw ApiException(
            'Invalid response format: expected Map, got ${response.data.runtimeType}');
      }

      final responseData = response.data as Map<String, dynamic>;

      // Ensure response has 'data' key with array
      if (!responseData.containsKey('data')) {
        throw ApiException(
            'Response missing "data" key. Keys found: ${responseData.keys.toList()}');
      }

      if (responseData['data'] is! List) {
        throw ApiException(
            'Response "data" is not an array. Type: ${responseData['data'].runtimeType}');
      }

      return responseData;
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== SERVICE CATEGORIES ERROR (DioException) ===');
        print('Error Type: ${e.type}');
        print('Error Message: ${e.message}');
        print('Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        print('Request URL: ${e.requestOptions.uri}');
        print('Request Headers: ${e.requestOptions.headers}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== SERVICE CATEGORIES ERROR (Unexpected) ===');
        print('Error Type: ${e.runtimeType}');
        print('Error: $e');
      }
      throw ApiException('Failed to get service categories: $e');
    }
  }

  /// Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      if (kDebugMode) {
        print('=== GET CURRENT USER REQUEST ===');
        print('URL: $baseUrl/auth/me');
      }

      final response = await _dio.get('/auth/me');

      if (kDebugMode) {
        print('=== CURRENT USER RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== CURRENT USER ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get current user: $e');
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logout() async {
    try {
      if (kDebugMode) {
        print('=== LOGOUT REQUEST ===');
        print('URL: $baseUrl/auth/logout');
      }

      final response = await _dio.post('/auth/logout');

      if (kDebugMode) {
        print('=== LOGOUT RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      // Clear token on logout
      await _clearToken();

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        return {'success': true, 'message': 'Logged out successfully'};
      }
    } on DioException catch (e) {
      // Clear token even if logout fails
      await _clearToken();

      if (kDebugMode) {
        print('=== LOGOUT ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      // Clear token even if logout fails
      await _clearToken();

      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to logout: $e');
    }
  }

  /// Get cities (for registration)
  Future<Map<String, dynamic>> getCities() async {
    try {
      final response = await _dio.get('/public/cities');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get cities: $e');
    }
  }

  /// Get nationalities (for registration)
  Future<Map<String, dynamic>> getNationalities() async {
    try {
      final response = await _dio.get('/public/nationalities');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get nationalities: $e');
    }
  }

  /// Get all requests (my requests)
  Future<Map<String, dynamic>> getMyRequests({
    int? page,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response =
          await _dio.get('/requests', queryParameters: queryParams);

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get requests: $e');
    }
  }

  /// Get request details
  Future<Map<String, dynamic>> getRequestDetails(int requestId) async {
    try {
      final response = await _dio.get('/requests/$requestId');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get request details: $e');
    }
  }

  /// Create a new service request
  Future<Map<String, dynamic>> createRequest({
    required String category,
    required String description,
    required double locationLat,
    required double locationLng,
    String? address,
    String? subService,
    String? priority,
    DateTime? scheduledAt,
    String? paymentMethod,
  }) async {
    try {
      final data = {
        'category': category,
        'description': description,
        'location_lat': locationLat,
        'location_lng': locationLng,
        if (address != null) 'address': address,
        if (subService != null) 'sub_service': subService,
        if (priority != null) 'priority': priority,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        if (paymentMethod != null) 'payment_method': paymentMethod,
      };

      if (kDebugMode) {
        print('=== CREATE REQUEST ===');
        print('URL: $baseUrl/requests');
        print('Data: $data');
      }

      final response = await _dio.post('/requests', data: data);

      if (kDebugMode) {
        print('=== CREATE REQUEST RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== CREATE REQUEST ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== CREATE REQUEST UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to create request: $e');
    }
  }

  /// Get addresses
  Future<Map<String, dynamic>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get addresses: $e');
    }
  }

  /// Update address
  Future<Map<String, dynamic>> updateAddress({
    required int addressId,
    String? address,
    double? latitude,
    double? longitude,
    String? label,
    bool? isDefault,
  }) async {
    try {
      final data = {
        if (address != null) 'address': address,
        if (address != null) 'address_line': address,
        if (label != null) 'title': label,
        if (label != null) 'label': label,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isDefault != null) 'is_default': isDefault ? 1 : 0,
      };

      final response = await _dio.put('/addresses/$addressId', data: data);

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to update address: $e');
    }
  }

  /// Delete address
  Future<Map<String, dynamic>> deleteAddress(int addressId) async {
    try {
      final response = await _dio.delete('/addresses/$addressId');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'success': true, 'message': 'Address deleted'};
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to delete address: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/user');
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to get profile: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    try {
      final data = {
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      };

      final response = await _dio.post('/user/update', data: data);

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to update profile: $e');
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      final data = {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      };

      final response = await _dio.post('/user/change-password', data: data);

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to change password: $e');
    }
  }

  /// Delete user account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await _dio.delete('/user/account');

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'success': true, 'message': 'Account deleted'};
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to delete account: $e');
    }
  }

  /// Create address
  Future<Map<String, dynamic>> createAddress({
    required String address,
    required double latitude,
    required double longitude,
    String? label,
    bool? isDefault,
  }) async {
    try {
      final data = {
        'address': address,
        // Backend table has title + address_line + latitude + longitude + is_default
        'title': label ?? 'Default Address',
        'address_line': address,
        'latitude': latitude,
        'longitude': longitude,
        if (label != null) 'label': label,
        if (isDefault != null) 'is_default': isDefault ? 1 : 0,
      };

      final response = await _dio.post('/addresses', data: data);

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to create address: $e');
    }
  }

  /// Get notifications
  Future<Map<String, dynamic>> getNotifications({int? page}) async {
    try {
      final queryParams = page != null ? {'page': page} : null;

      if (kDebugMode) {
        print('=== GET NOTIFICATIONS REQUEST ===');
        print('URL: $baseUrl/notifications');
        print('Query params: $queryParams');
      }

      final response =
          await _dio.get('/notifications', queryParameters: queryParams);

      if (kDebugMode) {
        print('=== GET NOTIFICATIONS RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data type: ${response.data.runtimeType}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      // Return default structure if no data
      return {
        'success': true,
        'data': [],
        'message': 'لا توجد إشعارات',
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== GET NOTIFICATIONS ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN GET NOTIFICATIONS ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get notifications: $e');
    }
  }

  /// Mark notification as read - FIXED: Updated to match backend endpoint
  Future<Map<String, dynamic>> markNotificationAsRead(
      int notificationId) async {
    try {
      if (kDebugMode) {
        print('=== MARK NOTIFICATION AS READ REQUEST ===');
        print('URL: $baseUrl/notifications/mark-read/$notificationId');
        print('Notification ID: $notificationId');
      }

      // FIXED: Backend uses /notifications/mark-read/{id} not /notifications/{id}/read
      final response =
          await _dio.post('/notifications/mark-read/$notificationId');

      if (kDebugMode) {
        print('=== MARK NOTIFICATION AS READ RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'success': true, 'message': 'تم تحديث حالة الإشعار'};
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== MARK NOTIFICATION AS READ ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN MARK NOTIFICATION AS READ ===');
        print('Error: $e');
      }
      throw ApiException('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      if (kDebugMode) {
        print('=== MARK ALL NOTIFICATIONS AS READ REQUEST ===');
        print('URL: $baseUrl/notifications/mark-all-read');
      }

      final response = await _dio.post('/notifications/mark-all-read');

      if (kDebugMode) {
        print('=== MARK ALL NOTIFICATIONS AS READ RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'success': true, 'message': 'تم تحديث جميع الإشعارات'};
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== MARK ALL NOTIFICATIONS AS READ ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN MARK ALL NOTIFICATIONS AS READ ===');
        print('Error: $e');
      }
      throw ApiException('Failed to mark all notifications as read: $e');
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final data = {
        'email': email,
      };

      if (kDebugMode) {
        print('=== RESEND OTP REQUEST ===');
        print('URL: $baseUrl/auth/resend-otp');
        print('Data: $data');
      }

      final response = await _dio.post(
        '/auth/resend-otp',
        data: data,
      );

      if (kDebugMode) {
        print('=== RESEND OTP RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== RESEND OTP ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }

      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to resend OTP: $e');
    }
  }

  /// Toggle technician availability status
  Future<Map<String, dynamic>> toggleAvailability({
    required bool isAvailable,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final data = {
        'is_available': isAvailable ? 1 : 0,
        if (latitude != null) 'current_lat': latitude,
        if (longitude != null) 'current_lng': longitude,
      };

      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY REQUEST ===');
        print('URL: $baseUrl/technician/toggle-availability');
        print('Data: $data');
      }

      final response = await _dio.post(
        '/technician/toggle-availability',
        data: data,
      );

      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to toggle availability: $e');
    }
  }

  /// Get technician's assigned orders
  Future<Map<String, dynamic>> getTechnicianAssignedOrders(
      {String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;

      if (kDebugMode) {
        print('=== GET TECHNICIAN ASSIGNED ORDERS REQUEST ===');
        print('URL: $baseUrl/technician/my-assigned-orders');
        print('Status filter: $status');
      }

      final response = await _dio.get(
        '/technician/my-assigned-orders',
        queryParameters: queryParams,
      );

      if (kDebugMode) {
        print('=== TECHNICIAN ASSIGNED ORDERS RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== TECHNICIAN ASSIGNED ORDERS ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get assigned orders: $e');
    }
  }

  /// Get technician's current active job
  Future<Map<String, dynamic>> getCurrentJob() async {
    try {
      if (kDebugMode) {
        print('=== GET CURRENT JOB REQUEST ===');
        print('URL: $baseUrl/technician/current-job');
      }

      final response = await _dio.get('/technician/current-job');

      if (kDebugMode) {
        print('=== CURRENT JOB RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== CURRENT JOB ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get current job: $e');
    }
  }

  /// Update technician location
  Future<Map<String, dynamic>> updateTechnicianLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final data = {
        'lat': latitude,
        'lng': longitude,
      };

      if (kDebugMode) {
        print('=== UPDATE TECHNICIAN LOCATION REQUEST ===');
        print('URL: $baseUrl/technician/update-location');
        print('Data: $data');
      }

      final response = await _dio.post(
        '/technician/update-location',
        data: data,
      );

      if (kDebugMode) {
        print('=== UPDATE LOCATION RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== UPDATE LOCATION ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to update location: $e');
    }
  }

  /// Get technician statistics
  Future<Map<String, dynamic>> getTechnicianStats() async {
    try {
      if (kDebugMode) {
        print('=== GET TECHNICIAN STATS REQUEST ===');
        print('URL: $baseUrl/technician/stats');
      }

      final response = await _dio.get('/technician/stats');

      if (kDebugMode) {
        print('=== TECHNICIAN STATS RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw ApiException('Invalid response format from server');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== TECHNICIAN STATS ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get technician stats: $e');
    }
  }

  /// Update an existing service request
  Future<Map<String, dynamic>> updateRequest({
    required int requestId,
    String? description,
    String? priority,
    DateTime? scheduledAt,
  }) async {
    try {
      final data = {
        if (description != null) 'description': description,
        if (priority != null) 'priority': priority,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
      };

      final response = await _dio.put('/requests/$requestId', data: data);
      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      throw ApiException('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to update request: $e');
    }
  }

  /// Cancel a service request
  /// Tries multiple methods: PUT, PATCH, or POST to cancel endpoint
  Future<Map<String, dynamic>> cancelRequest(int requestId) async {
    try {
      if (kDebugMode) {
        print('=== CANCEL REQUEST ===');
        print('Request ID: $requestId');
      }

      // Method 1: Try PUT to update status
      try {
        if (kDebugMode) {
          print('Trying PUT /requests/$requestId');
        }
        final response = await _dio.put(
          '/requests/$requestId',
          data: {'status': 'canceled'},
        );

        if (kDebugMode) {
          print('=== CANCEL REQUEST SUCCESS (PUT) ===');
          print('Status: ${response.statusCode}');
        }

        if (response.data is Map<String, dynamic>) {
          return response.data;
        }
        return {'success': true, 'message': 'تم إلغاء الطلب بنجاح'};
      } on DioException catch (e) {
        if (kDebugMode) {
          print('PUT failed: ${e.response?.statusCode}');
        }

        // Method 2: Try PATCH
        if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
          try {
            if (kDebugMode) {
              print('Trying PATCH /requests/$requestId');
            }
            final patchResponse = await _dio.patch(
              '/requests/$requestId',
              data: {'status': 'canceled'},
            );

            if (kDebugMode) {
              print('=== CANCEL REQUEST SUCCESS (PATCH) ===');
              print('Status: ${patchResponse.statusCode}');
            }

            if (patchResponse.data is Map<String, dynamic>) {
              return patchResponse.data;
            }
            return {'success': true, 'message': 'تم إلغاء الطلب بنجاح'};
          } on DioException catch (e2) {
            if (kDebugMode) {
              print('PATCH failed: ${e2.response?.statusCode}');
            }

            // Method 3: Try POST to cancel endpoint (if backend has it)
            if (e2.response?.statusCode == 404 ||
                e2.response?.statusCode == 405) {
              try {
                if (kDebugMode) {
                  print('Trying POST /requests/$requestId/cancel');
                }
                final postResponse =
                    await _dio.post('/requests/$requestId/cancel');

                if (kDebugMode) {
                  print('=== CANCEL REQUEST SUCCESS (POST) ===');
                  print('Status: ${postResponse.statusCode}');
                }

                if (postResponse.data is Map<String, dynamic>) {
                  return postResponse.data;
                }
                return {'success': true, 'message': 'تم إلغاء الطلب بنجاح'};
              } on DioException catch (e3) {
                // All methods failed
                if (kDebugMode) {
                  print('All cancel methods failed');
                  print('POST error: ${e3.response?.statusCode}');
                  print('Response: ${e3.response?.data}');
                }
                throw e3;
              }
            } else {
              throw e2;
            }
          }
        } else {
          throw e;
        }
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== CANCEL REQUEST ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN CANCEL REQUEST ===');
        print('Error: $e');
      }
      throw ApiException('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  /// Handle Dio errors
  ApiException _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      final statusCode = error.response!.statusCode;

      if (data is Map<String, dynamic>) {
        // Check for Laravel validation errors
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return ApiException(
              firstError.first.toString(),
              errors: data, // Pass the whole data map
              statusCode: statusCode,
            );
          }
        }

        // Check for message field
        if (data.containsKey('message')) {
          return ApiException(
            data['message'].toString(),
            errors: data, // Pass the whole data map
            statusCode: statusCode,
          );
        }

        // Check for error field
        if (data.containsKey('error')) {
          return ApiException(
            data['error'].toString(),
            errors: data, // Pass the whole data map
            statusCode: statusCode,
          );
        }
      }

      // Generic error based on status code
      switch (error.response!.statusCode) {
        case 400:
          return ApiException('طلب غير صالح', statusCode: 400);
        case 401:
          return ApiException('غير مصرح', statusCode: 401);
        case 404:
          return ApiException('المورد غير موجود', statusCode: 404);
        case 422:
          return ApiException('بيانات غير صالحة', statusCode: 422);
        case 500:
          return ApiException('خطأ في الخادم', statusCode: 500);
        default:
          return ApiException(
            'حدث خطأ: ${error.response!.statusCode}',
            statusCode: error.response!.statusCode,
          );
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return ApiException('انتهت مهلة الاتصال');
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return ApiException('انتهت مهلة استقبال البيانات');
    } else if (error.type == DioExceptionType.connectionError) {
      return ApiException('فشل الاتصال بالخادم');
    } else {
      return ApiException('حدث خطأ غير متوقع');
    }
  }

  /// ===== CONNECTIVITY TESTING METHODS =====

  /// Test API connectivity and health
  Future<Map<String, dynamic>> testConnection() async {
    try {
      if (kDebugMode) {
        print('=== API CONNECTION TEST ===');
        print('Testing connection to: $baseUrl');
      }

      final response = await _dio.get('/health-check').timeout(
            const Duration(seconds: 10),
          );

      if (kDebugMode) {
        print('=== API CONNECTION TEST RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      return {
        'success': true,
        'message': 'الاتصال مع الخادم يعمل بشكل طبيعي',
        'baseUrl': baseUrl,
        'status': response.statusCode,
        'data': response.data,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== API CONNECTION TEST ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }

      String errorMessage = 'فشل الاتصال مع الخادم';
      if (e.response?.statusCode == 404) {
        errorMessage = 'endpoint /health-check غير موجود في الخادم';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'انتهت مهلة الاتصال مع الخادم';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'انتهت مهلة استقبال البيانات من الخادم';
      }

      return {
        'success': false,
        'message': errorMessage,
        'baseUrl': baseUrl,
        'error': e.toString(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN CONNECTION TEST ===');
        print('Error: $e');
      }

      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء اختبار الاتصال',
        'baseUrl': baseUrl,
        'error': e.toString(),
      };
    }
  }

  /// Test specific endpoint (helpful for debugging)
  Future<Map<String, dynamic>> testEndpoint(String endpoint) async {
    try {
      if (kDebugMode) {
        print('=== TESTING ENDPOINT: $endpoint ===');
        print('Full URL: $baseUrl$endpoint');
      }

      final response = await _dio.get(endpoint).timeout(
            const Duration(seconds: 10),
          );

      if (kDebugMode) {
        print('=== ENDPOINT TEST RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('Data type: ${response.data.runtimeType}');
        print('Data: ${response.data}');
      }

      return {
        'success': true,
        'message': 'Endpoint يعمل بشكل طبيعي',
        'endpoint': endpoint,
        'fullUrl': '$baseUrl$endpoint',
        'status': response.statusCode,
        'dataType': response.data.runtimeType.toString(),
        'data': response.data,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== ENDPOINT TEST ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }

      String errorMessage = 'فشل الوصول إلى $endpoint';
      if (e.response?.statusCode == 404) {
        errorMessage = 'Endpoint غير موجود: $endpoint';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'غير مصرح بالوصول إلى $endpoint';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'خطأ في الخادم أثناء الوصول إلى $endpoint';
      }

      return {
        'success': false,
        'message': errorMessage,
        'endpoint': endpoint,
        'fullUrl': '$baseUrl$endpoint',
        'status': e.response?.statusCode,
        'error': e.toString(),
        'responseData': e.response?.data,
      };
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN ENDPOINT TEST ===');
        print('Error: $e');
      }

      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع أثناء اختبار $endpoint',
        'endpoint': endpoint,
        'fullUrl': '$baseUrl$endpoint',
        'error': e.toString(),
      };
    }
  }

  /// Get comprehensive API status
  Future<Map<String, dynamic>> getApiStatus() async {
    final results = <String, dynamic>{
      'baseUrl': baseUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
    };

    // Test basic health check
    final healthResult = await testConnection();
    results['tests']['health_check'] = healthResult;

    // Test common endpoints that match backend structure
    final commonEndpoints = [
      '/auth/me', // Profile endpoint
      '/user', // User profile endpoint
      '/notifications', // Notifications endpoint
      '/service-categories', // Service categories endpoint
      '/addresses', // Addresses endpoint
      '/technician/stats', // Technician stats (might fail for customers - that's ok)
    ];

    for (String endpoint in commonEndpoints) {
      final endpointResult = await testEndpoint(endpoint);
      results['tests'][endpoint.replaceAll('/', '_')] = endpointResult;
    }

    // Overall assessment
    final successfulTests =
        results['tests'].values.where((test) => test['success'] == true).length;
    final totalTests = results['tests'].length;

    results['summary'] = {
      'successful_tests': successfulTests,
      'total_tests': totalTests,
      'success_rate': totalTests > 0 ? successfulTests / totalTests : 0.0,
      'overall_status': successfulTests == totalTests
          ? 'healthy'
          : successfulTests > totalTests / 2
              ? 'partial'
              : 'unhealthy',
    };

    if (kDebugMode) {
      print('=== API STATUS SUMMARY ===');
      print('Base URL: ${results['baseUrl']}');
      print('Success rate: ${results['summary']['success_rate']}');
      print('Overall status: ${results['summary']['overall_status']}');
    }

    return results;
  }

  /// ===== TECHNICIAN EARNINGS/CUSTODY METHODS =====

  /// Get technician earnings/custody data
  Future<Map<String, dynamic>> getTechnicianEarnings() async {
    try {
      if (kDebugMode) {
        print('=== GET TECHNICIAN EARNINGS REQUEST ===');
        print('URL: $baseUrl/technician/earnings');
      }

      final response = await _dio.get('/technician/earnings');

      if (kDebugMode) {
        print('=== GET TECHNICIAN EARNINGS RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return {
        'success': true,
        'data': {
          'recent_earnings': [],
          'summary': {},
        },
        'message': 'لا توجد بيانات أرباح',
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== GET TECHNICIAN EARNINGS ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN GET TECHNICIAN EARNINGS ===');
        print('Error: $e');
      }
      throw ApiException('Failed to get technician earnings: $e');
    }
  }

  /// Toggle technician availability
  Future<Map<String, dynamic>> toggleTechnicianAvailability({
    required bool isAvailable,
    double? currentLat,
    double? currentLng,
  }) async {
    try {
      final data = {
        'is_available': isAvailable,
        if (currentLat != null) 'current_lat': currentLat,
        if (currentLng != null) 'current_lng': currentLng,
      };

      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY REQUEST ===');
        print('URL: $baseUrl/technician/toggle-availability');
        print('Data: $data');
      }

      final response =
          await _dio.post('/technician/toggle-availability', data: data);

      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return {
        'success': true,
        'message': isAvailable ? 'تم تفعيل التوفر' : 'تم إيقاف التوفر',
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== TOGGLE AVAILABILITY ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN TOGGLE AVAILABILITY ===');
        print('Error: $e');
      }
      throw ApiException('Failed to toggle availability: $e');
    }
  }

  /// Update request/job status
  Future<Map<String, dynamic>> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      final data = {
        'status': status,
      };

      if (kDebugMode) {
        print('=== UPDATE REQUEST STATUS REQUEST ===');
        print('URL: $baseUrl/requests/$requestId');
        print('Data: $data');
      }

      final response = await _dio.put('/requests/$requestId', data: data);

      if (kDebugMode) {
        print('=== UPDATE REQUEST STATUS RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }

      return {
        'success': true,
        'message': 'تم تحديث حالة الطلب',
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== UPDATE REQUEST STATUS ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN UPDATE REQUEST STATUS ===');
        print('Error: $e');
      }
      throw ApiException('Failed to update request status: $e');
    }
  }

  /// Submit a rating for a service request
  Future<Map<String, dynamic>> submitRating({
    required int requestId,
    required int rating,
    String? review,
  }) async {
    try {
      final data = {
        'request_id': requestId,
        'rating': rating,
        if (review != null) 'review': review,
      };

      if (kDebugMode) {
        print('=== SUBMIT RATING REQUEST ===');
        print('URL: $baseUrl/ratings/submit');
        print('Data: $data');
      }

      final response = await _dio.post('/ratings/submit', data: data);

      if (kDebugMode) {
        print('=== SUBMIT RATING RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
      }

      if (response.data is Map<String, dynamic>) {
        return response.data;
      }
      return {'success': true, 'message': 'تم إرسال التقييم بنجاح'};
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== SUBMIT RATING ERROR ===');
        print('Error: ${e.toString()}');
        print('Response: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      if (kDebugMode) {
        print('=== UNEXPECTED ERROR IN SUBMIT RATING ===');
        print('Error: $e');
      }
      throw ApiException('Failed to submit rating: $e');
    }
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiException(this.message, {this.errors, this.statusCode});

  String? getFirstError() {
    if (errors == null || errors!.isEmpty) return null;
    final firstKey = errors!.keys.first;
    final value = errors![firstKey];
    if (value is List && value.isNotEmpty) {
      return value.first.toString();
    }
    return value?.toString();
  }

  @override
  String toString() => message;
}
