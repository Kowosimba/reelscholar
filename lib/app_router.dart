import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/chats/chats_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'screens/reels/reels_screen.dart';
import 'screens/reels/search_reels_screen.dart';
import 'screens/reels/bookmarks_screen.dart';
import 'screens/reels/upload_reel_screen.dart';
import 'screens/tutor/modules_screen.dart';

class AppRouter {
  AppRouter._();

  // ── Route names ─────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPw = '/forgot-password';
  static const String resetPw = '/reset-password';
  static const String changePw = '/change-password';
  static const String home = '/home';
  static const String reels = '/reels';
  static const String searchReels = '/search-reels';
  static const String bookmarks = '/bookmarks';
  static const String uploadReel = '/upload-reel';
  static const String reelDetail = '/reel-detail';
  static const String modules = '/modules';
  static const String moduleDetail = '/module-detail';
  static const String tutorChat = '/tutor-chat';
  static const String flashcards = '/flashcards';
  static const String conceptMap = '/concept-map';
  static const String voiceLesson = '/voice-lesson';
  static const String sessionHistory = '/session-history';
  static const String chats = '/chats';
  static const String conversation = '/conversation';
  static const String studyGroups = '/study-groups';
  static const String hackathons = '/hackathons';
  static const String notifications = '/notifications';
  static const String progress = '/progress';
  static const String leaderboard = '/leaderboard';
  static const String achievements = '/achievements';
  static const String settings = '/settings';
  static const String searchUsers = '/search-users';
  static const String profile = '/profile';
  static const String publicProfile = '/public-profile';

  // ── Route map ────────────────────────────────────────────────────────────────
  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    onboarding: (_) => const OnboardingScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    verifyEmail: (_) => const EmailVerificationScreen(),
    forgotPw: (_) => const ForgotPasswordScreen(),
    resetPw: (_) => const ResetPasswordScreen(),
    changePw: (_) => const ChangePasswordScreen(),
    home: (_) => const MainScreen(),
    reels: (_) => const ReelsScreen(),
    searchReels: (_) => const SearchReelsScreen(),
    bookmarks: (_) => const BookmarksScreen(),
    uploadReel: (_) => const UploadReelScreen(),
    modules: (_) => const ModulesScreen(),
    chats: (_) => const ChatsScreen(),
    notifications: (_) => const NotificationsScreen(),
  };

  // ── On-generate route (for routes needing arguments) ─────────────────────────
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case publicProfile:
        final userId = settings.arguments as String?;
        return _slide(
          // ProfileScreen(userId: userId ?? ''),
          Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(child: Text('Profile: $userId')),
          ),
        );

      case conversation:
        final convId = settings.arguments as String?;
        return _slide(
          Scaffold(
            appBar: AppBar(title: const Text('Conversation')),
            body: Center(child: Text('Conversation: $convId')),
          ),
        );

      case moduleDetail:
        // final module = settings.arguments as TutorModule;
        // return _slide(ModuleDetailScreen(module: module));
        return _slide(
          const Scaffold(body: Center(child: Text('Module Detail'))),
        );

      case reelDetail:
        // final reel = settings.arguments as Reel;
        // return _slide(ReelDetailScreen(reel: reel));
        return _slide(const Scaffold(body: Center(child: Text('Reel Detail'))));

      default:
        return null;
    }
  }

  // ── Slide transition helper ───────────────────────────────────────────────
  static MaterialPageRoute _slide(Widget page) =>
      MaterialPageRoute(builder: (_) => page);
}
