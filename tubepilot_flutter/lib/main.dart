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

  // Firebase is only used for push notifications — it must NEVER be allowed
  // to block or crash app startup. If it fails or hangs (e.g. mismatched
  // google-services.json after a package rename, no network, etc.), we log
  // it and continue straight to runApp() so the app is never stuck on the
  // native splash screen forever.
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Firebase.initializeApp() timed out after 8s'),
    );
  } catch (e) {
    debugPrint('⚠️ Firebase init failed/skipped, continuing without push notifications: $e');
  }

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
    try {
      final appLinks = AppLinks();
      _linkSub = appLinks.uriLinkStream.listen((uri) {
        if (uri.scheme == 'tubepilot' && uri.host == 'oauth-success') {
          final connected = uri.queryParameters['youtube_connected'] == '1';
          final ctx = navigatorKey.currentContext;
          if (ctx != null) {
            showToast(ctx, connected ? 'YouTube channel connected!' : 'Failed to connect YouTube channel', isSuccess: connected, isError: !connected);
          }
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      debugPrint('⚠️ Deep link listener failed to start: $e');
    }
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
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
