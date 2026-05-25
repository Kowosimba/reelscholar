// lib/screens/hackathons/team_chat_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class TeamChatScreen extends StatefulWidget {
  final String hackId;
  final String teamId;
  final bool showAppBar;

  const TeamChatScreen({
    super.key,
    required this.hackId,
    required this.teamId,
    this.showAppBar = true,
  });

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  Timer? _typingPollTimer;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = context.read<AuthProvider>().user?.uid ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<HackathonProvider>()
          .loadTeamChat(widget.hackId, widget.teamId, refresh: true);
      _typingPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          context
              .read<HackathonProvider>()
              .pollTeamChatTyping(widget.hackId, widget.teamId);
        }
      });
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingPollTimer?.cancel();
    final p = context.read<HackathonProvider>();
    p.onTeamChatInputChanged(widget.hackId, widget.teamId, '');
    _textCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context
          .read<HackathonProvider>()
          .loadMoreTeamChat(widget.hackId, widget.teamId);
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await context.read<HackathonProvider>().sendTeamChatText(
          widget.hackId,
          widget.teamId,
          text,
          _currentUserId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final body = Consumer<HackathonProvider>(
      builder: (_, p, _) {
        return Column(
          children: [
            Expanded(
              child: () {
                if (p.teamChatLoading && p.teamChatMessages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (p.teamChatMessages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello to your team!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  itemCount: p.teamChatMessages.length +
                      (p.teamChatHasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == p.teamChatMessages.length) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    final msg = p.teamChatMessages[i];
                    return _MessageBubble(
                      message: msg,
                      isMine: msg.sender.uid == _currentUserId,
                      onReply: () =>
                          p.setTeamChatReplyingTo(msg),
                      onReact: (emoji) => p.reactToTeamChatMessage(
                          widget.hackId, widget.teamId, msg.id, emoji),
                      onDelete: msg.sender.uid == _currentUserId
                          ? () => p.deleteTeamChatMessage(
                              widget.hackId, widget.teamId, msg.id)
                          : null,
                    );
                  },
                );
              }(),
            ),
            if (p.teamChatRemoteTyping)
              const _TypingIndicator(),
            _ChatInputArea(
              controller: _textCtrl,
              focusNode: _focusNode,
              replyingTo: p.teamChatReplyingTo,
              onCancelReply: () => p.setTeamChatReplyingTo(null),
              onChanged: (v) =>
                  p.onTeamChatInputChanged(widget.hackId, widget.teamId, v),
              onSend: _send,
            ),
          ],
        );
      },
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Team Chat',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: body,
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final HackTeamMessage message;
  final bool isMine;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onReply,
    required this.onReact,
    this.onDelete,
  });

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply',
                  style: TextStyle(fontFamily: 'DM Sans')),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('React',
                  style: TextStyle(fontFamily: 'DM Sans')),
              onTap: () {
                Navigator.pop(context);
                _showEmojiPicker(context);
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(
                        fontFamily: 'DM Sans', color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '🎉'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis
                .map((e) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onReact(e);
                      },
                      child: Text(e,
                          style: const TextStyle(fontSize: 28)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              _Avatar(
                  pic: message.sender.profilePic,
                  name: message.sender.name),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2, left: 4),
                      child: Text(
                        message.sender.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMine
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      border: isMine
                          ? null
                          : Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyTo != null)
                          _ReplySnippet(
                              reply: message.replyTo!, isMine: isMine),
                        if (message.type == 'text' ||
                            message.attachments.isEmpty)
                          Text(
                            message.body,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color: isMine
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        if (message.attachments.isNotEmpty)
                          ...message.attachments.map((a) =>
                              _AttachmentWidget(attachment: a)),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.textTertiary,
                              ),
                            ),
                            if (message.isPending) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.access_time_rounded,
                                  size: 10,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.textTertiary),
                            ],
                            if (message.isFailed) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.error_outline_rounded,
                                  size: 10, color: Colors.red),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    _ReactionRow(reactions: message.reactions),
                ],
              ),
            ),
            if (isMine) const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Avatar extends StatelessWidget {
  final String? pic;
  final String name;
  const _Avatar({this.pic, required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: pic != null
          ? ClipOval(child: Image.network(pic!, fit: BoxFit.cover))
          : Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
    );
  }
}

class _ReplySnippet extends StatelessWidget {
  final HackTeamReplyContext reply;
  final bool isMine;
  const _ReplySnippet({required this.reply, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withValues(alpha: 0.2)
            : AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white : AppColors.primary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isMine ? Colors.white : AppColors.primary,
            ),
          ),
          Text(
            reply.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: isMine ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentWidget extends StatelessWidget {
  final HackTeamAttachment attachment;
  const _AttachmentWidget({required this.attachment});

  @override
  Widget build(BuildContext context) {
    if (attachment.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachment.url,
          width: 200,
          fit: BoxFit.cover,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.attach_file_rounded,
            size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            attachment.name ?? attachment.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReactionRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  const _ReactionRow({required this.reactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '${e.key} ${e.value.length}',
              style: const TextStyle(fontSize: 11),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'typing…',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input area ────────────────────────────────────────────────────────────────

class _ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final HackTeamMessage? replyingTo;
  final VoidCallback onCancelReply;
  final void Function(String) onChanged;
  final VoidCallback onSend;

  const _ChatInputArea({
    required this.controller,
    required this.focusNode,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to ${replyingTo!.sender.name}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.close_rounded,
                        size: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Message your team…',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onSend,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
