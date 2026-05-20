import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reelscholar/models/reel_models.dart';
import '../core/services/reel_service.dart';

enum FeedType { forYou, following, trending }

enum ReelLoadState { idle, loading, loaded, loadingMore, error }

class ReelProvider extends ChangeNotifier {
  final ReelService _svc = ReelService();

  // ─── Feed state ─────────────────────────────────────────────────────────────
  final Map<FeedType, List<Reel>> _feeds = {
    FeedType.forYou: [],
    FeedType.following: [],
    FeedType.trending: [],
  };
  final Map<FeedType, PaginationMeta?> _feedMetas = {};
  final Map<FeedType, ReelLoadState> _feedStates = {
    FeedType.forYou: ReelLoadState.idle,
    FeedType.following: ReelLoadState.idle,
    FeedType.trending: ReelLoadState.idle,
  };
  FeedType _activeFeed = FeedType.forYou;

  // ─── Current playing reel index ─────────────────────────────────────────────
  int _currentIndex = 0;

  // ─── Comments ────────────────────────────────────────────────────────────────
  List<ReelComment> _comments = [];
  PaginationMeta? _commentsMeta;
  ReelLoadState _commentsState = ReelLoadState.idle;

  // ─── Bookmarks ───────────────────────────────────────────────────────────────
  List<Reel> _bookmarks = [];
  PaginationMeta? _bookmarksMeta;
  ReelLoadState _bookmarksState = ReelLoadState.idle;

  // ─── User reels ──────────────────────────────────────────────────────────────
  final Map<String, List<Reel>> _userReels = {};

  // ─── Search ──────────────────────────────────────────────────────────────────
  List<Reel> _searchResults = [];
  List<Hashtag> _trendingTags = [];
  ReelLoadState _searchState = ReelLoadState.idle;
  String _lastQuery = '';

  // ─── Upload state ────────────────────────────────────────────────────────────
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _uploadError;

  // ─── Pending upload tracking ─────────────────────────────────────────────────
  Reel? _pendingReel;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 24;

  // ─── Trending tags ───────────────────────────────────────────────────────────
  bool _tagsLoaded = false;

  // ─── Global error ────────────────────────────────────────────────────────────
  String? _error;

  // ─── Getters ─────────────────────────────────────────────────────────────────
  FeedType get activeFeed => _activeFeed;
  List<Reel> get currentFeedReels => _feeds[_activeFeed] ?? [];
  ReelLoadState get feedState => _feedStates[_activeFeed] ?? ReelLoadState.idle;
  int get currentIndex => _currentIndex;

  List<Reel> get forYouReels => _feeds[FeedType.forYou] ?? [];
  List<Reel> get trendingReels => _feeds[FeedType.trending] ?? [];
  List<Reel> get followingReels => _feeds[FeedType.following] ?? [];

  List<ReelComment> get comments => _comments;
  ReelLoadState get commentsState => _commentsState;
  bool get hasMoreComments =>
      _commentsMeta != null && _commentsMeta!.hasMore;

  List<Reel> get bookmarks => _bookmarks;
  ReelLoadState get bookmarksState => _bookmarksState;
  bool get hasMoreBookmarks =>
      _bookmarksMeta != null && _bookmarksMeta!.hasMore;

  List<Reel> get searchResults => _searchResults;
  List<Hashtag> get trendingTags => _trendingTags;
  ReelLoadState get searchState => _searchState;

  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  String? get error => _error;

  Reel? get pendingReel => _pendingReel;
  bool get hasPendingReel => _pendingReel != null;

  List<Reel> userReels(String userId) => _userReels[userId] ?? [];

