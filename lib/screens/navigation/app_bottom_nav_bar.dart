import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final bool isDark; // reels feed uses dark variant
  final VoidCallback onUploadTap;

  const AppBottomNavBar({
    super.key,
    required this.isDark,
    required this.onUploadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (_, nav, _) {
        return _BottomNavContent(
          currentIndex: nav.currentIndex,
          isDark: isDark,
          unreadChats: nav.unreadChats,
          onTap: nav.setTab,
          onUploadTap: onUploadTap,
        );
      },
    );
  }
}

class _BottomNavContent extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final int unreadChats;
  final ValueChanged<int> onTap;
  final VoidCallback onUploadTap;

  const _BottomNavContent({
    required this.currentIndex,
    required this.isDark,
    required this.unreadChats,
    required this.onTap,
    required this.onUploadTap,
  });

  // Active colour — teal on light, white on dark (reels)
  Color get _activeColor => isDark ? Colors.white : AppColors.primary;

  // Inactive colour
  Color get _inactiveColor =>
      isDark ? Colors.white.withValues(alpha: 0.4) : AppColors.textTertiary;

  // Background
  Color get _bg =>
      isDark ? Colors.black.withValues(alpha: 0.82) : AppColors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: isDark
            ? null
            : const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0 – Reels
              _NavItem(
                index: 0,
                icon: Icons.play_circle_outline_rounded,
                activeIcon: Icons.play_circle_filled_rounded,
                label: 'Reels',
                currentIndex: currentIndex,
                activeColor: _activeColor,
                inactiveColor: _inactiveColor,
                onTap: onTap,
              ),

              // 1 – Chats
              _NavItem(
                index: 1,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chats',
                currentIndex: currentIndex,
                activeColor: _activeColor,
                inactiveColor: _inactiveColor,
                onTap: onTap,
                badge: unreadChats,
              ),

              // 2 – Upload FAB (centre)
              _UploadFAB(onTap: onUploadTap),

              // 3 – Learn
              _NavItem(
                index: 3,
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
                label: 'Learn',
                currentIndex: currentIndex,
                activeColor: _activeColor,
                inactiveColor: _inactiveColor,
                onTap: onTap,
              ),

              // 4 – Profile
              _NavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                currentIndex: currentIndex,
                activeColor: _activeColor,
                inactiveColor: _inactiveColor,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Individual nav tab ───────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;
  final int badge;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    this.badge = 0,
  });

  bool get _active => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _active ? activeIcon : icon,
                    key: ValueKey(_active),
                    size: 24,
                    color: _active ? activeColor : inactiveColor,
                  ),
                ),
                // Unread badge
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: const TextStyle(
                            fontFamily: AppFonts.dmSans,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontSize: 10,
                fontWeight: _active ? FontWeight.w700 : FontWeight.w500,
                color: _active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Centre upload FAB ────────────────────────────────────────────────────────
/// Matches wireframe .bnav-home — gradient circle floating above the bar.
class _UploadFAB extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(bottom: 8), // float above bar
        decoration: BoxDecoration(
          gradient: AppColors.fabGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}
