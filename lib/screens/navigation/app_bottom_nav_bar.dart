import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/providers/navigation_provider.dart';

/// Shadcn-inspired bottom nav: neutral surface, crisp border, soft active pill.
class AppBottomNavBar extends StatelessWidget {
  final bool isDark;

  const AppBottomNavBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Consumer<NavigationProvider>(
      builder: (context, nav, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            12,
            8,
            12,
            bottomInset == 0 ? 10 : bottomInset + 6,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF020617) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                    ),
                  ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    index: 0,
                    label: 'Home',
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    currentIndex: nav.currentIndex,
                    onTap: nav.setTab,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 1,
                    label: 'Chats',
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    currentIndex: nav.currentIndex,
                    onTap: nav.setTab,
                    badge: nav.unreadChats,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 2,
                    label: 'Groups',
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    currentIndex: nav.currentIndex,
                    onTap: nav.setTab,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 3,
                    label: 'Learn',
                    icon: Icons.psychology_outlined,
                    activeIcon: Icons.psychology_rounded,
                    currentIndex: nav.currentIndex,
                    onTap: nav.setTab,
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    index: 4,
                    label: 'Me',
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    currentIndex: nav.currentIndex,
                    onTap: nav.setTab,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badge;
  final bool isDark;

  const _NavItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.badge = 0,
  });

  bool get active => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? (isDark ? Colors.white : AppColors.textPrimary)
        : (isDark ? const Color(0xFF94A3B8) : AppColors.textTertiary);
    final activeBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF8FAFC);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active ? activeBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: active
                          ? Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                            )
                          : null,
                    ),
                    child: Icon(
                      active ? activeIcon : icon,
                      size: 20,
                      color: fg,
                    ),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -4,
                      top: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF020617)
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            badge > 9 ? '9+' : '$badge',
                            style: const TextStyle(
                              fontFamily: AppFonts.dmSans,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.dmSans,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
