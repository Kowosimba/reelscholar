import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:reelscholar/core/services/messaging_service.dart';
import 'package:reelscholar/models/messaging_models.dart';

class MessagingProvider extends ChangeNotifier {
  MessagingProvider(this._service);

  final MessagingService _service;

  String _currentUserId = '';

  String get currentUserId => _currentUserId;

  void syncFromAuth(String? uid) {
    final id = uid ?? '';
    if (id.isEmpty) {
      if (_currentUserId.isEmpty && _conversations.isEmpty) return;
      clear();
      return;
    }
    if (_currentUserId == id) return;
    _currentUserId = id;
    notifyListeners();
  }

  void clear() {
    _typingDebounce?.cancel();
    _typingTimeout?.cancel();
    if (_isSelfTyping && _activeConversation != null) {
      _service.stopTyping(_activeConversation!.id);
      _isSelfTyping = false;
    }
    _activeConversation = null;
    _messages = [];
    _conversations = [];
    _requests = [];
    _convsError = null;
    _messagesError = null;
    _replyingTo = null;
    _remoteTyping = false;
    _currentUserId = '';
    notifyListeners();
  }

  // ── Conversations list ────────────────────────────────────────────────────
  List<Conversation> _conversations = [];
  bool _convsLoading = false;
  String? _convsError;
  String _filterType = 'all';

  List<Conversation> get conversations => _conversations;
  bool get convsLoading => _convsLoading;
  String? get convsError => _convsError;
  String get filterType => _filterType;

  List<Conversation> get filteredConversations {
    if (_filterType == 'all') return _conversations;
    return _conversations.where((c) => c.type == _filterType).toList();
  }

  int get totalUnread =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  Future<void> loadConversations({bool refresh = false}) async {
    if (_convsLoading && !refresh) return;
    _convsLoading = true;
    _convsError = null;
    notifyListeners();
    try {
      _conversations = await _service.getConversations(type: _filterType);
      _conversations.sort((a, b) {
        final aT = a.lastMessageAt ?? DateTime(2000);
        final bT = b.lastMessageAt ?? DateTime(2000);
        return bT.compareTo(aT);
      });
    } catch (e) {
      _convsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _convsLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String type) {
    if (_filterType == type) return;
    _filterType = type;
    notifyListeners();
    loadConversations(refresh: true);
  }

  // ── Active conversation / message thread ──────────────────────────────────
  Conversation? _activeConversation;
  List<ConvMessage> _messages = [];
  bool _messagesLoading = false;
  String? _messagesError;
  bool _hasMoreMessages = true;
  int _messagePage = 1;

  bool _remoteTyping = false;
  Timer? _typingDebounce;
  Timer? _typingTimeout;
  bool _isSelfTyping = false;

  ConvMessage? _replyingTo;

  Conversation? get activeConversation => _activeConversation;
  List<ConvMessage> get messages => _messages;
  bool get messagesLoading => _messagesLoading;
  String? get messagesError => _messagesError;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get remoteTyping => _remoteTyping;
  ConvMessage? get replyingTo => _replyingTo;

  Future<void> openConversation(Conversation conversation) async {
    _activeConversation = conversation;
    _messages = [];
    _messagePage = 1;
    _hasMoreMessages = true;
    _replyingTo = null;
    _remoteTyping = false;
    notifyListeners();
    await _loadMessages();
    await _service.markAsRead(conversation.id);
    _updateConvUnread(conversation.id, 0);
  }

  Future<void> openConversationById(String conversationId) async {
    Conversation? existing;
    for (final c in _conversations) {
      if (c.id == conversationId) {
        existing = c;
        break;
      }
    }
    final conv =
        existing ?? await _service.getConversation(conversationId);
    await openConversation(conv);
  }

  Future<void> _loadMessages({bool append = false}) async {
    if (_activeConversation == null) return;
    _messagesLoading = true;
    _messagesError = null;
    if (!append) notifyListeners();
    try {
      final page = append ? _messagePage : 1;
      final result = await _service.getMessages(
        _activeConversation!.id,
        page: page,
      );
      _hasMoreMessages = result.currentPage < result.lastPage;
      if (result.items.isEmpty) {
        _hasMoreMessages = false;
      } else {
        if (append) {
          _messages.addAll(result.items);
        } else {
          _messages = result.items;
        }
        _messagePage = result.currentPage + 1;
        _hasMoreMessages = result.currentPage < result.lastPage;
      }
    } catch (e) {
      _messagesError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _messagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (!_hasMoreMessages || _messagesLoading || _activeConversation == null) {
      return;
    }
    await _loadMessages(append: true);
  }

  void setReplyingTo(ConvMessage? message) {
    _replyingTo = message;
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    if (_activeConversation == null || text.trim().isEmpty) return;
    final convId = _activeConversation!.id;
    final replyId = _replyingTo?.id;
    _replyingTo = null;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ConvMessage(
      id: tempId,
      conversationId: convId,
      sender: MessageSender(
        uid: _currentUserId,
        name: 'You',
        profilePic: null,
      ),
      body: text.trim(),
      type: 'text',
      attachments: [],
      reactions: {},
      isRead: false,
      readByCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isPending: true,
    );
    _messages.insert(0, optimistic);
    _updateConvPreview(convId, text.trim());
    notifyListeners();

    try {
      await _stopTypingImmediate();
      final sent = await _service.sendTextMessage(
        convId,
        text.trim(),
        replyToMessageId: replyId,
      );
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _messages[idx] = sent;
        notifyListeners();
      }
    } catch (_) {
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        _messages[idx] =
            _messages[idx].copyWith(isFailed: true, isPending: false);
        notifyListeners();
      }
    }
  }

