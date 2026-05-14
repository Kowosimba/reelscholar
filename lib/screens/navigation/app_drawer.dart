import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';

/// Dark glass-style drawer aligned with the floating bottom nav aesthetic.
class AppDrawer extends StatelessWidget {
  final DrawerUser? user;
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

  static const Color _bg = Color(0xFF050814);
  static const Color _surface = Color(0xFF0F1629);
  static const Color _muted = Color(0xFF64748B);
  static const Color _label = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Drawer(
      width: 304,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeroHeader(
            topPadding: top,
            user: user,
            onClose: () => Navigator.pop(context),
          ),
          Expanded(
            child: Consumer<NavigationProvider>(
              builder: (_, nav, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  children: [
                    _section('Navigate'),
                    _DrawerNavTile(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      active: nav.currentIndex == 0,
                      onTap: () => _goTab(context, nav, 0),
                    ),
                    _DrawerNavTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Chats',
                      active: nav.currentIndex == 1,
                      badge: nav.unreadChats,
                      onTap: () => _goTab(context, nav, 1),
                    ),
                    _DrawerNavTile(
                      icon: Icons.groups_outlined,
                      label: 'Study Groups',
                      active: nav.currentIndex == 2,
                      onTap: () => _goTab(context, nav, 2),
                    ),
                    _DrawerNavTile(
                      icon: Icons.psychology_outlined,
                      label: 'Learn',
                      active: nav.currentIndex == 3,
                      onTap: () => _goTab(context, nav, 3),
                    ),
                    _DrawerNavTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Me',
                      active: nav.currentIndex == 4,
                      onTap: () => _goTab(context, nav, 4),
                    ),
                    _divider(),
                    _section('Explore'),
                    _DrawerNavTile(
                      icon: Icons.search_rounded,
                      label: 'Search reels',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/search-reels');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.bookmark_outline_rounded,
                      label: 'Saved',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/bookmarks');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      badge: nav.unreadNotifications,
                      onTap: () {
                        Navigator.pop(context);
                        nav.clearNotificationBadge();
                        Navigator.pushNamed(context, '/notifications');
                      },
                    ),
                    _divider(),
                    _section('Community'),
                    _DrawerNavTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Hackathons',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/hackathons');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.leaderboard_outlined,
                      label: 'Leaderboard',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/leaderboard');
                      },
                    ),
                    _divider(),
                    _section('Progress'),
                    _DrawerNavTile(
                      icon: Icons.insights_outlined,
                      label: 'Stats & XP',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/progress');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.military_tech_outlined,
                      label: 'Achievements',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/achievements');
                      },
                    ),
                    _divider(),
                    _section('Account'),
                    _DrawerNavTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change password',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/change-password');
                      },
                    ),
                    const SizedBox(height: 6),
                    _DarkModeRow(
                      isDark: isDarkMode,
                      onToggle: onDarkModeToggle,
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSignOut,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.45),
                        ),
                        color: AppColors.error.withValues(alpha: 0.08),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.error.withValues(alpha: 0.95),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sign out',
                            style: TextStyle(
                              fontFamily: AppFonts.dmSans,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ReelScholar v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 10,
                    color: _muted.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goTab(BuildContext context, NavigationProvider nav, int index) {
    Navigator.pop(context);
    nav.setTab(index);
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: AppFonts.dmSans,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: _label,
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

class _DrawerHeroHeader extends StatelessWidget {
  final double topPadding;
  final DrawerUser? user;
  final VoidCallback onClose;

  const _DrawerHeroHeader({
    required this.topPadding,
    this.user,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0D9488).withValues(alpha: 0.35),
            AppDrawer._surface,
            AppDrawer._bg,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Menu',
                style: TextStyle(
                  fontFamily: AppFonts.sora,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.white.withValues(alpha: 0.08),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.fabGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDrawer._bg,
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: user?.profilePicUrl != null
                        ? Image.network(
                            user!.profilePicUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _InitialsAvatar(
                              initials: user?.initials ?? '?',
                            ),
                          )
                        : _InitialsAvatar(initials: user?.initials ?? '?'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'ReelScholar',
                      style: const TextStyle(
                        fontFamily: AppFonts.sora,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    if (user?.programme != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.programme!,
                        style: TextStyle(
                          fontFamily: AppFonts.dmSans,
                          fontSize: 12,
                          height: 1.3,
                          color: AppDrawer._label,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniChip(
                          icon: Icons.bolt_rounded,
                          label: user != null ? _fmtXp(user!.totalXp) : '0 XP',
                        ),
                        _MiniChip(
                          icon: Icons.local_fire_department_outlined,
                          label: '${user?.currentStreak ?? 0} streak',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtXp(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k XP';
    return '$xp XP';
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;

  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppDrawer._surface,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: AppFonts.sora,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5EEAD4)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.dmSans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    this.active = false,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.transparent,
              ),
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.22),
                        AppColors.secondary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    )
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.03),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: active ? Colors.white : AppDrawer._label,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.dmSans,
                      fontSize: 14.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active ? Colors.white : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.fabGradient,
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
                if (active)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkModeRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _DarkModeRow({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.03),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 22,
                color: AppDrawer._label,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isDark ? 'Light appearance' : 'Dark appearance',
                  style: const TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isDark ? AppColors.fabGradient : null,
                  color: isDark ? null : Colors.white.withValues(alpha: 0.12),
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
                          color: Colors.black26,
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
      ),
    );
  }
}

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

/// Pass from [AuthProvider] / profile when wired.
class DrawerUser extends _DrawerUser {
  const DrawerUser({
    required super.fullName,
    super.profilePicUrl,
    super.programme,
    required super.totalXp,
    required super.currentStreak,
  });
}
