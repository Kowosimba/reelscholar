import 'package:flutter/material.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/core/constants/app_colors.dart';

// ─── User Avatar ──────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool hasBorder;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 36,
    this.backgroundColor,
    this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: hasBorder ? Border.all(color: Colors.white, width: 2) : null,
          color: backgroundColor ?? AppColors.primary,
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _Initials(text: initials, size: size),
                )
              : _Initials(text: initials, size: size),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final double size;
  const _Initials({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: size * 0.35,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Reel Action Button (right sidebar) ──────────────────────────────────────
class ReelActionButton extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;

  const ReelActionButton({
    super.key,
    required this.icon,
    this.activeIcon,
    required this.label,
    this.isActive = false,
    this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? AppColors.primary) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive && activeIcon != null ? activeIcon : icon,
                  key: ValueKey(isActive),
                  size: 26,
                  color: color,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              label,
              key: ValueKey('$label-$isActive'),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video Progress Bar ───────────────────────────────────────────────────────
class VideoProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final int? currentSeconds;
  final int? totalSeconds;

  const VideoProgressBar({
    super.key,
    required this.progress,
    this.currentSeconds,
    this.totalSeconds,
  });

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress track
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Thumb
            Positioned(
              left:
                  (MediaQuery.of(context).size.width - 56) *
                  progress.clamp(0.0, 1.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        if (currentSeconds != null && totalSeconds != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(currentSeconds!),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                _fmt(totalSeconds!),
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Hashtag Chip ─────────────────────────────────────────────────────────────
class HashtagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onTap;
  final bool dark;

  const HashtagChip({
    super.key,
    required this.tag,
    this.onTap,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        tag.startsWith('#') ? tag : '#$tag',
        style: TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? AppColors.primaryLight : AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class ReelEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ReelEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Reel Thumbnail Card (for bookmarks/user grid) ────────────────────────────
class ReelThumbnailCard extends StatelessWidget {
  final Reel reel;
  final VoidCallback? onTap;

  const ReelThumbnailCard({super.key, required this.reel, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail / dark bg
            reel.thumbnailUrl != null
                ? Image.network(
                    reel.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _DarkBg(),
                  )
                : _DarkBg(),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 60,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Play icon
            Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 32,
              ),
            ),

            // View count
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatCount(reel.viewCount),
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // Duration badge
            if (reel.duration != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(reel.duration!),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _DarkBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1a2740), Color(0xFF0d1520)],
      ),
    ),
  );
}

// ─── Count formatter ──────────────────────────────────────────────────────────
String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
