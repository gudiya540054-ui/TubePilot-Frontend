import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/theme_provider.dart';
import 'services/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/common.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Uses android/app/google-services.json automatically — no extra config needed on Android.
  await Firebase.initializeApp();
  runApp(const TubePilotApp());
}

class TubePilotApp extends StatefulWidget {
  const TubePilotApp({super.key});
  @override
  State<TubePilotApp> createState() => _TubePilotAppState();
}

class _TubePilotAppState extends State<TubePilotApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  // Listens for the custom "tubepilot://oauth-success" deep link that the
  // backend redirects to once a YouTube channel connect finishes in the
  // external browser (see backend/routes/youtube.js -> platform=mobile).
  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'tubepilot' && uri.host == 'oauth-success') {
        final connected = uri.queryParameters['youtube_connected'] == '1';
        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          showToast(ctx, connected ? 'YouTube channel connected!' : 'Failed to connect YouTube channel', isSuccess: connected, isError: !connected);
        }
        // Bounce back to a fresh Dashboard so it reloads the connected channel state
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'TubePilot',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode, // defaults to light until user toggles
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
