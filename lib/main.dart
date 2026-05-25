import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/navigation_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/reel_provider.dart';
import 'providers/tutor_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/messaging_provider.dart';
import 'providers/study_group_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/social_provider.dart';
import 'core/services/messaging_service.dart';
import 'core/services/study_group_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/social_service.dart';
import 'core/services/hackathon_service.dart';
import 'providers/hackathon_provider.dart';
import 'core/services/progress_service.dart';
import 'providers/progress_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/voice_call_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'core/constants/app_theme.dart';
import 'app_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ReelScholarApp());
}

class ReelScholarApp extends StatelessWidget {
  const ReelScholarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReelProvider()),
        ChangeNotifierProvider(create: (_) => TutorProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => StudyGroupProvider(StudyGroupService())),
        ChangeNotifierProvider(create: (_) => ProfileProvider(ProfileService())),
        ChangeNotifierProvider(create: (_) => SocialProvider(SocialService())),
        ChangeNotifierProvider(create: (_) => HackathonProvider(HackathonService())),
        ChangeNotifierProvider(create: (_) => ProgressProvider(ProgressService())),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCallProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MessagingProvider>(
          create: (_) => MessagingProvider(MessagingService()),
          update: (_, auth, previous) {
            final m = previous ?? MessagingProvider(MessagingService());
            m.syncFromAuth(auth.user?.uid);
            return m;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) => MaterialApp(
          title: 'ReelScholar',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: theme.themeMode,
          initialRoute: AppRouter.splash,
          routes: AppRouter.routes,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
