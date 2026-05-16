import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/theme_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';

class AppDrawer extends StatelessWidget {
  final DrawerUser? user;
  final VoidCallback onSignOut;

  const AppDrawer({
    super.key,
    this.user,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.watch<ThemeProvider>();
    final nav = context.watch<NavigationProvider>();
    
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Drawer(
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          // Header
          _DrawerHeader(user: user, isDark: isDark),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _SectionLabel('Discover', color: labelColor),
                _DrawerTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  badge: nav.unreadNotifications,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/notifications');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'Hackathons',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/hackathons');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Saved Reels',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/bookmarks');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.person_search_outlined,
                  label: 'Find People',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/search-users');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.add_circle_outline_rounded,
                  label: 'Upload Reel',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/upload-reel');
                  },
                  isDark: isDark,
                ),

                const Divider(height: 32, thickness: 0.5),

                _SectionLabel('Progress', color: labelColor),
                _DrawerTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'My Progress',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/progress');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.leaderboard_outlined,
                  label: 'Leaderboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/leaderboard');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: Icons.military_tech_outlined,
                  label: 'Achievements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/achievements');
                  },
                  isDark: isDark,
                ),

                const Divider(height: 32, thickness: 0.5),

                _SectionLabel('Settings', color: labelColor),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  label: 'App Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                  isDark: isDark,
                ),
                _DrawerTile(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Light Mode' : 'Dark Mode',
                  onTap: () => theme.toggleTheme(),
                  isDark: isDark,
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => theme.toggleTheme(),
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                _DrawerTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Feedback',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          
          // Sign Out
          Padding(
            padding: const EdgeInsets.all(16),
            child: _DrawerTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              color: AppColors.error,
              onTap: onSignOut,
              isDark: isDark,
            ),
          ),
          
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'ReelScholar v1.0.0',
                style: TextStyle(
                  fontSize: 11,
                  color: labelColor,
                  fontFamily: AppFonts.dmSans,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.1,
          fontFamily: AppFonts.dmSans,
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final DrawerUser? user;
  final bool isDark;

  const _DrawerHeader({this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: user?.profilePicUrl != null
                      ? Image.network(
                          user!.profilePicUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, e, _) => _InitialsAvatar(
                            initials: user?.initials ?? '?',
                          ),
                        )
                      : _InitialsAvatar(initials: user?.initials ?? '?'),
                ),
              ),
              const Spacer(),
              const Icon(Icons.school_rounded, color: AppColors.primary, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Welcome Back',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFamily: AppFonts.sora,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          Text(
            user?.programme ?? 'Learning account',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
              fontFamily: AppFonts.dmSans,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;
  final bool isDark;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.onTap,
    this.color,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final textColor = color ?? (isDark ? Colors.white : const Color(0xFF1E293B));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                      fontFamily: AppFonts.dmSans,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrawerUser {
  final String fullName;
  final String? profilePicUrl;
  final String? programme;
  final int totalXp;
  final int currentStreak;

  const DrawerUser({
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

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  const _InitialsAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
