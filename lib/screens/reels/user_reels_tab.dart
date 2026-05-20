import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/models/reel_models.dart';
import 'package:reelscholar/providers/reel_provider.dart';
import 'widgets/reel_widgets.dart';

/// Drop-in tab widget for the Profile screen showing a user's reel grid.
/// Pass [userId] and it self-loads.
class UserReelsTab extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const UserReelsTab({
    super.key,
    required this.userId,
    this.isOwnProfile = false,
  });

  @override
  State<UserReelsTab> createState() => _UserReelsTabState();
}

class _UserReelsTabState extends State<UserReelsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReelProvider>().loadUserReels(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReelProvider>(
      builder: (_, prov, _) {
        final reels = prov.userReels(widget.userId);

        if (reels.isEmpty) {
          return ReelEmptyState(
            icon: Icons.videocam_off_outlined,
            title: widget.isOwnProfile
                ? "You haven't posted yet"
                : 'No reels yet',
            subtitle: widget.isOwnProfile
                ? 'Share your first educational reel with the community'
                : 'This creator hasn\'t posted any reels yet',
            actionLabel: widget.isOwnProfile ? 'Post a Reel' : null,
            onAction: widget.isOwnProfile
                ? () => Navigator.pushNamed(context, '/upload-reel')
                : null,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.62,
          ),
          itemCount:
              reels.length +
              (widget.isOwnProfile ? 1 : 0), // +1 for upload button
          itemBuilder: (_, i) {
            if (widget.isOwnProfile && i == 0) {
              return _UploadPromptCard(
                onTap: () => Navigator.pushNamed(context, '/upload-reel'),
              );
            }
            final reel = reels[widget.isOwnProfile ? i - 1 : i];
            final showBadge = widget.isOwnProfile && !reel.isVisible;

            return Stack(
              children: [
                Opacity(
                  opacity: reel.isRejected ? 0.55 : 1.0,
                  child: ReelThumbnailCard(
                    reel: reel,
                    onTap: () {
                      if (reel.isRejected) {
                        _showRejectionSheet(context, reel);
                      } else if (reel.isPending) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This reel is still being reviewed.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/reel-detail',
                          arguments: reel,
                        );
                      }
                    },
                  ),
                ),
                if (showBadge)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    right: 6,
                    child: _StatusBadge(reel: reel),
                  ),
                if (widget.isOwnProfile)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context, prov, reel.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ReelProvider prov, String reelId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
                title: const Text(
                  'Delete Reel',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                subtitle: const Text('This action cannot be undone'),
                onTap: () async {
                  Navigator.pop(context);
                  await prov.deleteReel(reelId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reel deleted'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadPromptCard extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadPromptCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'New Reel',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status badge shown on uploader's own grid ───────────────────────────────
class _StatusBadge extends StatelessWidget {
  final Reel reel;
  const _StatusBadge({required this.reel});

  @override
  Widget build(BuildContext context) {
    final (label, bg, icon) = switch (reel.moderationStatus) {
      'processing' => ('Validating', const Color(0xFF1D4ED8), Icons.hourglass_top_rounded),
      'under_review' => ('Reviewing', const Color(0xFFD97706), Icons.visibility_outlined),
      'auto_rejected' || 'admin_rejected' => ('Rejected', const Color(0xFFDC2626), Icons.block_rounded),
      _ => ('', Colors.transparent, Icons.circle),
    };

    if (label.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rejection bottom sheet ───────────────────────────────────────────────────
void _showRejectionSheet(BuildContext context, Reel reel) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.block_rounded, color: AppColors.error),
                SizedBox(width: 10),
                Text(
                  'Reel was rejected',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _humanReason(reel.moderationReason),
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/upload-reel');
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Try a different video',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _humanReason(String? reason) {
  return switch (reason) {
    'not_educational' =>
      "Our AI didn't detect educational content in this video. ReelScholar is for sharing educational material — please try a different video.",
    'validation_failed' =>
      "We couldn't validate this video. This might be a temporary issue — please try uploading again.",
    null => "This reel didn't meet our community guidelines.",
    _ => reason,
  };
}

// Reference to AppColors — include in standalone build
class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primarySubtle = Color(0xFFCCFBF1);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color border = Color(0xFFE2E8F0);
}
