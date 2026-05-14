import 'package:flutter/foundation.dart';

/// Bottom nav indices
/// 0 = Reels  1 = Chats  2 = Study Groups  3 = Learn  4 = Profile
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0; // Default: Reels

  // Unread badge counts
  int _unreadChats = 0;
  int _unreadNotifications = 0;

  bool _drawerOpen = false;

  // ── Getters ─────────────────────────────────────────────────────────────────
  int get currentIndex => _currentIndex;
  int get unreadChats => _unreadChats;
  int get unreadNotifications => _unreadNotifications;
  bool get drawerOpen => _drawerOpen;

  bool get isReels => _currentIndex == 0;
  bool get isChats => _currentIndex == 1;
  bool get isStudyGroups => _currentIndex == 2;
  bool get isLearn => _currentIndex == 3;
  bool get isProfile => _currentIndex == 4;

  // ── Navigation ───────────────────────────────────────────────────────────────
  void setTab(int index) {
    if (_currentIndex == index) return;
    _currentIndex = index;
    notifyListeners();
  }

  void goToReels() => setTab(0);
  void goToChats() => setTab(1);
  void goToStudyGroups() => setTab(2);
  void goToLearn() => setTab(3);
  void goToProfile() => setTab(4);

  // ── Drawer ──────────────────────────────────────────────────────────────────
  void openDrawer() {
    _drawerOpen = true;
    notifyListeners();
  }

  void closeDrawer() {
    _drawerOpen = false;
    notifyListeners();
  }

  // ── Badge counts ─────────────────────────────────────────────────────────────
  void setUnreadChats(int count) {
    if (_unreadChats == count) return;
    _unreadChats = count;
    notifyListeners();
  }

  void setUnreadNotifications(int count) {
    if (_unreadNotifications == count) return;
    _unreadNotifications = count;
    notifyListeners();
  }

  void clearChatBadge() => setUnreadChats(0);
  void clearNotificationBadge() => setUnreadNotifications(0);
}
