import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/models/tutor_models.dart';
import 'package:reelscholar/providers/tutor_provider.dart';
import 'package:reelscholar/screens/tutor/widgets/tutor_widgets.dart';

class TutorChatScreen extends StatefulWidget {
  final TutorModule module;

  const TutorChatScreen({super.key, required this.module});

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  late TextEditingController _messageCtrl;
  late ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    _scrollCtrl = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    });
  }

  Future<void> _refreshSession(TutorProvider prov) async {
    if (prov.isStarting || prov.isSending) return;
    final ok = await prov.startSession(widget.module);
    if (!mounted) return;
    if (ok) {
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.chatError ?? 'Could not refresh session'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: TColors.error,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final prov = context.read<TutorProvider>();
    if (prov.isSending) return;

    _messageCtrl.clear();
    FocusScope.of(context).unfocus();

    await prov.sendMessage(text);

    if (!mounted) return;
    if (prov.chatError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.chatError!),
          behavior: SnackBarBehavior.floating,
          backgroundColor: TColors.error,
        ),
      );
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.muted,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: TColors.white,
        foregroundColor: TColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.name,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Tutor Chat',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<TutorProvider>(
            builder: (_, prov, _) => PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: TColors.textSecondary,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (v) async {
                if (v == 'refresh') await _refreshSession(prov);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'refresh',
                  enabled: !prov.isStarting && !prov.isSending,
                  child: Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: prov.isStarting || prov.isSending
                            ? TColors.textTertiary
                            : TColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Refresh Session',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          color: prov.isStarting || prov.isSending
                              ? TColors.textTertiary
                              : TColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<TutorProvider>(
        builder: (context, prov, _) {
          final mismatch =
              prov.activeModule?.moduleId != widget.module.moduleId;
          final messages = prov.messages;

          if (mismatch) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 40, color: TColors.textTertiary),
                    const SizedBox(height: 12),
                    const Text(
                      'No active session for this module. Go back and tap “Start AI Tutor Session”.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: TColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final progress = prov.sessionProgress;
          final extra = prov.isSending ? 1 : 0;

          return Column(
            children: [
              if (progress != null) _ProgressStrip(progress: progress),
              Expanded(
                child: messages.isEmpty && !prov.isSending
                    ? const Center(
                        child: Text(
                          'Say hello to your tutor…',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            color: TColors.textTertiary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: messages.length + extra,
                        itemBuilder: (context, index) {
                          if (index >= messages.length) {
                            return const _TutorTypingBubble();
                          }
                          return _TutorChatBubble(message: messages[index]);
                        },
                      ),
              ),
              _InputBar(
                controller: _messageCtrl,
                enabled: !prov.isSending,
                onSend: _sendMessage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final SessionProgress progress;

  const _ProgressStrip({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.progressPercentage / 100).clamp(0.0, 1.0);
    return Material(
      color: TColors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Module progress',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: TColors.textTertiary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress.progressPercentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: TColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: TColors.border,
                color: TColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _TutorChatBubble({required this.message});

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? TColors.primary : TColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  topRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: TColors.border),
                boxShadow: isUser
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 14,
                      color: isUser ? Colors.white : TColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (message.progress != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${message.progress!.progressPercentage.toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUser
                            ? Colors.white70
                            : TColors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _timeLabel(message.timestamp),
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: isUser ? Colors.white60 : TColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: TColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: TColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TutorTypingBubble extends StatelessWidget {
  const _TutorTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [TColors.primary, TColors.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: TColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TColors.border),
            ),
            child: const Text(
              'Tutor is thinking…',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: TColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TColors.white,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: TColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? onSend() : null,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: TColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask your tutor…',
                  hintStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    color: TColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: TColors.muted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: TColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: TColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: enabled ? TColors.primary : TColors.textTertiary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: enabled ? onSend : null,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
