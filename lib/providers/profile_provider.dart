// lib/providers/profile_provider.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:reelscholar/core/services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _service;

  ProfileProvider(this._service);

  // ── Me / current user ─────────────────────────────────────────────────────
  Map<String, dynamic>? _me;
  bool _meLoading = false;
  String? _meError;

  Map<String, dynamic>? get me => _me;
  bool get meLoading => _meLoading;
  String? get meError => _meError;

  // Convenient accessors
  String get displayName => _me?['full_name'] as String? ?? '';
  String get email => _me?['email'] as String? ?? '';
  String? get profilePicUrl => _me?['profile_pic_url'] as String?;
  String? get faculty => _me?['faculty'] as String?;
  String? get degreeProgramme => _me?['degree_programme'] as String?;
  int get yearLevel => _me?['year_level'] as int? ?? 1;
  int get semester => _me?['semester'] as int? ?? 1;
  String? get bio => _me?['bio'] as String?;
  String? get studentId => _me?['student_id'] as String?;
  String get role => _me?['role'] as String? ?? 'student';
  bool get isLecturer => role == 'lecturer';
  int get totalXp => _me?['total_xp'] as int? ?? 0;
  int get currentStreak => _me?['current_streak'] as int? ?? 0;
  int get longestStreak => _me?['longest_streak'] as int? ?? 0;
  int get videoCount => _me?['video_count'] as int? ?? 0;
  int get followersCount =>
      _me?['followers'] as int? ?? _me?['followers_count'] as int? ?? 0;
  int get followingCount =>
      _me?['following'] as int? ?? _me?['following_count'] as int? ?? 0;
  int get xpLevel => (totalXp / 500).floor() + 1;
  double get xpProgress => (totalXp % 500) / 500;

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  Future<void> loadMe({bool refresh = false}) async {
    if (_meLoading) return;
    if (_me != null && !refresh) return;
    _meLoading = true;
    _meError = null;
    notifyListeners();
    try {
      _me = await _service.getMe();
    } catch (e) {
      _meError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _meLoading = false;
      notifyListeners();
    }
  }

  // ── Edit profile ──────────────────────────────────────────────────────────
  bool _updating = false;
  String? _updateError;

  bool get updating => _updating;
  String? get updateError => _updateError;

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? studentId,
    String? faculty,
    String? degreeProgramme,
    int? yearLevel,
    int? semester,
    String? bio,
    File? profilePicture,
    bool removeProfilePicture = false,
  }) async {
    _updating = true;
    _updateError = null;
    notifyListeners();
    try {
      final updated = await _service.updateProfile(
        fullName: fullName,
        email: email,
        studentId: studentId,
        faculty: faculty,
        degreeProgramme: degreeProgramme,
        yearLevel: yearLevel,
        semester: semester,
        bio: bio,
        profilePicture: profilePicture,
        removeProfilePicture: removeProfilePicture,
      );
      // Merge into _me
      if (_me != null) {
        _me = {..._me!, ...updated};
      } else {
        _me = updated;
      }
    } catch (e) {
      _updateError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  // ── Change password ───────────────────────────────────────────────────────
  bool _pwChanging = false;
  String? _pwError;

  bool get pwChanging => _pwChanging;
  String? get pwError => _pwError;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    _pwChanging = true;
    _pwError = null;
    notifyListeners();
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmation: confirmation,
      );
    } catch (e) {
      _pwError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _pwChanging = false;
      notifyListeners();
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> deleteAccount(String password) async {
    await _service.deleteAccount(password);
    _me = null;
    notifyListeners();
  }

  // ── Meta: faculties & programmes ──────────────────────────────────────────
  List<Faculty> _faculties = [];
  List<String> _programmes = [];
  bool _facultiesLoading = false;
  bool _programmesLoading = false;

  List<Faculty> get faculties => _faculties;
  List<String> get programmes => _programmes;
  bool get facultiesLoading => _facultiesLoading;
  bool get programmesLoading => _programmesLoading;

  List<String> get facultyNames =>
      _faculties.map((f) => f.name).toList();

  Future<void> loadFaculties() async {
    if (_faculties.isNotEmpty) return;
    _facultiesLoading = true;
    notifyListeners();
    try {
      _faculties = await _service.getFaculties();
    } catch (_) {
    } finally {
      _facultiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProgrammes(String faculty) async {
    _programmesLoading = true;
    _programmes = [];
    notifyListeners();
    try {
      final cached =
          _faculties.where((f) => f.name == faculty).firstOrNull;
      if (cached != null && cached.programmes.isNotEmpty) {
        _programmes = cached.programmes;
      } else {
        _programmes = await _service.getProgrammes(faculty);
      }
    } catch (_) {
    } finally {
      _programmesLoading = false;
      notifyListeners();
    }
  }

  // ── Notification preferences ──────────────────────────────────────────────
  NotificationPrefs? _notifPrefs;
  bool _notifLoading = false;
  bool _notifSaving = false;

  NotificationPrefs? get notifPrefs => _notifPrefs;
  bool get notifLoading => _notifLoading;
  bool get notifSaving => _notifSaving;

  Future<void> loadNotificationPrefs() async {
    if (_notifPrefs != null) return;
    _notifLoading = true;
    notifyListeners();
    try {
      _notifPrefs = await _service.getNotificationPrefs();
    } catch (_) {
      _notifPrefs = const NotificationPrefs();
    } finally {
      _notifLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNotificationPrefs(NotificationPrefs prefs) async {
    _notifPrefs = prefs; // Optimistic
    _notifSaving = true;
    notifyListeners();
    try {
      await _service.updateNotificationPrefs(prefs);
    } catch (_) {
    } finally {
      _notifSaving = false;
      notifyListeners();
    }
  }

  void toggleNotifPref(String key, bool value) {
    if (_notifPrefs == null) return;
    final updated = switch (key) {
      'followers' => _notifPrefs!.copyWith(followers: value),
      'likes' => _notifPrefs!.copyWith(likes: value),
      'comments' => _notifPrefs!.copyWith(comments: value),
      'study_groups' => _notifPrefs!.copyWith(studyGroups: value),
      'hackathons' => _notifPrefs!.copyWith(hackathons: value),
      'direct_messages' => _notifPrefs!.copyWith(directMessages: value),
      'announcements' => _notifPrefs!.copyWith(announcements: value),
      _ => _notifPrefs!,
    };
    updateNotificationPrefs(updated);
  }
}
