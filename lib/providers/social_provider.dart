// lib/providers/social_provider.dart

import 'package:flutter/foundation.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/core/services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _service;

  SocialProvider(this._service);

  // ── Search ─────────────────────────────────────────────────────────────────
  List<AppUser> _searchResults = [];
  List<AppUser> _suggestions = [];
  bool _searchLoading = false;
  bool _suggestionsLoading = false;
  String? _searchError;
  String _lastQuery = '';
  String _searchFilter = 'all';

  List<AppUser> get searchResults => _searchResults;
  List<AppUser> get suggestions => _suggestions;
  bool get searchLoading => _searchLoading;
  bool get suggestionsLoading => _suggestionsLoading;
  String? get searchError => _searchError;
  String get searchFilter => _searchFilter;

  Future<void> search(String query, {String? filter}) async {
    final q = query.trim();
    if (q.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    if (filter != null) _searchFilter = filter;
    _lastQuery = q;
    _searchLoading = true;
    _searchError = null;
    notifyListeners();
    try {
      final result = await _service.searchUsers(
          query: q, filter: _searchFilter);
      if (_lastQuery == q) {
        _searchResults = result.users;
      }
    } catch (e) {
      _searchError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _searchLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    _searchFilter = filter;
    if (_lastQuery.length >= 2) search(_lastQuery);
  }

  void clearSearch() {
    _searchResults = [];
    _lastQuery = '';
    notifyListeners();
  }

  Future<void> loadSuggestions() async {
    if (_suggestions.isNotEmpty) return;
    _suggestionsLoading = true;
    notifyListeners();
    try {
      _suggestions = await _service.getSuggestions();
    } catch (_) {
    } finally {
      _suggestionsLoading = false;
      notifyListeners();
    }
  }

  // ── Profile view ───────────────────────────────────────────────────────────
  AppUser? _viewedProfile;
  bool _profileLoading = false;
  String? _profileError;

  AppUser? get viewedProfile => _viewedProfile;
  bool get profileLoading => _profileLoading;
  String? get profileError => _profileError;

  Future<void> loadProfile(String userId) async {
    _profileLoading = true;
    _profileError = null;
    _viewedProfile = null;
    notifyListeners();
    try {
      _viewedProfile = await _service.getUser(userId);
    } catch (e) {
      _profileError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  // ── Follow toggle ──────────────────────────────────────────────────────────
  final Set<String> _followLoading = {};

  bool isFollowLoading(String uid) => _followLoading.contains(uid);

  Future<void> toggleFollow(String userId) async {
    if (_followLoading.contains(userId)) return;
    _followLoading.add(userId);
    notifyListeners();

    final wasFollowing = _viewedProfile?.isFollowing ?? false;
    if (_viewedProfile?.uid == userId) {
      _viewedProfile = _viewedProfile!.copyWith(
        isFollowing: !wasFollowing,
        followersCount: wasFollowing
            ? (_viewedProfile!.followersCount - 1).clamp(0, 999999)
            : _viewedProfile!.followersCount + 1,
      );
      notifyListeners();
    }
    _updateFollowInLists(userId, !wasFollowing);

    try {
      final result = await _service.toggleFollow(userId);
      if (_viewedProfile?.uid == userId) {
        _viewedProfile = _viewedProfile!.copyWith(
          isFollowing: result.isFollowing,
          followersCount: result.followersCount,
        );
      }
      _updateFollowInLists(userId, result.isFollowing);
    } catch (e) {
      if (_viewedProfile?.uid == userId) {
        _viewedProfile = _viewedProfile!.copyWith(
          isFollowing: wasFollowing,
          followersCount: _viewedProfile!.followersCount +
              (wasFollowing ? 1 : -1),
        );
      }
      _updateFollowInLists(userId, wasFollowing);
      rethrow;
    } finally {
      _followLoading.remove(userId);
      notifyListeners();
    }
  }

  void _updateFollowInLists(String uid, bool isFollowing) {
    _searchResults = _searchResults
        .map((u) => u.uid == uid ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
    _suggestions = _suggestions
        .map((u) => u.uid == uid ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
    _myFollowers = _myFollowers
        .map((u) => u.uid == uid ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
    _myFollowing = _myFollowing
        .map((u) => u.uid == uid ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
  }

  // ── Block ──────────────────────────────────────────────────────────────────
  Future<void> blockUser(String userId) async {
    await _service.blockUser(userId);
    if (_viewedProfile?.uid == userId) {
      _viewedProfile = _viewedProfile!.copyWith(isBlocked: true);
    }
    _removeFromLists(userId);
    notifyListeners();
  }

  Future<void> unblockUser(String userId) async {
    await _service.unblockUser(userId);
    _blockedUsers.removeWhere((u) => u.uid == userId);
    notifyListeners();
  }

  void _removeFromLists(String uid) {
    _searchResults.removeWhere((u) => u.uid == uid);
    _suggestions.removeWhere((u) => u.uid == uid);
    _myFollowers.removeWhere((u) => u.uid == uid);
    _myFollowing.removeWhere((u) => u.uid == uid);
  }

  // ── Blocked users ──────────────────────────────────────────────────────────
  List<AppUser> _blockedUsers = [];
  bool _blockedLoading = false;

  List<AppUser> get blockedUsers => _blockedUsers;
  bool get blockedLoading => _blockedLoading;

  Future<void> loadBlockedUsers({bool refresh = false}) async {
    if (_blockedLoading) return;
    if (_blockedUsers.isNotEmpty && !refresh) return;
    _blockedLoading = true;
    notifyListeners();
    try {
      _blockedUsers = await _service.getBlockedUsers();
    } catch (_) {
    } finally {
      _blockedLoading = false;
      notifyListeners();
    }
  }

  // ── My followers / following ───────────────────────────────────────────────
  List<AppUser> _myFollowers = [];
  List<AppUser> _myFollowing = [];
  bool _followersLoading = false;
  bool _followingLoading = false;

  List<AppUser> get myFollowers => _myFollowers;
  List<AppUser> get myFollowing => _myFollowing;
  bool get followersLoading => _followersLoading;
  bool get followingLoading => _followingLoading;

  Future<void> loadMyFollowers({bool refresh = false}) async {
    if (_followersLoading) return;
    if (_myFollowers.isNotEmpty && !refresh) return;
    _followersLoading = true;
    notifyListeners();
    try {
      _myFollowers = await _service.getMyFollowers();
    } catch (_) {
    } finally {
      _followersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyFollowing({bool refresh = false}) async {
    if (_followingLoading) return;
    if (_myFollowing.isNotEmpty && !refresh) return;
    _followingLoading = true;
    notifyListeners();
    try {
      _myFollowing = await _service.getMyFollowing();
    } catch (_) {
    } finally {
      _followingLoading = false;
      notifyListeners();
    }
  }

  // ── User-specific followers / following ────────────────────────────────────
  List<AppUser> _profileFollowers = [];
  List<AppUser> _profileFollowing = [];
  bool _profileFollowersLoading = false;
  bool _profileFollowingLoading = false;

  List<AppUser> get profileFollowers => _profileFollowers;
  List<AppUser> get profileFollowing => _profileFollowing;
  bool get profileFollowersLoading => _profileFollowersLoading;
  bool get profileFollowingLoading => _profileFollowingLoading;

  Future<void> loadProfileFollowers(String userId) async {
    _profileFollowersLoading = true;
    _profileFollowers = [];
    notifyListeners();
    try {
      _profileFollowers = await _service.getUserFollowers(userId);
    } catch (_) {
    } finally {
      _profileFollowersLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfileFollowing(String userId) async {
    _profileFollowingLoading = true;
    _profileFollowing = [];
    notifyListeners();
    try {
      _profileFollowing = await _service.getUserFollowing(userId);
    } catch (_) {
    } finally {
      _profileFollowingLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _viewedProfile = null;
    _profileFollowers = [];
    _profileFollowing = [];
    notifyListeners();
  }
}
