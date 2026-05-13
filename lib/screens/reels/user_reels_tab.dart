import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            return Stack(
              children: [
                ReelThumbnailCard(
                  reel: reel,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/reel-detail',
                    arguments: reel,
                  ),
                ),
                if (widget.isOwnProfile)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context, prov, reel.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
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

// Reference to AppColors — include in standalone build
class AppColors {
  static const Color primary = Color(0xFF0D9488);
  static const Color primarySubtle = Color(0xFFCCFBF1);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color border = Color(0xFFE2E8F0);
}
