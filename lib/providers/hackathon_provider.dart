// lib/providers/hackathon_provider.dart

import 'dart:async';
import 'dart:io';

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
    try {
      await loadHackathon(hackId);
    } catch (_) {}
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

  Future<void> updateProgress(
    String hackId, {
    required String step,
    required int percentage,
    String? notes,
    List<bool>? checklist,
  }) async {
    await _service.updateProgress(hackId,
        step: step,
        percentage: percentage,
        notes: notes,
        checklist: checklist);
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
      final result =
          await _service.getDiscussion(hackId, page: _commentsPage);
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
      final c = _comments[idx];
      _comments[idx] = DiscussionComment(
        id: c.id,
        hackathonId: c.hackathonId,
        userId: c.userId,
        userName: c.userName,
        userProfilePic: c.userProfilePic,
        userBadge: c.userBadge,
        body: c.body,
        likesCount: c.likesCount,
        likedByMe: c.likedByMe,
        repliesCount: c.repliesCount + 1,
        hasMoreReplies: c.hasMoreReplies,
        replies: [...c.replies, reply],
        replyTo: c.replyTo,
        createdAt: c.createdAt,
      );
      notifyListeners();
    }
  }

  Future<void> toggleLike(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final prev = _comments[idx];
    _comments[idx] = prev.copyWith(
      likedByMe: !prev.likedByMe,
      likesCount: prev.likedByMe ? prev.likesCount - 1 : prev.likesCount + 1,
    );
    notifyListeners();
    try {
      await _service.likeComment(commentId);
    } catch (_) {
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

  // ── Team chat ──────────────────────────────────────────────────────────────
  List<HackTeamMessage> _teamChatMessages = [];
  bool _teamChatLoading = false;
  String? _teamChatError;
  int _teamChatNextPage = 1;
  bool _teamChatHasMore = true;
  bool _teamChatRemoteTyping = false;
  HackTeamMessage? _teamChatReplyingTo;
  bool _teamChatIsSelfTyping = false;
  Timer? _teamChatTypingDebounce;
  Timer? _teamChatTypingTimeout;

  List<HackTeamMessage> get teamChatMessages => _teamChatMessages;
  bool get teamChatLoading => _teamChatLoading;
  String? get teamChatError => _teamChatError;
  bool get teamChatHasMore => _teamChatHasMore;
  bool get teamChatRemoteTyping => _teamChatRemoteTyping;
  HackTeamMessage? get teamChatReplyingTo => _teamChatReplyingTo;

  Future<void> loadTeamChat(String hackId, String teamId,
      {bool refresh = false}) async {
    if (refresh) {
      _teamChatNextPage = 1;
      _teamChatMessages = [];
      _teamChatHasMore = true;
    }
    _teamChatLoading = true;
    _teamChatError = null;
    notifyListeners();
    try {
      final result = await _service.getTeamChat(hackId, teamId, page: 1);
      _teamChatMessages = result.items;
      _teamChatNextPage = result.nextPage;
      _teamChatHasMore = result.hasMore;
    } catch (e) {
      _teamChatError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _teamChatLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTeamChat(String hackId, String teamId) async {
    if (!_teamChatHasMore || _teamChatLoading) return;
    _teamChatLoading = true;
    notifyListeners();
    try {
      final result = await _service.getTeamChat(
        hackId,
        teamId,
        page: _teamChatNextPage,
      );
      _teamChatMessages.addAll(result.items);
      _teamChatNextPage = result.nextPage;
      _teamChatHasMore = result.hasMore;
    } catch (_) {
    } finally {
      _teamChatLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendTeamChatText(
    String hackId,
    String teamId,
    String text,
    String currentUserId,
  ) async {
    if (text.trim().isEmpty) return;
    final replyId = _teamChatReplyingTo?.id;
    _teamChatReplyingTo = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = HackTeamMessage(
      id: tempId,
      hackathonId: hackId,
      teamId: teamId,
      sender: HackTeamMessageSender(uid: currentUserId, name: 'You'),
      body: text.trim(),
      type: 'text',
      attachments: [],
      reactions: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPending: true,
    );
    _teamChatMessages.insert(0, optimistic);
    notifyListeners();

    try {
      await _stopTeamChatTypingImmediate(hackId, teamId);
      final sent = await _service.sendTeamChatText(
        hackId,
        teamId,
        text.trim(),
        replyToId: replyId,
      );
      final idx = _teamChatMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _teamChatMessages[idx] = sent;
        notifyListeners();
      }
    } catch (e) {
      final idx = _teamChatMessages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _teamChatMessages[idx] =
            _teamChatMessages[idx].copyWith(isFailed: true, isPending: false);
        notifyListeners();
      }
    }
  }

  Future<void> sendTeamChatMedia(
    String hackId,
    String teamId,
    List<File> files, {
    String? caption,
  }) async {
    try {
      final sent = await _service.sendTeamChatMedia(
        hackId,
        teamId,
        files,
        caption: caption,
      );
      _teamChatMessages.insert(0, sent);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> reactToTeamChatMessage(
    String hackId,
    String teamId,
    String messageId,
    String emoji,
  ) async {
    try {
      final reactions = await _service.reactToTeamChatMessage(
          hackId, teamId, messageId, emoji);
      final idx = _teamChatMessages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _teamChatMessages[idx] =
            _teamChatMessages[idx].copyWith(reactions: reactions);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteTeamChatMessage(
    String hackId,
    String teamId,
    String messageId,
  ) async {
    final idx = _teamChatMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final removed = _teamChatMessages.removeAt(idx);
    notifyListeners();
    try {
      await _service.deleteTeamChatMessage(hackId, teamId, messageId);
    } catch (_) {
      _teamChatMessages.insert(idx, removed);
      notifyListeners();
    }
  }

  void setTeamChatReplyingTo(HackTeamMessage? msg) {
    _teamChatReplyingTo = msg;
    notifyListeners();
  }

  void onTeamChatInputChanged(String hackId, String teamId, String value) {
    if (value.isEmpty) {
      _teamChatTypingDebounce?.cancel();
      if (_teamChatIsSelfTyping) {
        _stopTeamChatTypingImmediate(hackId, teamId);
      }
      return;
    }
    if (!_teamChatIsSelfTyping) {
      _teamChatIsSelfTyping = true;
      _service.startTeamChatTyping(hackId, teamId);
    }
    _teamChatTypingDebounce?.cancel();
    _teamChatTypingDebounce = Timer(const Duration(seconds: 3), () {
      _stopTeamChatTypingImmediate(hackId, teamId);
    });
  }

  Future<void> _stopTeamChatTypingImmediate(
      String hackId, String teamId) async {
    _teamChatTypingDebounce?.cancel();
    if (_teamChatIsSelfTyping) {
      _teamChatIsSelfTyping = false;
      await _service.stopTeamChatTyping(hackId, teamId);
    }
  }

  void setTeamChatRemoteTyping(bool typing) {
    _teamChatRemoteTyping = typing;
    notifyListeners();
    if (typing) {
      _teamChatTypingTimeout?.cancel();
      _teamChatTypingTimeout = Timer(const Duration(seconds: 5), () {
        _teamChatRemoteTyping = false;
        notifyListeners();
      });
    }
  }

  Future<void> pollTeamChatTyping(String hackId, String teamId) async {
    try {
      final users =
          await _service.getTeamChatTypingUsers(hackId, teamId);
      setTeamChatRemoteTyping(users.isNotEmpty);
    } catch (_) {}
  }

  // ── Clear / dispose ────────────────────────────────────────────────────────
  void clearActive() {
    _active = null;
    _submission = null;
    _comments = [];
    _commentsPage = 1;
    _leaderboard = [];
    _mentorMessages = [];
    _openTeams = [];
    _voteStatus = null;
    _teamChatMessages = [];
    _teamChatNextPage = 1;
    _teamChatHasMore = true;
    _teamChatRemoteTyping = false;
    _teamChatReplyingTo = null;
    _teamChatTypingDebounce?.cancel();
    _teamChatTypingTimeout?.cancel();
    _teamChatIsSelfTyping = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _teamChatTypingDebounce?.cancel();
    _teamChatTypingTimeout?.cancel();
    super.dispose();
  }
}
