// lib/features/social/widgets/user_tile.dart
//
// Reusable user row used in search results, followers list,
// following list, blocked list, and suggestions.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/models/social_models.dart';
import 'package:reelscholar/providers/social_provider.dart';
import 'package:reelscholar/screens/social/public_profile_screen.dart';

class UserTile extends StatelessWidget {
  final AppUser user;
  final bool showFollowBtn;
  final bool showBlockedBadge;
  final bool showMutualBadge;
  final Widget? secondaryTrailing;
  final Widget? trailing;
  final VoidCallback? onTap;

  const UserTile({
    super.key,
    required this.user,
    this.showFollowBtn = true,
    this.showBlockedBadge = false,
    this.showMutualBadge = true,
    this.secondaryTrailing,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ??
          () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PublicProfileScreen(userId: user.uid),
                ),
              ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            // Avatar
            _UserAvatar(user: user, size: 44),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isLecturer) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Lecturer',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6D28D9),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // XP badge
                      _MiniStat(
                        icon: '⚡',
                        label: _fmtNum(user.totalXp),
                      ),
                      const SizedBox(width: 8),
                      // Streak badge
                      if (user.currentStreak > 0)
                        _MiniStat(
                          icon: '🔥',
                          label: '${user.currentStreak}d',
                        ),
                      if (showMutualBadge &&
                          user.followsYou &&
                          !user.isFollowing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Follows you',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                      if (showBlockedBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Blocked',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing: custom or follow button
            trailing ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showFollowBtn) _FollowButton(user: user),
                    if (showFollowBtn && secondaryTrailing != null)
                      const SizedBox(width: 8),
                    ?secondaryTrailing,
                  ],
                ),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (user.faculty != null && user.faculty!.isNotEmpty) {
      parts.add(user.faculty!);
    }
    if (user.degreeProgramme != null &&
        user.degreeProgramme!.isNotEmpty) {
      parts.add(user.degreeProgramme!);
    }
    if (parts.isEmpty && user.studentId != null) {
      return user.studentId!;
    }
    return parts.join(' · ');
  }

  static String _fmtNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final AppUser user;
  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();
    final isLoading = provider.isFollowLoading(user.uid);
    final isFollowing = user.isFollowing;

    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppColors.primary),
      );
    }

    return GestureDetector(
      onTap: () async {
        try {
          await context.read<SocialProvider>().toggleFollow(user.uid);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  e.toString().replaceFirst('Exception: ', '')),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ));
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing
                ? AppColors.textSecondary
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Mini stat pill ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── User avatar ───────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;

  const _UserAvatar({required this.user, this.size = 44});

  List<Color> get _gradient {
    final hue = user.fullName.codeUnits.fold(0, (a, b) => a + b) % 360;
    return [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.4).toColor(),
      HSLColor.fromAHSL(1, (hue + 40.0) % 360, 0.7, 0.3).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _gradient),
        shape: BoxShape.circle,
      ),
      child: user.profilePicUrl != null
          ? ClipOval(
              child: Image.network(
              user.profilePicUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _InitialsText(initials: user.initials, size: size),
            ))
          : _InitialsText(initials: user.initials, size: size),
    );
  }
}

class _InitialsText extends StatelessWidget {
  final String initials;
  final double size;
  const _InitialsText({required this.initials, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Sora',
          fontSize: size * 0.33,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Public export of avatar for use in other screens
class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  const UserAvatar({super.key, required this.user, this.size = 44});

  @override
  Widget build(BuildContext context) =>
      _UserAvatar(user: user, size: size);
}



