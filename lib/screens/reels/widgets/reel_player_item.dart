import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'reel_widgets.dart';
import '../comments_sheet.dart';

class ReelPlayerItem extends StatefulWidget {
  final Reel reel;
  final bool isActive;
  final VoidCallback? onProfileTap;
  final VoidCallback? onHashtagTap;

  const ReelPlayerItem({
    super.key,
    required this.reel,
    required this.isActive,
    this.onProfileTap,
    this.onHashtagTap,
  });

  @override
  State<ReelPlayerItem> createState() => _ReelPlayerItemState();
}

class _ReelPlayerItemState extends State<ReelPlayerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  bool _showHeart = false;
  double _videoProgress = 0.0;
  bool _isPlaying = true;
  int _secondsWatched = 0;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Simulate video playback progress when active
    if (widget.isActive) _startProgress();
  }

  @override
  void didUpdateWidget(ReelPlayerItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _startProgress();
      _recordView();
    } else if (!widget.isActive && old.isActive) {
      _stopProgress();
    }
  }

  void _startProgress() {
    setState(() {
      _isPlaying = true;
      _videoProgress = 0;
      _secondsWatched = 0;
    });
    _tickProgress();
  }

  void _stopProgress() {
    setState(() => _isPlaying = false);
  }

  void _tickProgress() async {
    if (!mounted || !widget.isActive || !_isPlaying) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || !widget.isActive || !_isPlaying) return;
    final total = widget.reel.duration ?? 60;
    setState(() {
      _secondsWatched++;
      _videoProgress = (_secondsWatched / total).clamp(0.0, 1.0);
    });
    if (_videoProgress < 1.0) {
      _tickProgress();
    } else {
      // Loop
      await Future.delayed(const Duration(milliseconds: 800));
      _startProgress();
    }
  }

  void _recordView() {
    context.read<ReelProvider>().recordView(
      widget.reel.id,
      watchSeconds: _secondsWatched,
    );
  }

  void _onDoubleTap() {
    context.read<ReelProvider>().toggleLike(widget.reel.id);
    _showHeartAnimation();
  }

  void _showHeartAnimation() {
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) _tickProgress();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(reelId: widget.reel.id),
    );
  }

  void _onShare() {
    final prov = context.read<ReelProvider>();
    prov.recordShare(widget.reel.id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(reel: widget.reel),
    );
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReelProvider>(
      builder: (_, prov, _) {
        final reel = prov.currentFeedReels.firstWhere(
          (r) => r.id == widget.reel.id,
          orElse: () => widget.reel,
        );
        return GestureDetector(
          onTap: _togglePlay,
          onDoubleTap: _onDoubleTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video background ────────────────────────────────────────
              _VideoBackground(thumbnailUrl: reel.thumbnailUrl),

              // ── Top gradient ────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // ── Bottom gradient ─────────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 280,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // ── Right action column ─────────────────────────────────────
              Positioned(
                right: 12,
                bottom: 120,
                child: _RightActions(
                  reel: reel,
                  onLike: () => prov.toggleLike(reel.id),
                  onComment: _openComments,
                  onShare: _onShare,
                  onBookmark: () => prov.toggleBookmark(reel.id),
                  onProfileTap: widget.onProfileTap,
                ),
              ),

              // ── Bottom info ──────────────────────────────────────────────
              Positioned(
                bottom: 80,
                left: 0,
                right: 60,
                child: _BottomInfo(
                  reel: reel,
                  onFollowTap: () {},
                  onHashtagTap: widget.onHashtagTap,
                ),
              ),

              // ── Progress bar ─────────────────────────────────────────────
              Positioned(
                bottom: 72,
                left: 14,
                right: 56,
                child: VideoProgressBar(
                  progress: _videoProgress,
                  currentSeconds: _secondsWatched,
                  totalSeconds: reel.duration,
                ),
              ),

              // ── Pause indicator ──────────────────────────────────────────
              if (!_isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

              // ── Double-tap heart ─────────────────────────────────────────
              if (_showHeart)
                Center(
                  child: AnimatedBuilder(
                    animation: _heartCtrl,
                    builder: (_, _) {
                      final t = _heartCtrl.value;
                      return Opacity(
                        opacity: (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0, 1),
                        child: Transform.scale(
                          scale: 0.6 + t * 0.8,
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 80,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Video background (thumbnail or gradient placeholder) ────────────────────
class _VideoBackground extends StatelessWidget {
  final String? thumbnailUrl;
  const _VideoBackground({this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return Image.network(
        thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _Placeholder(),
      );
    }
    return _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a2740), Color(0xFF0d1520), Color(0xFF0a1020)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

// ─── Right action column ──────────────────────────────────────────────────────
class _RightActions extends StatelessWidget {
  final Reel reel;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onBookmark;
  final VoidCallback? onProfileTap;

  const _RightActions({
    required this.reel,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onBookmark,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with follow +
        GestureDetector(
          onTap: onProfileTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              UserAvatar(
                imageUrl: reel.uploader.profilePicUrl,
                initials: reel.uploader.initials,
                size: 42,
                hasBorder: true,
              ),
              Positioned(
                bottom: -8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        ReelActionButton(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          label: formatCount(reel.likeCount),
          isActive: reel.isLiked,
          activeColor: const Color(0xFFEF4444),
          onTap: onLike,
        ),

        const SizedBox(height: 18),

        ReelActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: formatCount(reel.commentCount),
          onTap: onComment,
        ),

        const SizedBox(height: 18),

        ReelActionButton(
          icon: Icons.reply_rounded,
          label: formatCount(reel.shareCount),
          onTap: onShare,
        ),

        const SizedBox(height: 18),

        ReelActionButton(
          icon: Icons.bookmark_border_rounded,
          activeIcon: Icons.bookmark_rounded,
          label: 'Save',
          isActive: reel.isBookmarked,
          activeColor: AppColors.primaryLight,
          onTap: onBookmark,
        ),
      ],
    );
  }
}

// ─── Bottom info (caption, hashtags, topic, uploader) ────────────────────────
class _BottomInfo extends StatelessWidget {
  final Reel reel;
  final VoidCallback? onFollowTap;
  final VoidCallback? onHashtagTap;

  const _BottomInfo({required this.reel, this.onFollowTap, this.onHashtagTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Uploader row
          Row(
            children: [
              UserAvatar(
                imageUrl: reel.uploader.profilePicUrl,
                initials: reel.uploader.initials,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '@${reel.uploader.fullName.replaceAll(' ', '_').toLowerCase()}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
              const SizedBox(width: 8),
              if (!reel.uploader.isFollowing)
                GestureDetector(
                  onTap: onFollowTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Caption
          if (reel.caption != null && reel.caption!.isNotEmpty)
            Text(
              reel.caption!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.35,
                shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
              ),
            ),

          if (reel.hashtags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: reel.hashtags
                  .take(4)
                  .map((tag) => HashtagChip(tag: tag, onTap: onHashtagTap))
                  .toList(),
            ),
          ],

          // Topic chip
          if (reel.topic != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  reel.topic!.name,
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Share sheet ──────────────────────────────────────────────────────────────
class _ShareSheet extends StatelessWidget {
  final Reel reel;
  const _ShareSheet({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share Reel',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ShareOption(
                icon: Icons.copy_rounded,
                label: 'Copy Link',
                onTap: () => Navigator.pop(context),
              ),
              _ShareOption(
                icon: Icons.message_rounded,
                label: 'Message',
                onTap: () => Navigator.pop(context),
              ),
              _ShareOption(
                icon: Icons.group_rounded,
                label: 'Study Group',
                onTap: () => Navigator.pop(context),
              ),
              _ShareOption(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: AppColors.darkTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}
