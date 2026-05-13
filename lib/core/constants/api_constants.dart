class ApiConstants {
  static const String baseUrl = 'https://reelscholarapi-main-l5f9h5.laravel.cloud/api';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String verificationStatus = '/auth/verification-status';
  static const String resendVerification = '/auth/resend-verification';
  static const String verificationLink = '/auth/verification-link';
  static const String fcmToken = '/auth/fcm-token';

  // ─── Metadata ──────────────────────────────────────────────────────────────
  static const String faculties = '/meta/faculties';
  static const String programmes = '/meta/programmes';
}

/// Role options sent to the API
class RoleOptions {
  static const String student = 'student';
  static const String lecturer = 'lecturer';
}

/// Year level options for registration
class YearLevelOptions {
  static const List<int> yearLevels = [1, 2, 3, 4, 5];
}

/// Semester options for registration
class SemesterOptions {
  static const List<int> semesters = [1, 2];
}
