import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'package:video_player/video_player.dart';
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
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  AnimationController? _heartCtrl;
  bool _showHeart = false;
  double _videoProgress = 0.0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initController();
    if (widget.isActive) _startPlayback();
  }

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
    
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.setLooping(true);
        if (widget.isActive) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }

    _controller!.addListener(() {
      if (mounted) {
        setState(() {
          _videoProgress = _controller!.value.position.inMilliseconds / 
                          _controller!.value.duration.inMilliseconds;
        });
      }
    });
  }

  @override
  void didUpdateWidget(ReelPlayerItem old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _startPlayback();
      _recordView();
    } else if (!widget.isActive && old.isActive) {
      _stopPlayback();
    }
  }

  void _startPlayback() {
    setState(() => _isPlaying = true);
    _controller?.play();
  }

  void _stopPlayback() {
    setState(() => _isPlaying = false);
    _controller?.pause();
  }

  void _recordView() {
    context.read<ReelProvider>().recordView(
      widget.reel.id,
      watchSeconds: _controller?.value.position.inSeconds ?? 0,
    );
  }

  void _onDoubleTap() {
    context.read<ReelProvider>().toggleLike(widget.reel.id);
    _showHeartAnimation();
  }

  void _showHeartAnimation() {
    if (_heartCtrl == null) return;
    setState(() => _showHeart = true);
    _heartCtrl!.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
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
    _heartCtrl?.dispose();
    _controller?.dispose();
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
              // Full-screen video player
              Positioned.fill(
                child: _isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    : _VideoBackground(thumbnailUrl: reel.thumbnailUrl),
              ),

              // Dark gradient scrim — heavy at top (status bar) and bottom (controls)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.18, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Right action column — pinned bottom-right
              Positioned(
                right: 12,
                bottom: 24,
                child: _RightActions(
                  reel: reel,
                  onLike: () => prov.toggleLike(reel.id),
                  onComment: _openComments,
                  onShare: _onShare,
                  onBookmark: () => prov.toggleBookmark(reel.id),
                  onProfileTap: widget.onProfileTap,
                ),
              ),

              // Bottom info + progress bar — pinned bottom-left
              Positioned(
                left: 16,
                right: 88,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _BottomInfo(
                      reel: reel,
                      onFollowTap: () {},
                      onHashtagTap: widget.onHashtagTap,
                    ),
                    const SizedBox(height: 12),
                    VideoProgressBar(
                      progress: _videoProgress,
                      currentSeconds: _controller?.value.position.inSeconds ?? 0,
                      totalSeconds: _controller?.value.duration.inSeconds ?? reel.duration,
                    ),
                  ],
                ),
              ),

              // Pause indicator
              if (!_isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),

              // Double-tap heart animation
              if (_showHeart && _heartCtrl != null)
                Center(
                  child: AnimatedBuilder(
                    animation: _heartCtrl!,
                    builder: (_, _) {
                      final t = _heartCtrl!.value;
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
          colors: [Color(0xFF8BDCD5), Color(0xFF4FD1C5), Color(0xFF6366F1)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          size: 56,
          color: Colors.white.withValues(alpha: 0.5),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 12,
                    color: AppColors.primary,
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

  static const _shadow = [Shadow(color: Colors.black54, blurRadius: 8)];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Uploader row
        Row(
          children: [
            UserAvatar(
              imageUrl: reel.uploader.profilePicUrl,
              initials: reel.uploader.initials,
              size: 30,
              hasBorder: true,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '@${reel.uploader.fullName.replaceAll(' ', '_').toLowerCase()}',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: _shadow,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (!reel.uploader.isFollowing)
              GestureDetector(
                onTap: onFollowTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
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
              shadows: _shadow,
            ),
          ),

        if (reel.hashtags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: reel.hashtags
                .take(4)
                .map((tag) => HashtagChip(tag: tag, onTap: onHashtagTap, dark: true))
                .toList(),
          ),
        ],

        // Topic chip
        if (reel.topic != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                reel.topic!.name,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Colors.white70,
                  shadows: _shadow,
                ),
              ),
            ],
          ),
        ],
      ],
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
        color: Colors.white,
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
                color: AppColors.border,
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
              color: AppColors.textPrimary,
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
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}


