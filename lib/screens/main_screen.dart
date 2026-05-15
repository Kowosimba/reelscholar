import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/profile_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'package:reelscholar/screens/reels/reels_screen.dart';
import 'package:reelscholar/screens/profile/my_profile_screen.dart';
import 'package:reelscholar/screens/study_groups/study_groups_screen.dart';
import 'package:reelscholar/screens/tutor/modules_screen.dart';
import 'navigation/app_bottom_nav_bar.dart';
import 'navigation/app_drawer.dart';
import '../providers/theme_provider.dart';
import 'chats/chats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Tab screens ──────────────────────────────────────────────────────────────
  // Index 0 = Reels, 1 = Chats, 2 = Study Groups, 3 = Learn, 4 = Profile
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ReelsScreen(onMenuTap: _openDrawer),
      const ChatsScreen(),
      const StudyGroupsScreen(),
      ModulesScreen(onMenuTap: _openDrawer),
      const MyProfileScreen(),
    ];
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentIndex = navProvider.currentIndex;
    final isDark = themeProvider.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF020617) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      extendBody: false, // fixed overlap
      backgroundColor: isDark ? const Color(0xFF020617) : AppColors.white,

      // ── Sidebar drawer ─────────────────────────────────────────────────
      drawer: AppDrawer(
        user: _buildDrawerUser(
          context.watch<AuthProvider>(),
          context.watch<ProfileProvider>(),
        ),
        onSignOut: _confirmSignOut,
      ),

      // ── Body: IndexedStack keeps each tab alive ──────────────────────
      body: IndexedStack(index: currentIndex, children: _screens),

      // ── Bottom navigation bar ──────────────────────────────────────────
      bottomNavigationBar: AppBottomNavBar(isDark: isDark),
    );
  }

  DrawerUser _buildDrawerUser(AuthProvider auth, ProfileProvider profile) {
    final u = auth.user;
    if (u == null) {
      return const DrawerUser(
        fullName: 'Guest',
        programme: null,
        totalXp: 0,
        currentStreak: 0,
      );
    }
    // Prefer the fresh URL from ProfileProvider (re-fetched on each profile load)
    // over the stale signed URL stored in AuthProvider at login time.
    final freshPicUrl = profile.profilePicUrl ?? u.profilePicUrl;
    return DrawerUser(
      fullName: u.fullName,
      profilePicUrl: freshPicUrl,
      programme: '${u.degreeProgramme} · Year ${u.yearLevel}',
      totalXp: u.totalXp,
      currentStreak: u.currentStreak,
    );
  }

  Future<void> _confirmSignOut() async {
    Navigator.pop(context); // close drawer first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontFamily: AppFonts.sora,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out of ReelScholar?',
          style: TextStyle(
            fontFamily: AppFonts.dmSans,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: AppFonts.dmSans,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
