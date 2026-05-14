// lib/providers/hackathon_provider.dart

import 'package:flutter/foundation.dart';
import 'package:reelscholar/models/hackathon_models.dart';
import 'package:reelscholar/core/services/hackathon_service.dart';

class HackathonProvider extends ChangeNotifier {
  final HackathonService _service;

  HackathonProvider(this._service);

  // ── Listings ───────────────────────────────────────────────────────────────
  List<Hackathon> _hackathons = [];
  bool _listLoading = false;
  bool _listLoadingMore = false;
  String? _listError;
  int _listPage = 1;
  int _listLastPage = 1;

  List<Hackathon> get hackathons => _hackathons;
  bool get listLoading => _listLoading;
  bool get listLoadingMore => _listLoadingMore;
  String? get listError => _listError;
  bool get hasMoreHackathons => _listPage <= _listLastPage;

  Future<void> loadHackathons({bool refresh = false}) async {
    if (refresh) {
      _listPage = 1;
      _hackathons = [];
    }
    if (_listLoading) return;
    _listLoading = true;
    _listError = null;
    notifyListeners();
    try {
      final result = await _service.listHackathons(page: _listPage);
      _hackathons = [..._hackathons, ...result.items];
      _listLastPage = result.lastPage;
      _listPage++;
    } catch (e) {
      _listError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _listLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreHackathons() async {
    if (_listLoadingMore || !hasMoreHackathons) return;
    _listLoadingMore = true;
    notifyListeners();
    try {
      final result = await _service.listHackathons(page: _listPage);
      _hackathons = [..._hackathons, ...result.items];
      _listLastPage = result.lastPage;
      _listPage++;
    } catch (_) {
    } finally {
      _listLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Active hackathon ───────────────────────────────────────────────────────
  Hackathon? _active;
  bool _activeLoading = false;
  String? _activeError;

  Hackathon? get active => _active;
  bool get activeLoading => _activeLoading;
  String? get activeError => _activeError;

  Future<void> loadHackathon(String id) async {
    _activeLoading = true;
    _activeError = null;
    _active = null;
    notifyListeners();
    try {
      _active = await _service.getHackathon(id);
    } catch (e) {
      _activeError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _activeLoading = false;
      notifyListeners();
    }
  }

  // ── Team ───────────────────────────────────────────────────────────────────
  ({String teamId, String name, String inviteCode})? _myTeam;
  List<OpenTeam> _openTeams = [];
  bool _teamsLoading = false;

  ({String teamId, String name, String inviteCode})? get myTeam => _myTeam;
  List<OpenTeam> get openTeams => _openTeams;
  bool get teamsLoading => _teamsLoading;

  Future<({String teamId, String name, String inviteCode})> createTeam(
      String hackId, String name) async {
    final team = await _service.createTeam(hackId, name);
    _myTeam = team;
    notifyListeners();
    return team;
  }

  Future<void> joinTeam(String hackId, String inviteCode) async {
    await _service.joinTeam(hackId, inviteCode);
    await loadHackathon(hackId);
  }

  Future<void> leaveTeam(String hackId) async {
    await _service.leaveTeam(hackId);
    _myTeam = null;
    await loadHackathon(hackId);
  }

  Future<void> loadOpenTeams(String hackId) async {
    _teamsLoading = true;
    notifyListeners();
    try {
      _openTeams = await _service.getOpenTeams(hackId);
    } catch (_) {
    } finally {
      _teamsLoading = false;
      notifyListeners();
    }
  }

  // ── Submission ─────────────────────────────────────────────────────────────
  HackSubmission? _submission;
  List<HackSubmission> _allSubmissions = [];
  bool _submissionLoading = false;
  String? _submissionError;

  HackSubmission? get submission => _submission;
  List<HackSubmission> get allSubmissions => _allSubmissions;
  bool get submissionLoading => _submissionLoading;
  String? get submissionError => _submissionError;

  Future<void> saveSubmission(
    String hackId, {
    required String projectName,
    required String description,
    String? repoUrl,
    String? demoUrl,
    String? videoUrl,
    List<String>? additionalLinks,
  }) async {
    _submissionLoading = true;
    _submissionError = null;
    notifyListeners();
    try {
      _submission = await _service.saveSubmission(
        hackId,
        projectName: projectName,
        description: description,
        repoUrl: repoUrl,
        demoUrl: demoUrl,
        videoUrl: videoUrl,
        additionalLinks: additionalLinks,
      );
    } catch (e) {
      _submissionError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _submissionLoading = false;
      notifyListeners();
    }
  }

  Future<void> finaliseSubmission(String hackId) async {
    await _service.finaliseSubmission(hackId);
    if (_submission != null) {
      _submission = HackSubmission(
        id: _submission!.id,
        projectName: _submission!.projectName,
        description: _submission!.description,
        repoUrl: _submission!.repoUrl,
        demoUrl: _submission!.demoUrl,
        videoUrl: _submission!.videoUrl,
        additionalLinks: _submission!.additionalLinks,
        isFinalised: true,
        teamName: _submission!.teamName,
        submittedAt: _submission!.submittedAt,
      );
      notifyListeners();
    }
  }

  Future<void> loadAllSubmissions(String hackId) async {
    try {
      _allSubmissions = await _service.getSubmissions(hackId);
      notifyListeners();
    } catch (_) {}
  }

  // ── Voting ─────────────────────────────────────────────────────────────────
  VoteStatus? _voteStatus;
  bool _voteLoading = false;
  List<HackLeaderboardEntry> _leaderboard = [];
  bool _lbLoading = false;

  VoteStatus? get voteStatus => _voteStatus;
  bool get voteLoading => _voteLoading;
  List<HackLeaderboardEntry> get leaderboard => _leaderboard;
  bool get lbLoading => _lbLoading;

  Future<void> loadVoteStatus(String hackId) async {
    try {
      _voteStatus = await _service.getVoteStatus(hackId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> castVote(String hackId, String teamId) async {
    _voteLoading = true;
    notifyListeners();
    try {
      await _service.castVote(hackId, teamId);
      await loadVoteStatus(hackId);
      await loadLeaderboard(hackId);
    } finally {
      _voteLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard(String hackId) async {
    _lbLoading = true;
    notifyListeners();
    try {
      _leaderboard = await _service.getLeaderboard(hackId);
    } catch (_) {
    } finally {
      _lbLoading = false;
      notifyListeners();
    }
  }

  // ── Discussion ─────────────────────────────────────────────────────────────
  List<DiscussionComment> _comments = [];
  bool _commentsLoading = false;
  int _commentsPage = 1;
  int _commentsTotal = 0;

  List<DiscussionComment> get comments => _comments;
  bool get commentsLoading => _commentsLoading;
  int get commentsTotal => _commentsTotal;

  Future<void> loadDiscussion(String hackId, {bool refresh = false}) async {
    if (refresh) {
      _commentsPage = 1;
      _comments = [];
    }
    _commentsLoading = true;
    notifyListeners();
    try {
      final result = await _service.getDiscussion(hackId, page: _commentsPage);
      _comments = [..._comments, ...result.comments];
      _commentsTotal = result.total;
      _commentsPage++;
    } catch (_) {
    } finally {
      _commentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> postComment(String hackId, String body) async {
    final comment = await _service.postComment(hackId, body);
    _comments.insert(0, comment);
    _commentsTotal++;
    notifyListeners();
  }

  Future<void> replyToComment(
      String hackId, String commentId, String body) async {
    final reply = await _service.replyToComment(hackId, commentId, body);
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      final updated = DiscussionComment(
        id: _comments[idx].id,
        hackathonId: _comments[idx].hackathonId,
        userId: _comments[idx].userId,
        userName: _comments[idx].userName,
        userProfilePic: _comments[idx].userProfilePic,
        body: _comments[idx].body,
        likesCount: _comments[idx].likesCount,
        likedByMe: _comments[idx].likedByMe,
        repliesCount: _comments[idx].repliesCount + 1,
        replies: [..._comments[idx].replies, reply],
        createdAt: _comments[idx].createdAt,
      );
      _comments[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final prev = _comments[idx];
    // Optimistic update
    _comments[idx] = prev.copyWith(
      likedByMe: !prev.likedByMe,
      likesCount: prev.likedByMe ? prev.likesCount - 1 : prev.likesCount + 1,
    );
    notifyListeners();
    try {
      await _service.likeComment(commentId);
    } catch (_) {
      // Revert on failure
      _comments[idx] = prev;
      notifyListeners();
    }
  }

  Future<void> deleteComment(String commentId) async {
    await _service.deleteComment(commentId);
    _comments.removeWhere((c) => c.id == commentId);
    notifyListeners();
  }

  // ── Mentor ─────────────────────────────────────────────────────────────────
  List<MentorMessage> _mentorMessages = [];
  bool _mentorChatLoading = false;

  List<MentorMessage> get mentorMessages => _mentorMessages;
  bool get mentorChatLoading => _mentorChatLoading;

  Future<void> requestMentor(String hackId, int mentorId) async {
    await _service.requestMentor(hackId, mentorId);
    notifyListeners();
  }

  Future<void> loadMentorChat(String hackId, String teamId) async {
    _mentorChatLoading = true;
    notifyListeners();
    try {
      _mentorMessages = await _service.getMentorChat(hackId, teamId);
    } catch (_) {
    } finally {
      _mentorChatLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMentorMessage(
      String hackId, String teamId, String body) async {
    final msg = await _service.sendMentorMessage(hackId, teamId, body);
    _mentorMessages.insert(0, msg);
    notifyListeners();
  }

  void clearActive() {
    _active = null;
    _submission = null;
    _comments = [];
    _commentsPage = 1;
    _leaderboard = [];
    _mentorMessages = [];
    _openTeams = [];
    _voteStatus = null;
    notifyListeners();
  }
}
