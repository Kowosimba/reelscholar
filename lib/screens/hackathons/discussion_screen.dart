// lib/screens/hackathons/discussion_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/hackathon_provider.dart';
import 'package:reelscholar/models/hackathon_models.dart';

class DiscussionScreen extends StatefulWidget {
  final String hackId;
  final bool showAppBar;
  const DiscussionScreen({super.key, required this.hackId, this.showAppBar = true});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final _textCtrl = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<HackathonProvider>()
          .loadDiscussion(widget.hackId, refresh: true);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    final p = context.read<HackathonProvider>();
    if (_replyingToId != null) {
      await p.replyToComment(widget.hackId, _replyingToId!, text);
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
      });
    } else {
      await p.postComment(widget.hackId, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.showAppBar ? AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Discussion',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ) : null,
      body: Column(
        children: [
          Expanded(
            child: Consumer<HackathonProvider>(
              builder: (_, p, _) {
                if (p.commentsLoading && p.comments.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                if (p.comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet.\nBe the first to start the discussion!',
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
                  padding: const EdgeInsets.all(16),
                  itemCount: p.comments.length,
                  itemBuilder: (_, i) => _CommentTile(
                    comment: p.comments[i],
                    onReply: (id, name) {
                      setState(() {
                        _replyingToId = id;
                        _replyingToName = name;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _InputArea(
            controller: _textCtrl,
            onSend: _send,
            replyingToName: _replyingToName,
            onCancelReply: () {
              setState(() {
                _replyingToId = null;
                _replyingToName = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final DiscussionComment comment;
  final Function(String id, String name) onReply;

  const _CommentTile({required this.comment, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(
                  pic: comment.userProfilePic, initials: comment.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.body,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StatBtn(
                          icon: comment.likedByMe
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          label: '${comment.likesCount}',
                          color: comment.likedByMe
                              ? Colors.red
                              : AppColors.textTertiary,
                          onTap: () => context
                              .read<HackathonProvider>()
                              .toggleLike(comment.id),
                        ),
                        const SizedBox(width: 16),
                        _StatBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Reply',
                          onTap: () => onReply(comment.id, comment.userName),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, top: 12),
              child: Column(
                children: comment.replies
                    .map((r) => _CommentTile(comment: r, onReply: onReply))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

class _UserAvatar extends StatelessWidget {
  final String? pic;
  final String initials;
  const _UserAvatar({this.pic, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: pic != null && pic!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                pic!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
    );
  }
}

class _StatBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _StatBtn(
      {required this.icon, required this.label, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String? replyingToName;
  final VoidCallback onCancelReply;

  const _InputArea({
    required this.controller,
    required this.onSend,
    this.replyingToName,
    required this.onCancelReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingToName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      'Replying to $replyingToName',
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
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13),
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
