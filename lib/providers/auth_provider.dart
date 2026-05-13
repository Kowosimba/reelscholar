import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final bool emailVerified;
  final String? studentId;
  final String faculty;
  final String degreeProgramme;
  final int yearLevel;
  final int semester;
  final String role;
  final String? bio;
  final String? profilePicUrl;
  final int totalXp;
  final int currentStreak;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.emailVerified,
    this.studentId,
    required this.faculty,
    required this.degreeProgramme,
    required this.yearLevel,
    required this.semester,
    required this.role,
    this.bio,
    this.profilePicUrl,
    required this.totalXp,
    required this.currentStreak,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        emailVerified: json['email_verified'] as bool? ?? false,
        studentId: json['student_id'] as String?,
        faculty: json['faculty'] as String? ?? '',
        degreeProgramme: json['degree_programme'] as String? ?? '',
        yearLevel: json['year_level'] as int? ?? 1,
        semester: json['semester'] as int? ?? 1,
        role: json['role'] as String? ?? 'student',
        bio: json['bio'] as String?,
        profilePicUrl: json['profile_pic_url'] as String?,
        totalXp: json['total_xp'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
      );

  bool get isStudent => role == 'student';
  bool get isLecturer => role == 'lecturer';
}

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isLoadingMetadata = false;
  List<String> _faculties = [];
  List<String> _programmes = [];

  // ─── Getters ───────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isLoadingMetadata => _isLoadingMetadata;
  List<String> get faculties => _faculties;
  List<String> get programmes => _programmes;

  // ─── Auth status check (called from splash) ────────────────────────────────
  Future<void> checkAuthStatus() async {
    final token = await _service.getToken();
    if (token == null) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }
    try {
      final userData = await _service.getMe();
      _user = UserModel.fromJson(userData);
      _isAuthenticated = true;
    } catch (_) {
      await _service.clearToken();
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // ─── Register ──────────────────────────────────────────────────────────────
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String faculty,
    required int yearLevel,
    required int semester,
    required String degreeProgramme,
    required String role,
    String? studentId,
    String? fcmToken,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        faculty: faculty,
        yearLevel: yearLevel,
        semester: semester,
        degreeProgramme: degreeProgramme,
        role: role,
        studentId: studentId,
        fcmToken: fcmToken,
      );
      _user = UserModel.fromJson(data['data']['user'] as Map<String, dynamic>);
      _isAuthenticated = true;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String loginId, String password, {String? fcmToken}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.login(
        login: loginId,
        password: password,
        fcmToken: fcmToken,
      );
      _user = UserModel.fromJson(data['data']['user'] as Map<String, dynamic>);
      _isAuthenticated = true;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> logoutAll() async {
    await _service.logoutAll();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // ─── Forgot / Reset password ───────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _service.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _service.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  // ─── Email verification ────────────────────────────────────────────────────
  Future<bool> checkEmailVerification() async {
    final verified = await _service.checkVerificationStatus();
    if (verified && _user != null) {
      // Refresh user from server
      final userData = await _service.getMe();
      _user = UserModel.fromJson(userData);
      notifyListeners();
    }
    return verified;
  }

  Future<void> resendVerificationEmail([String? email]) async {
    await _service.resendVerification();
  }

  // ─── Change password ───────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await _service.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      newPasswordConfirmation: newPasswordConfirmation,
    );
  }

  // ─── FCM token ─────────────────────────────────────────────────────────────
  Future<void> updateFcmToken(String token) async {
    try {
      await _service.updateFcmToken(token);
    } catch (_) {
      // Non-critical: fail silently
    }
  }

  // ─── Metadata ──────────────────────────────────────────────────────────────
  Future<void> loadFaculties() async {
    if (_faculties.isNotEmpty) return;
    _isLoadingMetadata = true;
    notifyListeners();
    try {
      _faculties = await _service.getFaculties();
    } catch (_) {
      // Use fallback defaults if API fails
      _faculties = [
        'Engineering & Technology',
        'Business & Management',
        'Sciences',
        'Humanities & Social Sciences',
        'Health Sciences',
        'Education',
        'Law',
      ];
    } finally {
      _isLoadingMetadata = false;
      notifyListeners();
    }
  }

  Future<void> loadProgrammes(String faculty) async {
    _programmes = [];
    _isLoadingMetadata = true;
    notifyListeners();
    try {
      _programmes = await _service.getProgrammes(faculty);
    } catch (_) {
      _programmes = [];
    } finally {
      _isLoadingMetadata = false;
      notifyListeners();
    }
  }
}
