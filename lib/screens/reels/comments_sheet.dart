import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'widgets/reel_widgets.dart';

class CommentsSheet extends StatefulWidget {
  final String reelId;
  const CommentsSheet({super.key, required this.reelId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  ReelComment? _replyingTo;
  bool _sortByTop = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().loadComments(widget.reelId);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<ReelProvider>().loadMoreComments(widget.reelId);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final prov = context.read<ReelProvider>();
    if (_replyingTo != null) {
      await prov.replyToComment(
        widget.reelId,
        _replyingTo!.id,
        text,
        replyToUserId: _replyingTo!.user.uid,
      );
    } else {
      await prov.postComment(widget.reelId, text);
    }

    _textCtrl.clear();
    setState(() => _replyingTo = null);
    _focusNode.unfocus();
  }

  void _startReply(ReelComment comment) {
    setState(() => _replyingTo = comment);
    _textCtrl.text = '@${comment.user.fullName.split(' ').first} ';
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Handle ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 8),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<ReelProvider>(
                  builder: (_, p, _) => Text(
                    'Comments (${formatCount(p.comments.length)})',
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.darkTextMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // ── Sort tabs ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _SortBtn(
                  label: 'Top',
                  active: _sortByTop,
                  onTap: () => setState(() => _sortByTop = true),
                ),
                const SizedBox(width: 8),
                _SortBtn(
                  label: 'Recent',
                  active: !_sortByTop,
                  onTap: () => setState(() => _sortByTop = false),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.darkBorder, height: 1),

          // ── Comments list ─────────────────────────────────────────────
          Expanded(
            child: Consumer<ReelProvider>(
              builder: (_, prov, _) {
                if (prov.commentsState == ReelLoadState.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (prov.comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 40,
                          color: AppColors.darkTextMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No comments yet\nBe the first to comment!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 13,
                            color: AppColors.darkTextMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sorted = List<ReelComment>.from(prov.comments)
                  ..sort(
                    (a, b) => _sortByTop
                        ? b.likeCount.compareTo(a.likeCount)
                        : b.createdAt.compareTo(a.createdAt),
                  );

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount:
                      sorted.length +
                      (prov.commentsState == ReelLoadState.loadingMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == sorted.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    return _CommentTile(
                      comment: sorted[i],
                      onLike: () => prov.toggleCommentLike(sorted[i].id),
                      onReply: () => _startReply(sorted[i]),
                      onDelete: () =>
                          prov.deleteComment(widget.reelId, sorted[i].id),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: AppColors.darkBorder, height: 1),

          // ── Reply indicator ───────────────────────────────────────────
          if (_replyingTo != null)
            Container(
              color: AppColors.darkCard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to ${_replyingTo!.user.fullName}',
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _replyingTo = null);
                      _textCtrl.clear();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                ],
              ),
            ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            color: AppColors.darkSurface,
            padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 100),
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      maxLines: null,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: AppColors.darkText,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        hintText: 'Add a comment…',
                        hintStyle: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          color: AppColors.darkTextMuted,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort button ──────────────────────────────────────────────────────────────
class _SortBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.darkTextMuted,
          ),
        ),
      ),
    );
  }
}

// ─── Comment tile ─────────────────────────────────────────────────────────────
class _CommentTile extends StatefulWidget {
  final ReelComment comment;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _showReplies = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            imageUrl: c.user.profilePicUrl,
            initials: c.user.initials,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + time + creator badge
                Row(
                  children: [
                    Text(
                      c.user.fullName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    if (c.isCreatorComment) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Creator',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _timeAgo(c.createdAt),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 10,
                        color: AppColors.darkTextMuted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // Body
                Text(
                  c.body,
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 13,
                    color: Color(0xFFCBD5E1),
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6),

                // Actions row
                Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onLike,
                      child: Row(
                        children: [
                          Icon(
                            c.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 15,
                            color: c.isLiked
                                ? const Color(0xFFEF4444)
                                : AppColors.darkTextMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${c.likeCount}',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: AppColors.darkTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    ),
                    if (c.replyCount > 0) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showReplies = !_showReplies),
                        child: Text(
                          _showReplies
                              ? 'Hide replies'
                              : 'View ${c.replyCount} ${c.replyCount == 1 ? 'reply' : 'replies'}',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Replies
                if (_showReplies && c.replies.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...c.replies.map(
                    (reply) => Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 2,
                            height: 40,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppColors.darkBorder,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          UserAvatar(
                            imageUrl: reply.user.profilePicUrl,
                            initials: reply.user.initials,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      reply.user.fullName,
                                      style: const TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                    if (reply.replyTo != null) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '→ ${reply.replyTo!.fullName}',
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 10,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  reply.body,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
