
class ApiConstants {
  static String? _customBaseUrl;

  // Supports compile-time override via: flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/v1
  // Otherwise defaults to 10.0.2.2 for Android emulator and 127.0.0.1 for desktop/web/testing
  static String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;

    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // return 'https://129-212-239-216.sslip.io/api/v1';
    return 'http://127.0.0.1:8000/api/v1';
  }

  static set baseUrl(String url) {
    _customBaseUrl = url;
  }


  // Auth endpoints
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Farmer & Owner endpoints
  static const String farmerProfile = '/farmer/profile';
  static const String farmers = '/farmers';
  static const String ownerDashboard = '/owner/dashboard';
  static String farmerDetails(int id) => '/farmers/$id';

  // Task & Assignment endpoints
  static const String tasks = '/tasks';
  static String taskDetails(int id) => '/tasks/$id';

  static const String assignments = '/assignments';
  static String assignmentDetails(int id) => '/assignments/$id';
  static String startAssignment(int id) => '/assignments/$id/start';
  static String submitAssignment(int id) => '/assignments/$id/submit';
  static String assignmentSubmission(int id) => '/assignments/$id/submission';

  // Location endpoints
  static const String locations = '/locations';
  static String locationDetails(int id) => '/locations/$id';

  // Farm & Field Boundary endpoints (Phase 12A V2 & 12B V2)
  static const String farms = '/farms';
  static String farmDetails(int id) => '/farms/$id';

  // Notification endpoints
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';

  // Storage Keys
  static const String tokenKey = 'bashir_agro_auth_token';
  static const String userKey = 'bashir_agro_auth_user';
  static const String profileKey = 'bashir_agro_farmer_profile';
  static const String cachedTasksKey = 'bashir_agro_cached_tasks';
  static const String offlineQueueKey = 'bashir_agro_offline_submissions';
  static const String notificationsKey = 'bashir_agro_notifications';
}
