import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/app_colors.dart';
import 'navigation/app_bottom_nav_bar.dart';
import 'navigation/app_drawer.dart';
import 'chats/chats_screen.dart';

// ── Placeholder screens (replace with real screens as you build them) ──────────
// import 'reels/reels_screen.dart';
// import 'tutor/modules_screen.dart';
// import 'profile/profile_screen.dart';
// import 'reels/upload_reel_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDarkMode = false;

  // ── Tab screens ──────────────────────────────────────────────────────────────
  // Index 0 = Reels, 1 = Chats, 2 = (FAB), 3 = Learn, 4 = Profile
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _ReelsPlaceholder(onMenuTap: _openDrawer), // 0 – Reels
      const ChatsScreen(),                        // 1 – Chats
      const SizedBox.shrink(),                    // 2 – FAB slot (never shown)
      _LearnPlaceholder(onMenuTap: _openDrawer),  // 3 – Learn
      _ProfilePlaceholder(onMenuTap: _openDrawer),// 4 – Profile
    ];
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _openUpload() {
    Navigator.pushNamed(context, '/upload-reel');
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final currentIndex = navProvider.currentIndex;
    final isReels = currentIndex == 0;

    // System bar style — dark on reels, light elsewhere
    SystemChrome.setSystemUIOverlayStyle(
      isReels
          ? const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
              systemNavigationBarColor: Colors.black,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true, // reels bleeds behind transparent nav bar
      backgroundColor:
          isReels ? Colors.black : AppColors.white,

      // ── Sidebar drawer ─────────────────────────────────────────────────
      drawer: AppDrawer(
        user: _buildDrawerUser(),
        isDarkMode: _isDarkMode,
        onDarkModeToggle: () => setState(() => _isDarkMode = !_isDarkMode),
        onSignOut: _confirmSignOut,
      ),

      // ── Body: IndexedStack keeps each tab alive ──────────────────────
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),

      // ── Bottom navigation bar ──────────────────────────────────────────
      bottomNavigationBar: AppBottomNavBar(
        isDark: isReels,
        onUploadTap: _openUpload,
      ),
    );
  }

  DrawerUser? _buildDrawerUser() {
    // TODO: replace with real auth provider user
    return const DrawerUser(
      fullName: 'Tendai Moyo',
      programme: 'BEng Computer Engineering · Year 3',
      totalXp: 3_980,
      currentStreak: 12,
    );
  }

  Future<void> _confirmSignOut() async {
    Navigator.pop(context); // close drawer first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: const Text('Sign Out',
            style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to sign out of ReelScholar?',
          style: TextStyle(
              fontFamily: AppFonts.dmSans,
              fontSize: 14,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: call auth provider logout
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder screens — swap these out with real implementations
// ─────────────────────────────────────────────────────────────────────────────

/// Reels feed placeholder — in production this is your ReelsScreen
class _ReelsPlaceholder extends StatelessWidget {
  final VoidCallback onMenuTap;

  const _ReelsPlaceholder({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    // In production: return ReelsScreen();
    // The hamburger icon in the top-left opens the drawer
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gradient video placeholder bg
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a2740), Color(0xFF0d1520)],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.play_circle_outline_rounded,
                size: 64, color: Colors.white12),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    // Hamburger — opens drawer
                    GestureDetector(
                      onTap: onMenuTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    const Text('ReelScholar',
                        style: TextStyle(
                          fontFamily: AppFonts.sora,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    const Spacer(),
                    const Icon(Icons.search_rounded,
                        color: Colors.white, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnPlaceholder extends StatelessWidget {
  final VoidCallback onMenuTap;

  const _LearnPlaceholder({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    // In production: return ModulesScreen();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: AppColors.textPrimary),
          onPressed: onMenuTap,
        ),
        title: const Text('Learn',
            style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded, size: 56, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Modules Screen',
                style: TextStyle(
                    fontFamily: AppFonts.sora,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Wire in ModulesScreen here',
                style: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  final VoidCallback onMenuTap;

  const _ProfilePlaceholder({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    // In production: return ProfileScreen();
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded,
              color: AppColors.textPrimary),
          onPressed: onMenuTap,
        ),
        title: const Text('Profile',
            style: TextStyle(
                fontFamily: AppFonts.sora,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary)),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, size: 56, color: AppColors.primary),
            SizedBox(height: 16),
            Text('Profile Screen',
                style: TextStyle(
                    fontFamily: AppFonts.sora,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text('Wire in ProfileScreen here',
                style: TextStyle(
                    fontFamily: AppFonts.dmSans,
                    color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
