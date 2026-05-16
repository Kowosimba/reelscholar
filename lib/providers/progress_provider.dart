// lib/providers/progress_provider.dart

import 'package:flutter/foundation.dart';
import 'package:reelscholar/core/services/progress_service.dart';
import 'package:reelscholar/models/progress_models.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _service;
  ProgressProvider(this._service);

  // ── Dashboard ─────────────────────────────────────────────────────────────
  ProgressDashboard? _dashboard;
  bool _dashboardLoading = false;
  String? _dashboardError;

  ProgressDashboard? get dashboard => _dashboard;
  bool get dashboardLoading => _dashboardLoading;
  String? get dashboardError => _dashboardError;

  Future<void> loadDashboard({bool refresh = false}) async {
    if (_dashboard != null && !refresh) return;
    _dashboardLoading = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.getDashboard();
    } catch (e) {
      _dashboardError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  // ── Leaderboard ───────────────────────────────────────────────────────────
  LeaderboardData? _leaderboard;
  bool _lbLoading = false;
  String? _lbError;
  String _lbScope = 'programme';

  LeaderboardData? get leaderboard => _leaderboard;
  bool get lbLoading => _lbLoading;
  String? get lbError => _lbError;
  String get lbScope => _lbScope;

  Future<void> loadLeaderboard({String? scope, bool refresh = false}) async {
    final s = scope ?? _lbScope;
    if (s != _lbScope || refresh || _leaderboard == null) {
      _lbScope = s;
      _leaderboard = null;
    }
    if (_leaderboard != null) return;
    _lbLoading = true;
    _lbError = null;
    notifyListeners();
    try {
      _leaderboard = await _service.getLeaderboard(scope: _lbScope);
    } catch (e) {
      _lbError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _lbLoading = false;
      notifyListeners();
    }
  }

  void setLeaderboardScope(String scope) {
    if (_lbScope == scope) return;
    _lbScope = scope;
    _leaderboard = null;
    loadLeaderboard();
  }

  // ── Achievements ──────────────────────────────────────────────────────────
  List<Achievement> _achievements = [];
  bool _achievementsLoading = false;
  String? _achievementsError;
  bool _achievementsLoaded = false;

  List<Achievement> get achievements => _achievements;
  bool get achievementsLoading => _achievementsLoading;
  String? get achievementsError => _achievementsError;

  Future<void> loadAchievements({bool refresh = false}) async {
    if (_achievementsLoaded && !refresh) return;
    _achievementsLoading = true;
    _achievementsError = null;
    notifyListeners();
    try {
      _achievements = await _service.getAchievements();
      _achievementsLoaded = true;
    } catch (e) {
      _achievementsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _achievementsLoading = false;
      notifyListeners();
    }
  }

  // ── Topics ────────────────────────────────────────────────────────────────
  List<AppTopic> _topics = [];
  bool _topicsLoading = false;

  List<AppTopic> get topics => _topics;
  bool get topicsLoading => _topicsLoading;

  Future<void> searchTopics({String? query}) async {
    _topicsLoading = true;
    notifyListeners();
    try {
      _topics = await _service.getTopics(query: query);
    } catch (_) {
      _topics = [];
    } finally {
      _topicsLoading = false;
      notifyListeners();
    }
  }
}