  // ─── Set active feed tab ─────────────────────────────────────────────────────
  void setFeedType(FeedType type) {
    if (_activeFeed == type) return;
    _activeFeed = type;
    _currentIndex = 0;
    notifyListeners();
    if ((_feeds[type] ?? []).isEmpty) loadFeed(type);
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // ─── Load feed ───────────────────────────────────────────────────────────────
  Future<void> loadFeed(FeedType type, {bool refresh = false}) async {
    if (_feedStates[type] == ReelLoadState.loading) return;
    if (!refresh && (_feeds[type] ?? []).isNotEmpty) return;

    _feedStates[type] = ReelLoadState.loading;
    if (refresh) _feeds[type] = [];
    _error = null;
    notifyListeners();

    try {
      final result = await _fetchFeed(type, page: 1);
      _feeds[type] = result.reels;
      _feedMetas[type] = result.meta;
      _feedStates[type] = ReelLoadState.loaded;
    } catch (e) {
      _feedStates[type] = ReelLoadState.error;
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ─── Load more (pagination) ──────────────────────────────────────────────────
  Future<void> loadMoreFeed(FeedType type) async {
    final meta = _feedMetas[type];
    if (meta == null || !meta.hasMore) return;
    if (_feedStates[type] == ReelLoadState.loadingMore) return;

    _feedStates[type] = ReelLoadState.loadingMore;
    notifyListeners();

    try {
      final result = await _fetchFeed(type, page: meta.currentPage + 1);
      _feeds[type] = [...(_feeds[type] ?? []), ...result.reels];
      _feedMetas[type] = result.meta;
      _feedStates[type] = ReelLoadState.loaded;
    } catch (_) {
      _feedStates[type] = ReelLoadState.loaded;
    }
    notifyListeners();
  }

  Future<({List<Reel> reels, PaginationMeta meta})> _fetchFeed(
      FeedType type, {required int page}) {
    switch (type) {
      case FeedType.forYou:
        return _svc.getForYou(page: page);
      case FeedType.trending:
        return _svc.getTrending(page: page);
      case FeedType.following:
        return _svc.getFeed(page: page);
    }
  }

  // ─── Refresh current feed ────────────────────────────────────────────────────
  Future<void> refreshFeed() => loadFeed(_activeFeed, refresh: true);

  // ─── Load initial feeds ──────────────────────────────────────────────────────
  Future<void> initialLoad() async {
    await loadFeed(FeedType.forYou);
  }

  // ─── Like toggle (optimistic) ────────────────────────────────────────────────
  Future<void> toggleLike(String reelId) async {
    _updateReel(reelId, (r) {
      final liked = !r.isLiked;
      return r.copyWith(
        isLiked: liked,
        likeCount: liked ? r.likeCount + 1 : r.likeCount - 1,
      );
    });
    notifyListeners();

    try {
      await _svc.toggleLike(reelId);
    } catch (_) {
      // Revert optimistic update
      _updateReel(reelId, (r) => r.copyWith(
            isLiked: !r.isLiked,
            likeCount: r.isLiked ? r.likeCount - 1 : r.likeCount + 1,
          ));
      notifyListeners();
    }
  }

  // ─── Bookmark toggle (optimistic) ───────────────────────────────────────────
  Future<void> toggleBookmark(String reelId) async {
    _updateReel(reelId, (r) {
      final bm = !r.isBookmarked;
      return r.copyWith(
        isBookmarked: bm,
        bookmarkCount: bm ? r.bookmarkCount + 1 : r.bookmarkCount - 1,
      );
    });
    notifyListeners();

    try {
      await _svc.toggleBookmark(reelId);
      // Update bookmarks list
      final reel = _findReel(reelId);
      if (reel != null) {
        if (reel.isBookmarked) {
          _bookmarks = [reel, ..._bookmarks];
        } else {
          _bookmarks.removeWhere((r) => r.id == reelId);
        }
      }
    } catch (_) {
      _updateReel(reelId, (r) => r.copyWith(
            isBookmarked: !r.isBookmarked,
            bookmarkCount: r.isBookmarked ? r.bookmarkCount - 1 : r.bookmarkCount + 1,
          ));
      notifyListeners();
    }
  }

  // ─── Record view ─────────────────────────────────────────────────────────────
  Future<void> recordView(String reelId, {int? watchSeconds}) async {
    _svc.recordView(reelId, watchSeconds: watchSeconds); // fire & forget
    _updateReel(reelId, (r) => r.copyWith(viewCount: r.viewCount + 1));
    notifyListeners();
  }

  // ─── Share ───────────────────────────────────────────────────────────────────
  Future<void> recordShare(String reelId) async {
    await _svc.recordShare(reelId);
    _updateReel(reelId, (r) => r.copyWith(shareCount: r.shareCount + 1));
    notifyListeners();
  }

  // ─── Comments ────────────────────────────────────────────────────────────────
  Future<void> loadComments(String reelId, {bool refresh = false}) async {
    if (_commentsState == ReelLoadState.loading && !refresh) return;
    if (refresh) _comments = [];
    _commentsState = ReelLoadState.loading;
    notifyListeners();

    try {
      final result = await _svc.getComments(reelId);
      _comments = result.comments;
      _commentsMeta = result.meta;
      _commentsState = ReelLoadState.loaded;
    } catch (e) {
      _commentsState = ReelLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMoreComments(String reelId) async {
    final meta = _commentsMeta;
    if (meta == null || !meta.hasMore) return;
    if (_commentsState == ReelLoadState.loadingMore) return;

    _commentsState = ReelLoadState.loadingMore;
    notifyListeners();

    try {
      final result =
          await _svc.getComments(reelId, page: meta.currentPage + 1);
      _comments = [..._comments, ...result.comments];
      _commentsMeta = result.meta;
    } catch (_) {}
    _commentsState = ReelLoadState.loaded;
    notifyListeners();
  }

  Future<ReelComment?> postComment(String reelId, String body) async {
    try {
      final comment = await _svc.postComment(reelId, body);
      _comments = [comment, ..._comments];
      _updateReel(reelId,
          (r) => r.copyWith(commentCount: r.commentCount + 1));
      notifyListeners();
      return comment;
    } catch (_) {
      return null;
    }
  }

  Future<void> replyToComment(
    String reelId,
    String commentId,
    String body, {
    String? replyToUserId,
  }) async {
    try {
      final reply = await _svc.replyToComment(commentId, body,
          replyToUserId: replyToUserId);
      final idx = _comments.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        _comments[idx].replies = [..._comments[idx].replies, reply];
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleCommentLike(String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;
    final c = _comments[idx];
    _comments[idx].isLiked = !c.isLiked;
    _comments[idx].likeCount += c.isLiked ? 1 : -1;
    notifyListeners();
    try {
      await _svc.toggleCommentLike(commentId);
    } catch (_) {
      _comments[idx].isLiked = c.isLiked;
      _comments[idx].likeCount = c.likeCount;
      notifyListeners();
    }
  }

  Future<void> deleteComment(String reelId, String commentId) async {
    await _svc.deleteComment(commentId);
    _comments.removeWhere((c) => c.id == commentId);
    _updateReel(reelId,
        (r) => r.copyWith(commentCount: r.commentCount - 1));
    notifyListeners();
  }

  // ─── Bookmarks ───────────────────────────────────────────────────────────────
  Future<void> loadBookmarks({bool refresh = false}) async {
    if (refresh) _bookmarks = [];
    _bookmarksState = ReelLoadState.loading;
    notifyListeners();

    try {
      final result = await _svc.getBookmarks();
      _bookmarks = result.reels;
      _bookmarksMeta = result.meta;
      _bookmarksState = ReelLoadState.loaded;
    } catch (_) {
      _bookmarksState = ReelLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadMoreBookmarks() async {
    final meta = _bookmarksMeta;
    if (meta == null || !meta.hasMore) return;
    _bookmarksState = ReelLoadState.loadingMore;
    notifyListeners();

    try {
      final result = await _svc.getBookmarks(page: meta.currentPage + 1);
      _bookmarks = [..._bookmarks, ...result.reels];
      _bookmarksMeta = result.meta;
    } catch (_) {}
    _bookmarksState = ReelLoadState.loaded;
    notifyListeners();
  }

  // ─── Search ──────────────────────────────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchState = ReelLoadState.idle;
      _lastQuery = '';
      notifyListeners();
      return;
    }

    _lastQuery = query;
    _searchState = ReelLoadState.loading;
    notifyListeners();

    try {
      final result = await _svc.search(query);
      if (_lastQuery == query) {
        _searchResults = result.reels;
        _searchState = ReelLoadState.loaded;
      }
    } catch (_) {
      _searchState = ReelLoadState.error;
    }
    notifyListeners();
  }

  Future<void> loadTrendingTags() async {
    if (_tagsLoaded) return;
    try {
      _trendingTags = await _svc.getTrendingTags();
      _tagsLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  // ─── User reels ──────────────────────────────────────────────────────────────
  Future<void> loadUserReels(String userId) async {
    if (_userReels.containsKey(userId)) return;
    try {
      final result = await _svc.getUserReels(userId);
      _userReels[userId] = result.reels;
      notifyListeners();
    } catch (_) {}
  }

  // ─── Upload ──────────────────────────────────────────────────────────────────
  Future<Reel?> uploadReel({
    required XFile video,
    String? caption,
    int? topicId,
  }) async {
    _isUploading = true;
    _uploadProgress = 0;
    _uploadError = null;
    notifyListeners();

    try {
      final reel = await _svc.uploadReel(
        video: video,
        caption: caption,
        topicId: topicId,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      _isUploading = false;

      // Add to uploader's own grid immediately so the status badge shows.
      final uploaderId = reel.uploader.uid;
      if (uploaderId.isNotEmpty && _userReels.containsKey(uploaderId)) {
        _userReels[uploaderId] = [reel, ...(_userReels[uploaderId] ?? [])];
      }

      // Only add to the public feed if already visible; otherwise start polling.
      if (reel.isVisible) {
        _feeds[FeedType.forYou] = [reel, ...(_feeds[FeedType.forYou] ?? [])];
      } else {
        _startPolling(reel);
      }

      notifyListeners();
      return reel;
    } catch (e) {
      _uploadError = e.toString().replaceFirst('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return null;
    }
  }

  // ─── Validation polling ───────────────────────────────────────────────────────
  void _startPolling(Reel reel) {
    _pollTimer?.cancel();
    _pendingReel = reel;
    _pollAttempts = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _pollAttempts++;

      try {
        final result = await _svc.getReelStatus(reel.id);
        final updated = (_pendingReel ?? reel).copyWith(
          moderationStatus: result.status,
          moderationReason: result.reason,
          isVisible: result.isVisible,
        );

        // Mirror updated status onto the uploader's grid cache.
        final uploaderId = reel.uploader.uid;
        if (uploaderId.isNotEmpty && _userReels.containsKey(uploaderId)) {
          final list = _userReels[uploaderId]!;
          final idx = list.indexWhere((r) => r.id == reel.id);
          if (idx != -1) list[idx] = updated;
        }

        _pendingReel = updated;

        if (updated.hasTerminalStatus) {
          timer.cancel();
          _pollTimer = null;

          if (updated.isVisible) {
            final feed = _feeds[FeedType.forYou] ?? [];
            if (!feed.any((r) => r.id == updated.id)) {
              _feeds[FeedType.forYou] = [updated, ...feed];
            }
          }
        }

        notifyListeners();
      } catch (_) {
        // Network blip — keep trying.
      }

      if (_pollAttempts >= _maxPollAttempts) {
        timer.cancel();
        _pollTimer = null;
      }
    });
  }

  void dismissPendingReel() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pendingReel = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Delete reel ─────────────────────────────────────────────────────────────
  Future<void> deleteReel(String reelId) async {
    await _svc.deleteReel(reelId);
    for (final type in FeedType.values) {
      _feeds[type]?.removeWhere((r) => r.id == reelId);
    }
    _bookmarks.removeWhere((r) => r.id == reelId);
    notifyListeners();
  }

  // ─── Uploader follow state sync ──────────────────────────────────────────────
  void updateUploaderFollowState(String uploaderUid, bool isFollowing) {
    for (final type in FeedType.values) {
      final list = _feeds[type];
      if (list == null) continue;
      for (int i = 0; i < list.length; i++) {
        if (list[i].uploader.uid == uploaderUid) {
          list[i] = list[i].copyWith(
            uploader: list[i].uploader.copyWith(isFollowing: isFollowing),
          );
        }
      }
    }
    notifyListeners();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  void _updateReel(String id, Reel Function(Reel) update) {
    for (final type in FeedType.values) {
      final list = _feeds[type];
      if (list == null) continue;
      final idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) {
        list[idx] = update(list[idx]);
      }
    }
    final bi = _bookmarks.indexWhere((r) => r.id == id);
    if (bi != -1) _bookmarks[bi] = update(_bookmarks[bi]);

    final si = _searchResults.indexWhere((r) => r.id == id);
    if (si != -1) _searchResults[si] = update(_searchResults[si]);
  }

  Reel? _findReel(String id) {
    for (final type in FeedType.values) {
      final r = _feeds[type]?.firstWhere((r) => r.id == id,
          orElse: () => _feeds[type]!.first);
      if (r?.id == id) return r;
    }
    return null;
  }

  void clearComments() {
    _comments = [];
    _commentsMeta = null;
    _commentsState = ReelLoadState.idle;
  }
}