  Future<void> sendMedia(List<File> files, {String? caption}) async {
    if (_activeConversation == null) return;
    final sent = await _service.sendMediaMessage(
      _activeConversation!.id,
      files,
      caption: caption,
    );
    _messages.insert(0, sent);
    notifyListeners();
  }

  void onInputChanged(String value) {
    if (_activeConversation == null) return;
    if (value.isEmpty) {
      _typingDebounce?.cancel();
      if (_isSelfTyping) _stopTypingImmediate();
      return;
    }
    if (!_isSelfTyping) {
      _isSelfTyping = true;
      _service.startTyping(_activeConversation!.id);
    }
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 3), () {
      _stopTypingImmediate();
    });
  }

  Future<void> _stopTypingImmediate() async {
    _typingDebounce?.cancel();
    if (_isSelfTyping && _activeConversation != null) {
      _isSelfTyping = false;
      await _service.stopTyping(_activeConversation!.id);
    }
  }

  void setRemoteTyping(bool typing) {
    _remoteTyping = typing;
    notifyListeners();
    if (typing) {
      _typingTimeout?.cancel();
      _typingTimeout = Timer(const Duration(seconds: 5), () {
        _remoteTyping = false;
        notifyListeners();
      });
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      final result = await _service.reactToMessage(messageId, emoji);
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        final updatedReactions = <String, List<String>>{};
        result.reactions.forEach((k, v) {
          if (v is List) {
            updatedReactions[k] =
                v.map((e) => e.toString()).toList();
          }
        });
        _messages[idx] = _messages[idx].copyWith(reactions: updatedReactions);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final removed = _messages.removeAt(idx);
    notifyListeners();
    try {
      await _service.deleteMessage(messageId);
    } catch (_) {
      _messages.insert(idx, removed);
      notifyListeners();
    }
  }

  Future<void> toggleMute(String convId, bool mute) async {
    await _service.toggleMute(convId, mute: mute);
    await loadConversations(refresh: true);
  }

  List<MessageRequest> _requests = [];
  bool _requestsLoading = false;
  String? _requestsError;

  List<MessageRequest> get requests => _requests;
  bool get requestsLoading => _requestsLoading;
  String? get requestsError => _requestsError;
  int get pendingRequestCount => _requests.where((r) => r.isPending).length;

  Future<void> loadRequests() async {
    _requestsLoading = true;
    _requestsError = null;
    notifyListeners();
    try {
      _requests = await _service.getMessageRequests(status: 'pending');
    } catch (e) {
      _requestsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _requestsLoading = false;
      notifyListeners();
    }
  }

  Future<Conversation> acceptRequest(String requestId) async {
    final conv = await _service.acceptRequest(requestId);
    _requests.removeWhere((r) => r.id == requestId);
    _conversations.removeWhere((c) => c.id == conv.id);
    _conversations.insert(0, conv);
    notifyListeners();
    return conv;
  }

  Future<void> rejectRequest(String requestId) async {
    await _service.rejectRequest(requestId);
    _requests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  void _updateConvUnread(String convId, int count) {
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: count);
      notifyListeners();
    }
  }

  void _updateConvPreview(String convId, String preview) {
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessagePreview: preview,
        lastMessageAt: DateTime.now(),
      );
      final updated = _conversations.removeAt(idx);
      _conversations.insert(0, updated);
      notifyListeners();
    }
  }

  void closeConversation() {
    _typingDebounce?.cancel();
    _typingTimeout?.cancel();
    if (_isSelfTyping && _activeConversation != null) {
      _service.stopTyping(_activeConversation!.id);
      _isSelfTyping = false;
    }
    _activeConversation = null;
    _messages = [];
    _replyingTo = null;
    _remoteTyping = false;
    _hasMoreMessages = true;
    _messagePage = 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _typingTimeout?.cancel();
    super.dispose();
  }
}
