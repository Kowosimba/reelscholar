// lib/features/study_groups/providers/study_group_provider.dart

import 'package:flutter/foundation.dart';
import 'package:reelscholar/models/study_group_models.dart';
import 'package:reelscholar/core/services/study_group_service.dart';

class StudyGroupProvider extends ChangeNotifier {
  final StudyGroupService _service;

  StudyGroupProvider(this._service);

  // ── Browse public groups ──────────────────────────────────────────────────
  List<StudyGroup> _publicGroups = [];
  bool _browseLoading = false;
  bool _browseLoadingMore = false;
  String? _browseError;
  int _browsePage = 1;
  int _browseLastPage = 1;
  String _searchQuery = '';

  List<StudyGroup> get publicGroups => _publicGroups;
  bool get browseLoading => _browseLoading;
  bool get browseLoadingMore => _browseLoadingMore;
  String? get browseError => _browseError;
  bool get hasMoreGroups => _browsePage <= _browseLastPage;
  String get searchQuery => _searchQuery;

  Future<void> browseGroups({bool refresh = false}) async {
    if (refresh) {
      _browsePage = 1;
      _publicGroups = [];
    }
    if (_browseLoading) return;
    _browseLoading = true;
    _browseError = null;
    notifyListeners();
    try {
      final result = await _service.browseGroups(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _browsePage,
      );
      _publicGroups = [..._publicGroups, ...result.groups];
      _browseLastPage = result.lastPage;
      _browsePage++;
    } catch (e) {
      _browseError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _browseLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreGroups() async {
    if (_browseLoadingMore || !hasMoreGroups) return;
    _browseLoadingMore = true;
    notifyListeners();
    try {
      final result = await _service.browseGroups(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _browsePage,
      );
      _publicGroups = [..._publicGroups, ...result.groups];
      _browseLastPage = result.lastPage;
      _browsePage++;
    } catch (_) {
    } finally {
      _browseLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearch(String q) {
    _searchQuery = q;
    browseGroups(refresh: true);
  }

  // ── My groups ─────────────────────────────────────────────────────────────
  List<StudyGroup> _myGroups = [];
  bool _myLoading = false;
  String? _myError;

  List<StudyGroup> get myGroups => _myGroups;
  bool get myLoading => _myLoading;
  String? get myError => _myError;

  Future<void> loadMyGroups({bool refresh = false}) async {
    if (_myLoading) return;
    if (_myGroups.isNotEmpty && !refresh) return;
    _myLoading = true;
    _myError = null;
    notifyListeners();
    try {
      _myGroups = await _service.getMyGroups();
    } catch (e) {
      _myError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _myLoading = false;
      notifyListeners();
    }
  }

  // ── Active group detail ───────────────────────────────────────────────────
  StudyGroup? _activeGroup;
  bool _groupLoading = false;
  String? _groupError;

  StudyGroup? get activeGroup => _activeGroup;
  bool get groupLoading => _groupLoading;
  String? get groupError => _groupError;

  Future<void> loadGroup(String id) async {
    _groupLoading = true;
    _groupError = null;
    notifyListeners();
    try {
      _activeGroup = await _service.getGroup(id);
    } catch (e) {
      _groupError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _groupLoading = false;
      notifyListeners();
    }
  }

  Future<StudyGroup> createGroup({
    required String name,
    String? description,
    String? subject,
    bool isPublic = true,
    bool adminOnlyMessaging = false,
  }) async {
    final group = await _service.createGroup(
      name: name,
      description: description,
      subject: subject,
      isPublic: isPublic,
      adminOnlyMessaging: adminOnlyMessaging,
    );
    _myGroups.insert(0, group);
    notifyListeners();
    return group;
  }

  Future<void> updateGroup(
    String id, {
    String? name,
    String? description,
    String? subject,
    bool? isPublic,
    bool? adminOnlyMessaging,
  }) async {
    final updated = await _service.updateGroup(
      id,
      name: name,
      description: description,
      subject: subject,
      isPublic: isPublic,
      adminOnlyMessaging: adminOnlyMessaging,
    );
    _activeGroup = updated;
    _refreshInList(updated);
    notifyListeners();
  }

  Future<void> deleteGroup(String id) async {
    await _service.deleteGroup(id);
    _myGroups.removeWhere((g) => g.id == id);
    if (_activeGroup?.id == id) _activeGroup = null;
    notifyListeners();
  }

  Future<void> leaveGroup(String id) async {
    await _service.leaveGroup(id);
    _myGroups.removeWhere((g) => g.id == id);
    if (_activeGroup?.id == id) _activeGroup = null;
    notifyListeners();
  }

  // Send a join request (public group) or just join
  Future<void> requestToJoin(String groupId) async {
    await _service.sendJoinRequest(groupId);
    // Mark the group as pending in browse list
    _publicGroups.indexWhere((g) => g.id == groupId);
    notifyListeners();
  }

  // ── Members ───────────────────────────────────────────────────────────────
  List<GroupMember> _members = [];
  bool _membersLoading = false;

  List<GroupMember> get members => _members;
  bool get membersLoading => _membersLoading;

  Future<void> loadMembers(String groupId) async {
    _membersLoading = true;
    notifyListeners();
    try {
      _members = await _service.getMembers(groupId);
    } catch (_) {
    } finally {
      _membersLoading = false;
      notifyListeners();
    }
  }

  Future<void> promoteMember(String groupId, String userId) async {
    await _service.promoteMember(groupId, userId);
    final idx = _members.indexWhere((m) => m.id == userId);
    if (idx != -1) {
      _members[idx] = GroupMember(
        id: _members[idx].id,
        name: _members[idx].name,
        profilePic: _members[idx].profilePic,
        role: 'admin',
        joinedAt: _members[idx].joinedAt,
      );
      notifyListeners();
    }
  }

  Future<void> demoteMember(String groupId, String userId) async {
    await _service.demoteMember(groupId, userId);
    final idx = _members.indexWhere((m) => m.id == userId);
    if (idx != -1) {
      _members[idx] = GroupMember(
        id: _members[idx].id,
        name: _members[idx].name,
        profilePic: _members[idx].profilePic,
        role: 'member',
        joinedAt: _members[idx].joinedAt,
      );
      notifyListeners();
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _service.removeMember(groupId, userId);
    _members.removeWhere((m) => m.id == userId);
    notifyListeners();
  }

  // ── Join requests ─────────────────────────────────────────────────────────
  List<JoinRequest> _joinRequests = [];
  bool _requestsLoading = false;
  int _pendingRequestCount = 0;

  List<JoinRequest> get joinRequests => _joinRequests;
  bool get requestsLoading => _requestsLoading;
  int get pendingRequestCount => _pendingRequestCount;

  Future<void> loadJoinRequests(String groupId) async {
    _requestsLoading = true;
    notifyListeners();
    try {
      _joinRequests = await _service.getJoinRequests(groupId);
      _pendingRequestCount =
          _joinRequests.where((r) => r.isPending).length;
    } catch (_) {
    } finally {
      _requestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveRequest(String groupId, String requestId) async {
    await _service.approveRequest(groupId, requestId);
    _joinRequests.removeWhere((r) => r.id == requestId);
    _pendingRequestCount =
        _joinRequests.where((r) => r.isPending).length;
    notifyListeners();
    await loadMembers(groupId);
  }

  Future<void> rejectRequest(String groupId, String requestId) async {
    await _service.rejectRequest(groupId, requestId);
    _joinRequests.removeWhere((r) => r.id == requestId);
    _pendingRequestCount =
        _joinRequests.where((r) => r.isPending).length;
    notifyListeners();
  }

  // ── Invites ───────────────────────────────────────────────────────────────
  List<GroupInvite> _myInvites = [];
  bool _invitesLoading = false;

  List<GroupInvite> get myInvites => _myInvites;
  bool get invitesLoading => _invitesLoading;
  int get pendingInviteCount =>
      _myInvites.where((i) => i.isPending).length;

  Future<void> loadMyInvites() async {
    _invitesLoading = true;
    notifyListeners();
    try {
      _myInvites = await _service.getMyInvites();
    } catch (_) {
    } finally {
      _invitesLoading = false;
      notifyListeners();
    }
  }

  Future<StudyGroup?> acceptInvite(String token) async {
    await _service.acceptInvite(token);
    _myInvites.removeWhere((i) => i.token == token);
    notifyListeners();
    await loadMyGroups(refresh: true);
    return null; // caller can navigate to group
  }

  Future<void> declineInvite(String token) async {
    await _service.declineInvite(token);
    _myInvites.removeWhere((i) => i.token == token);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _refreshInList(StudyGroup updated) {
    final idx = _myGroups.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _myGroups[idx] = updated;
    final pi = _publicGroups.indexWhere((g) => g.id == updated.id);
    if (pi != -1) _publicGroups[pi] = updated;
  }

  void clearActiveGroup() {
    _activeGroup = null;
    _members = [];
    _joinRequests = [];
    notifyListeners();
  }
}
