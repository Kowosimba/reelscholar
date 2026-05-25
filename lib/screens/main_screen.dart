import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:reelscholar/core/utils/notification_router.dart';
import 'package:reelscholar/providers/auth_provider.dart';
import 'package:reelscholar/providers/navigation_provider.dart';
import 'package:reelscholar/providers/notification_provider.dart';
import 'package:reelscholar/providers/profile_provider.dart';
import 'package:reelscholar/core/constants/app_colors.dart';
import 'package:reelscholar/screens/reels/reels_screen.dart';
import 'package:reelscholar/screens/profile/my_profile_screen.dart';
import 'package:reelscholar/screens/study_groups/study_groups_screen.dart';
import 'package:reelscholar/screens/tutor/modules_screen.dart';
import 'navigation/app_bottom_nav_bar.dart';
import 'navigation/app_drawer.dart';
import '../providers/theme_provider.dart';
import 'chats/chats_screen.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'reelscholar_notifications',
  'ReelScholar',
  importance: Importance.high,
);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _initLocalNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFcm());
  }

  Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _initFcm() async {
    // Request permission (required on iOS, safe no-op on Android 12-)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register current token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && mounted) {
      context.read<AuthProvider>().updateFcmToken(token);
    }

    // Re-register when the token rotates
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      if (mounted) context.read<AuthProvider>().updateFcmToken(t);
    });

    // Foreground message — show local banner and bump the badge
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      if (mounted) {
        final notifProv = context.read<NotificationProvider>();
        notifProv.incrementUnreadCount();
        context
            .read<NavigationProvider>()
            .setUnreadNotifications(notifProv.unreadCount);
      }
    });

    // App in background — user tapped the notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (mounted) NotificationRouter.route(message.data, context);
    });

    // App was terminated — user tapped the notification that launched the app
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && mounted) {
      NotificationRouter.route(initial.data, context);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
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
        systemNavigationBarColor: isDark ? AppColors.darkNav : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      extendBody: false,
      backgroundColor: isDark ? AppColors.darkNav : AppColors.white,

      drawer: AppDrawer(
        user: _buildDrawerUser(
          context.watch<AuthProvider>(),
          context.watch<ProfileProvider>(),
        ),
        onSignOut: _confirmSignOut,
      ),

      body: IndexedStack(index: currentIndex, children: _screens),

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
    Navigator.pop(context);
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
