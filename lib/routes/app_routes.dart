import 'package:flutter/material.dart';
import '../presentation/customer_home_screen/customer_home_screen.dart';
import '../presentation/location_permission_screen/location_permission_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/create_request_screen/create_request_screen.dart';
import '../presentation/job_details_screen/job_details_screen.dart';
import '../presentation/earnings_screen/earnings_screen.dart';
import '../presentation/my_requests_screen/my_requests_screen.dart';
import '../presentation/technician_home_screen/technician_home_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/request_details_screen/request_details_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/otp_verification_screen/otp_verification_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/my_addresses_screen/my_addresses_screen.dart';
import '../presentation/map_picker_screen/map_picker_screen.dart';
import '../presentation/notifications_screen/notifications_screen.dart';
import '../presentation/change_password_screen/change_password_screen.dart';
import '../presentation/technician_jobs_screen/technician_jobs_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String customerHome = '/customer-home-screen';
  static const String locationPermission = '/location-permission-screen';
  static const String splash = '/splash-screen';
  static const String createRequest = '/create-request-screen';
  static const String jobDetails = '/job-details-screen';
  static const String earnings = '/earnings-screen';
  static const String myRequests = '/my-requests-screen';
  static const String technicianHome = '/technician-home-screen';
  static const String profile = '/profile-screen';
  static const String requestDetails = '/request-details-screen';
  static const String registration = '/registration-screen';
  static const String otpVerification = '/otp-verification-screen';
  static const String login = '/login-screen';
  static const String myAddresses = '/my-addresses-screen';
  static const String mapPicker = '/map-picker-screen';
  static const String notifications = '/notifications-screen';
  static const String changePassword = '/change-password-screen';
  static const String technicianJobs = '/technician-jobs-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    customerHome: (context) => const CustomerHomeScreen(),
    locationPermission: (context) => const LocationPermissionScreen(),
    splash: (context) => const SplashScreen(),
    createRequest: (context) => const CreateRequestScreen(),
    jobDetails: (context) => const JobDetailsScreen(),
    earnings: (context) => const EarningsScreen(),
    myRequests: (context) => const MyRequestsScreen(),
    technicianHome: (context) => const TechnicianHomeScreen(),
    profile: (context) => const ProfileScreen(),
    requestDetails: (context) => const RequestDetailsScreen(),
    registration: (context) => const RegistrationScreen(),
    otpVerification: (context) => const OtpVerificationScreen(),
    login: (context) => const LoginScreen(),
    myAddresses: (context) => const MyAddressesScreen(),
    mapPicker: (context) => const MapPickerScreen(),
    notifications: (context) => const NotificationsScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    technicianJobs: (context) => const TechnicianJobsScreen(),
    // TODO: Add your other routes here
  };
}
