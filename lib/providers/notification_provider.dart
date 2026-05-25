import 'package:flutter/foundation.dart';
import 'package:reelscholar/models/notification_model.dart';
import 'package:reelscholar/core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service;

  NotificationProvider({NotificationService? service})
      : _service = service ?? NotificationService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = false;

  Map<String, bool> _preferences = {};
  bool _loadingPreferences = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  Map<String, bool> get preferences => _preferences;
  bool get loadingPreferences => _loadingPreferences;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();
    try {
      final result = await _service.getNotifications(page: 1);
      _notifications = result.items;
      _unreadCount = result.unreadCount;
      _hasMore = result.hasMore;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final nextPage = _currentPage + 1;
      final result = await _service.getNotifications(page: nextPage);
      _notifications = [..._notifications, ...result.items];
      _unreadCount = result.unreadCount;
      _hasMore = result.hasMore;
      _currentPage = nextPage;
    } catch (_) {
      // Silently ignore pagination errors
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markRead(List<String> ids) async {
    _notifications = _notifications
        .map((n) => ids.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
    try {
      await _service.markRead(ids: ids);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markRead(ids: null);
    } catch (_) {}
  }

  void incrementUnreadCount() {
    _unreadCount++;
    notifyListeners();
  }

  Future<void> loadPreferences() async {
    _loadingPreferences = true;
    notifyListeners();
    try {
      _preferences = await _service.getPreferences();
    } catch (_) {
      // Silently ignore — show whatever was cached
    } finally {
      _loadingPreferences = false;
      notifyListeners();
    }
  }

  /// Optimistically toggles a preference and PUTs to the API.
  /// Returns an error message if the API call fails (for snackbar display).
  Future<String?> setPreference(String key, bool value) async {
    final previous = _preferences[key];
    _preferences = Map.from(_preferences)..[key] = value;
    notifyListeners();
    try {
      await _service.updatePreferences({key: value});
      return null;
    } catch (e) {
      // Revert
      _preferences = Map.from(_preferences)..[key] = previous ?? !value;
      notifyListeners();
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
