import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final _DrawerUser? user;
  final bool isDarkMode;
  final VoidCallback onDarkModeToggle;
  final VoidCallback onSignOut;

  const AppDrawer({
    super.key,
    this.user,
    required this.isDarkMode,
    required this.onDarkModeToggle,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 290,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          _DrawerHeader(user: user),

          // ── Scrollable nav body ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Consumer<NavigationProvider>(
                builder: (_, nav, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Primary nav ────────────────────────────────────
                      _SectionLabel('Navigate'),
                      _DrawerItem(
                        icon: Icons.play_circle_filled_rounded,
                        label: 'Reels',
                        isActive: nav.currentIndex == 0,
                        accent: AppColors.primary,
                        onTap: () => _navigate(context, nav, 0),
                      ),
                      _DrawerItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chats & Groups',
                        isActive: nav.currentIndex == 1,
                        accent: AppColors.secondary,
                        badge: nav.unreadChats,
                        onTap: () => _navigate(context, nav, 1),
                      ),
                      _DrawerItem(
                        icon: Icons.school_rounded,
                        label: 'AI Tutor & Learn',
                        isActive: nav.currentIndex == 3,
                        accent: AppColors.primary,
                        onTap: () => _navigate(context, nav, 3),
                      ),
                      _DrawerItem(
                        icon: Icons.person_rounded,
                        label: 'My Profile',
                        isActive: nav.currentIndex == 4,
                        accent: AppColors.secondary,
                        onTap: () => _navigate(context, nav, 4),
                      ),

                      const _Divider(),

                      // ── Discover & Content ─────────────────────────────
                      _SectionLabel('Discover'),
                      _DrawerItem(
                        icon: Icons.explore_rounded,
                        label: 'Search & Discover',
                        accent: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/search-reels');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.bookmark_rounded,
                        label: 'Saved Reels',
                        accent: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/bookmarks');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.trending_up_rounded,
                        label: 'Trending Tags',
                        accent: AppColors.error,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/search-reels');
                        },
                      ),

                      const _Divider(),

                      // ── Community ─────────────────────────────────────
                      _SectionLabel('Community'),
                      _DrawerItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Hackathons',
                        accent: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/hackathons');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.leaderboard_rounded,
                        label: 'Leaderboard',
                        accent: AppColors.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/leaderboard');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        accent: AppColors.primary,
                        badge: nav.unreadNotifications,
                        onTap: () {
                          Navigator.pop(context);
                          nav.clearNotificationBadge();
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),

                      const _Divider(),

                      // ── Progress ──────────────────────────────────────
                      _SectionLabel('Progress'),
                      _DrawerItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'My Stats & XP',
                        accent: AppColors.success,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/progress');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.military_tech_rounded,
                        label: 'Achievements',
                        accent: AppColors.warning,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/achievements');
                        },
                      ),

                      const _Divider(),

                      // ── Settings & utility ────────────────────────────
                      _SectionLabel('Settings'),
                      _DrawerItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        accent: AppColors.textSecondary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.lock_reset_rounded,
                        label: 'Change Password',
                        accent: AppColors.textSecondary,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/change-password');
                        },
                      ),

                      // Dark mode toggle row
                      _DarkModeToggle(
                        isDark: isDarkMode,
                        onToggle: onDarkModeToggle,
                      ),

                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Bottom sign out ────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.border),
          _DrawerItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            accent: AppColors.error,
            onTap: onSignOut,
          ),
          const SizedBox(height: 12),

          // App version
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'ReelScholar v1.0.0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, NavigationProvider nav, int index) {
    Navigator.pop(context); // close drawer
    nav.setTab(index);
  }
}

// ─── Drawer header with gradient + user identity ──────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final _DrawerUser? user;

  const _DrawerHeader({this.user});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.drawerHeaderGradient,
        borderRadius: BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2.5,
              ),
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: ClipOval(
              child: user?.profilePicUrl != null
                  ? Image.network(
                      user!.profilePicUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _AvatarInitials(user?.initials ?? '?'),
                    )
                  : _AvatarInitials(user?.initials ?? '?'),
            ),
          ),

          const SizedBox(height: 14),

          // Name
          Text(
            user?.fullName ?? 'ReelScholar User',
            style: const TextStyle(
              fontFamily: AppFonts.sora,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 3),

          // Programme
          if (user?.programme != null)
            Text(
              user!.programme!,
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),

          const SizedBox(height: 14),

          // XP + Streak badges
          Row(
            children: [
              _HeaderBadge(
                icon: '⚡',
                label: user != null ? _fmtXp(user!.totalXp) : '0 XP',
              ),
              const SizedBox(width: 10),
              _HeaderBadge(
                icon: '🔥',
                label: '${user?.currentStreak ?? 0} day streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}K XP';
    return '$xp XP';
  }
}

class _AvatarInitials extends StatelessWidget {
  final String text;

  const _AvatarInitials(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppFonts.sora,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  final String icon;
  final String label;

  const _HeaderBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.dmSans,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}

// ─── Drawer nav item ──────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.accent,
    this.isActive = false,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: accent.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.15)
                    : AppColors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 19,
                color: isActive ? accent : AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 14),

            // Label
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? accent : AppColors.textPrimary,
                ),
              ),
            ),

            // Badge
            if (badge > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      fontFamily: AppFonts.dmSans,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Active indicator chevron
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Dark mode toggle ─────────────────────────────────────────────────────────
class _DarkModeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _DarkModeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.dark.withValues(alpha: 0.1)
                    : AppColors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                size: 19,
                color: isDark ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                isDark ? 'Light Mode' : 'Dark Mode',
                style: const TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Toggle switch
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: isDark
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Divider(color: AppColors.border, height: 1),
  );
}

// ─── Data model for drawer header ────────────────────────────────────────────
class _DrawerUser {
  final String fullName;
  final String? profilePicUrl;
  final String? programme;
  final int totalXp;
  final int currentStreak;

  const _DrawerUser({
    required this.fullName,
    this.profilePicUrl,
    this.programme,
    required this.totalXp,
    required this.currentStreak,
  });

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

/// Public factory — build from your UserModel
class DrawerUser extends _DrawerUser {
  const DrawerUser({
    required super.fullName,
    super.profilePicUrl,
    super.programme,
    required super.totalXp,
    required super.currentStreak,
  });
}
