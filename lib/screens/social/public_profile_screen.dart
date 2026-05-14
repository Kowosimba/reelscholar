// lib/features/social/screens/public_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/models/social_models.dart';

import 'package:reelscholar/screens/social/followers_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadProfile(widget.userId);
    });
  }

  @override
  void dispose() {
    context.read<SocialProvider>().clearProfile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialProvider>(
      builder: (_, provider, _) {
        if (provider.profileLoading && provider.viewedProfile == null) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary)),
          );
        }
        if (provider.profileError != null &&
            provider.viewedProfile == null) {
          return Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white, elevation: 0),
            body: Center(
              child: Text(provider.profileError!,
                  style: const TextStyle(
                      fontFamily: 'DM Sans',
                      color: AppColors.textSecondary)),
            ),
          );
        }
        final user = provider.viewedProfile;
        if (user == null) return const Scaffold(body: SizedBox.shrink());

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              _ProfileSliverAppBar(user: user, provider: provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      _StatsRow(user: user, userId: widget.userId),
                      const SizedBox(height: 16),

                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        _Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardTitle('Bio'),
                              const SizedBox(height: 6),
                              Text(
                                user.bio!,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Learning stats
                      _Card(
                        child: Column(
                          children: [
                            _StatRow(
                              label: 'Total XP',
                              value: '${_fmt(user.totalXp)} XP',
                              icon: '⚡',
                            ),
                            const Divider(
                                height: 16, color: Color(0xFFF1F5F9)),
                            _StatRow(
                              label: 'Current Streak',
                              value: '${user.currentStreak} days',
                              icon: '🔥',
                            ),
                            const Divider(
                                height: 16, color: Color(0xFFF1F5F9)),
                            _StatRow(
                              label: 'Longest Streak',
                              value: '${user.longestStreak} days',
                              icon: '🏆',
                            ),
                            const Divider(
                                height: 16, color: Color(0xFFF1F5F9)),
                            _StatRow(
                              label: 'Reels Created',
                              value: '${user.videoCount}',
                              icon: '🎥',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // XP level bar
                      _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Level ${user.xpLevel}',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${user.totalXp % 500} / 500 XP',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: user.xpProgress,
                                minHeight: 7,
                                backgroundColor:
                                    const Color(0xFFF1F5F9),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Block action (always available)
                      if (!user.isBlocked)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _confirmBlock(context, user, provider),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side:
                                  const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.block_rounded,
                                size: 16),
                            label: const Text(
                              'Block User',
                              style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmBlock(
      BuildContext context, AppUser user, SocialProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block ${user.fullName}?',
          style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w800,
              fontSize: 16),
        ),
        content: const Text(
          'They won\'t be able to see your profile or contact you. You can unblock from Settings.',
          style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.blockUser(user.uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User blocked'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              }
            },
            child: const Text('Block',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Sliver app bar ────────────────────────────────────────────────────────────

class _ProfileSliverAppBar extends StatelessWidget {
  final AppUser user;
  final SocialProvider provider;

  const _ProfileSliverAppBar(
      {required this.user, required this.provider});

  List<Color> get _gradColors {
    final hue = user.fullName.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.4).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.7, 0.3).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isFollowing = user.isFollowing;
    final isLoading = provider.isFollowLoading(user.uid);

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient banner
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Avatar + name overlay
            Positioned(
              bottom: 14,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      gradient: LinearGradient(colors: _gradColors),
                    ),
                    child: user.profilePicUrl != null
                        ? ClipOval(
                            child: Image.network(
                            user.profilePicUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(user.initials,
                                  style: const TextStyle(
                                      fontFamily: 'Sora',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ))
                        : Center(
                            child: Text(user.initials,
                                style: const TextStyle(
                                    fontFamily: 'Sora',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.faculty != null)
                          Text(
                            user.isLecturer
                                ? 'Lecturer · ${user.faculty}'
                                : '${user.faculty}',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Follow button
                  GestureDetector(
                    onTap: isLoading
                        ? null
                        : () async {
                            try {
                              await provider.toggleFollow(user.uid);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isFollowing
                                    ? Colors.white
                                    : _gradColors.first,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final AppUser user;
  final String userId;

  const _StatsRow({required this.user, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          value: _fmt(user.videoCount),
          label: 'Reels',
          onTap: null,
        ),
        _vDivider(),
        _StatTile(
          value: _fmt(user.followersCount),
          label: 'Followers',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FollowersScreen(
                userId: userId,
                userName: user.fullName,
                initialTab: 0,
              ),
            ),
          ),
        ),
        _vDivider(),
        _StatTile(
          value: _fmt(user.followingCount),
          label: 'Following',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FollowersScreen(
                userId: userId,
                userName: user.fullName,
                initialTab: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.border,
      );

  static String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatTile({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared card components ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Sora',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      );
}

class _StatRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}



