import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/messaging_models.dart';
import 'package:reelscholar/providers/messaging_provider.dart';
import 'package:reelscholar/screens/study_groups/study_group_detail_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final String? conversationId;
  final String? groupId;
  final String? groupName;

  const ChatThreadScreen({
    super.key,
    this.conversationId,
    this.groupId,
    this.groupName,
  }) : assert(conversationId != null || groupId != null,
            'Either conversationId or groupId must be provided');

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  late MessagingProvider _messaging;

  @override
  void initState() {
    super.initState();
    _messaging = context.read<MessagingProvider>();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final convId = widget.conversationId;
      final groupId = widget.groupId;
      if (convId != null) {
        if (_messaging.activeConversation?.id != convId) {
          _messaging.openConversationById(convId);
        }
      } else if (groupId != null) {
        if (_messaging.activeConversation?.studyGroupId != groupId) {
          _messaging.openStudyGroupChat(groupId, widget.groupName ?? 'Group Chat');
        }
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _messaging.loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _messaging.closeConversation();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    await _messaging.sendText(text);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (picked.isEmpty || !mounted) return;
    final files = picked.map((x) => File(x.path)).toList();
    try {
      await _messaging.sendMedia(files);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send media: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagingProvider>(
      builder: (_, provider, _) {
        final conv = provider.activeConversation;
        if (conv == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(conv, provider),
          body: Column(
            children: [
              // Message list
              Expanded(
                child: _MessageList(
                  provider: provider,
                  conv: conv,
                  scrollController: _scrollCtrl,
                ),
              ),
              // Typing indicator
              if (provider.remoteTyping) _TypingIndicator(conv: conv),
              // Reply preview
              if (provider.replyingTo != null)
                _ReplyPreview(
                  message: provider.replyingTo!,
                  onDismiss: () => provider.setReplyingTo(null),
                ),
              // Input bar
              _InputBar(
                controller: _textCtrl,
                focusNode: _focusNode,
                onSend: _sendText,
                onAttach: _pickImage,
                onChanged: provider.onInputChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      Conversation conv, MessagingProvider provider) {
    return AppBar(
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: conv.isGroup && widget.groupId != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StudyGroupDetailScreen(groupId: widget.groupId!),
                  ),
                )
            : null,
        child: Row(
          children: [
            _SmallAvatar(name: conv.displayName, isGroup: conv.isGroup),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conv.displayName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.isGroup && widget.groupId != null)
                        const Icon(Icons.chevron_right_rounded,
                            size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                  if (conv.isGroup)
                    Text(
                      '${conv.participantsCount} members',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!conv.isGroup)
          IconButton(
            icon: const Icon(Icons.phone_outlined,
                color: AppColors.textSecondary, size: 21),
            onPressed: () {},
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
          onSelected: (val) async {
            if (val == 'mute') {
              await provider.toggleMute(conv.id, !conv.isMuted);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'mute',
              child: Row(children: [
                Icon(
                  conv.isMuted
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(conv.isMuted ? 'Unmute' : 'Mute',
                    style: const TextStyle(fontFamily: 'DM Sans')),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final MessagingProvider provider;
  final Conversation conv;
  final ScrollController scrollController;

  const _MessageList({
    required this.provider,
    required this.conv,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (provider.messagesLoading && provider.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.messagesError != null && provider.messages.isEmpty) {
      return Center(
        child: Text(provider.messagesError!,
            style: const TextStyle(
                fontFamily: 'DM Sans', color: AppColors.textSecondary)),
      );
    }
    if (provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.waving_hand_rounded,
                size: 40, color: AppColors.border),
            const SizedBox(height: 10),
            Text(
              'Say hello to ${conv.displayName}!',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: provider.messages.length + (provider.hasMoreMessages ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == provider.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))),
          );
        }
        final msg = provider.messages[i];
        final prevMsg =
            i + 1 < provider.messages.length ? provider.messages[i + 1] : null;
        final nextMsg = i > 0 ? provider.messages[i - 1] : null;

        // Date separator
        final showDate = prevMsg == null ||
            !_sameDay(msg.createdAt, prevMsg.createdAt);
        final isMe = msg.sender.uid == provider.currentUserId;
        final sameAuthorAsNext =
            nextMsg != null && nextMsg.sender.uid == msg.sender.uid;

        return Column(
          children: [
            if (showDate) _DateSeparator(date: msg.createdAt),
            if (msg.isSystem)
              _SystemMessage(msg: msg)
            else
              _MessageBubble(
                msg: msg,
                isMe: isMe,
                isGroup: conv.isGroup,
                showAvatar: !isMe && !sameAuthorAsNext,
                showName: conv.isGroup && !isMe,
                onReply: () => provider.setReplyingTo(msg),
                onReact: (emoji) =>
                    provider.reactToMessage(msg.id, emoji),
                onDelete: isMe
                    ? () => _confirmDelete(ctx, provider, msg.id)
                    : null,
              ),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _confirmDelete(
      BuildContext context, MessagingProvider provider, String msgId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete message?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w800,
                fontSize: 16)),
        content: const Text('This message will be removed for everyone.',
            style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteMessage(msgId);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ConvMessage msg;
  final bool isMe;
  final bool isGroup;
  final bool showAvatar;
  final bool showName;
  final VoidCallback onReply;
  final ValueChanged<String> onReact;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isGroup,
    required this.showAvatar,
    required this.showName,
    required this.onReply,
    required this.onReact,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              SizedBox(
                width: 28,
                child: showAvatar
                    ? _TinyAvatar(name: msg.sender.name)
                    : null,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (showName && !isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Text(
                        msg.sender.name,
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  // Reply preview
                  if (msg.replyTo != null)
                    _ReplySnippet(reply: msg.replyTo!, isMe: isMe),
                  // Bubble body
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: isMe
                          ? AppColors.primary
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (msg.isPending || msg.isFailed)
                          _StatusIndicator(isPending: msg.isPending),
                        if (msg.isMedia && msg.attachments.isNotEmpty)
                          _AttachmentGrid(
                              attachments: msg.attachments, isMe: isMe),
                        if (msg.body.isNotEmpty)
                          Text(
                            msg.body,
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 13,
                              color:
                                  isMe ? Colors.white : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(msg.createdAt),
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white60
                                    : AppColors.textTertiary,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                msg.isRead
                                    ? Icons.done_all_rounded
                                    : Icons.done_rounded,
                                size: 13,
                                color: msg.isRead
                                    ? const Color(0xFF93C5FD)
                                    : Colors.white60,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Reactions
                  if (msg.reactions.isNotEmpty)
                    _ReactionsRow(
                        reactions: msg.reactions, onTap: onReact),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showActions(BuildContext context) {
    const emojis = ['❤️', '😂', '👍', '😮', '😢', '🙏'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick emoji row
              Row(
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
              const SizedBox(height: 14),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.reply_rounded,
                    color: AppColors.textSecondary),
                title: const Text('Reply',
                    style: TextStyle(fontFamily: 'DM Sans')),
                onTap: () {
                  Navigator.pop(context);
                  onReply();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded,
                    color: AppColors.textSecondary),
                title: const Text('Copy text',
                    style: TextStyle(fontFamily: 'DM Sans')),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg.body));
                },
              ),
              if (onDelete != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline_rounded,
                          color: AppColors.error),
                  title: const Text('Delete',
                      style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Auxiliary bubble widgets ──────────────────────────────────────────────────

class _ReplySnippet extends StatelessWidget {
  final ReplyContext reply;
  final bool isMe;
  const _ReplySnippet({required this.reply, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.2)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white60 : AppColors.primary,
            width: 3,
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
              color: isMe ? Colors.white70 : AppColors.primary,
            ),
          ),
          Text(
            reply.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: isMe ? Colors.white60 : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final ValueChanged<String> onTap;

  const _ReactionsRow({required this.reactions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((e) {
          final count = e.value.length;
          return GestureDetector(
            onTap: () => onTap(e.key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '${e.key} $count',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AttachmentGrid extends StatelessWidget {
  final List<MessageAttachment> attachments;
  final bool isMe;
  const _AttachmentGrid({required this.attachments, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final imgs = attachments.where((a) => a.isImage).toList();
    if (imgs.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imgs.length == 1
          ? Image.network(imgs.first.url, width: 200, fit: BoxFit.cover)
          : SizedBox(
              width: 200,
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: imgs
                    .take(4)
                    .map((a) => Image.network(a.url, fit: BoxFit.cover))
                    .toList(),
              ),
            ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isPending;
  const _StatusIndicator({required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: isPending
                ? const CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white60)
                : const Icon(Icons.error_outline_rounded,
                    size: 10, color: AppColors.error),
          ),
          const SizedBox(width: 4),
          Text(
            isPending ? 'Sending…' : 'Failed',
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyAvatar extends StatelessWidget {
  final String name;
  const _TinyAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final h = name.codeUnits.fold(0, (a, b) => a + b) % 360;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.4).toColor(),
            HSLColor.fromAHSL(1, (h + 40).toDouble() % 360, 0.7, 0.3)
                .toColor(),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String name;
  final bool isGroup;
  const _SmallAvatar({required this.name, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    final h = name.codeUnits.fold(0, (a, b) => a + b) % 360;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, h.toDouble(), 0.6, 0.4).toColor(),
            HSLColor.fromAHSL(1, (h + 40).toDouble() % 360, 0.7, 0.3).toColor(),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          isGroup
              ? (name.isNotEmpty ? name[0].toUpperCase() : '?')
              : (name.split(' ').take(2).map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase()),
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _label(),
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ── System message ────────────────────────────────────────────────────────────

class _SystemMessage extends StatelessWidget {
  final ConvMessage msg;
  const _SystemMessage({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          msg.body,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  final Conversation conv;
  const _TypingIndicator({required this.conv});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _ctrl,
              builder: (_, _) => Container(
                margin: const EdgeInsets.only(right: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(
                      alpha: 0.3 + 0.7 * (((_ctrl.value + i * 0.3) % 1))),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
          Text(
            'typing…',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reply preview bar ─────────────────────────────────────────────────────────

class _ReplyPreview extends StatelessWidget {
  final ConvMessage message;
  final VoidCallback onDismiss;

  const _ReplyPreview({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF9),
        border: Border(top: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.sender.name}',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  message.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final ValueChanged<String> onChanged;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onAttach,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onAttach,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.attach_file_rounded,
                  size: 18, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Message…',
                  hintStyle: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
      ),
    );
  }
}
