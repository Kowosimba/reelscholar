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
  String? _error;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.getNotifications();
      _notifications = result.items;
      _unreadCount = result.unreadCount;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(List<String> ids) async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => ids.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
    try {
      await _service.markRead(ids: ids);
    } catch (_) {
      // Silently ignore — state is already updated optimistically
    }
  }

  Future<void> markAllRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markRead(ids: null);
    } catch (_) {}
  }
}
