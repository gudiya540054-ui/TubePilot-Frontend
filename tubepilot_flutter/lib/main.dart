import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'providers/theme_provider.dart';
import 'services/auth_provider.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/common.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// ⚠️ TODO: replace with your real OneSignal App ID
// (OneSignal dashboard -> Settings -> Keys & IDs -> "OneSignal App ID").
// This is the PUBLIC app id, safe to ship in the app — NOT the REST API Key
// (that one stays server-side only, in the backend's .env as
// ONESIGNAL_API_KEY, used by utils/oneSignalPush.js).
const String oneSignalAppId = '205c5c05-ad00-4e06-a8f4-d7ff9245ccfd';

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

  // OneSignal is only used for the "your free uploads + diamonds are
  // exhausted" alert (see backend utils/oneSignalPush.js). Just like
  // Firebase above, it must never block or crash app startup — wrapped in
  // its own try/catch so a OneSignal outage/misconfig never affects the rest
  // of the app.
  try {
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.requestPermission(true);
  } catch (e) {
    debugPrint('⚠️ OneSignal init failed/skipped, continuing without diamond-alert push: $e');
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
    _initOneSignalPlayerIdSync();
  }

  // Sends the device's OneSignal player/subscription id to the backend
  // (POST /api/notifications/register-onesignal-player) so
  // utils/oneSignalPush.js can target this device later. Registers
  // immediately if an id is already available (e.g. app relaunch), and also
  // listens for future changes (e.g. right after the user grants
  // notification permission for the first time).
  void _initOneSignalPlayerIdSync() {
    try {
      final existingId = OneSignal.User.pushSubscription.id;
      if (existingId != null) {
        ApiService.instance.registerOneSignalPlayerId(existingId).catchError((_) {});
      }

      OneSignal.User.pushSubscription.addObserver((state) {
        final playerId = OneSignal.User.pushSubscription.id;
        if (playerId != null) {
          ApiService.instance.registerOneSignalPlayerId(playerId).catchError((_) {});
        }
      });
    } catch (e) {
      debugPrint('⚠️ OneSignal player id sync failed to start: $e');
    }
  }

  // Listens for the custom "tubepilot://oauth-success" deep link that the
  // backend redirects to once EITHER a YouTube channel connect (see
  // backend/routes/youtube.js -> platform=mobile) OR a Google Drive connect
  // (see backend/routes/drive.js -> platform=mobile) finishes in the
  // external browser. Query params tell us which one just happened:
  // "youtube_connected" for YouTube, "drive_connected" for Drive.
  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();
      _linkSub = appLinks.uriLinkStream.listen((uri) {
        if (uri.scheme == 'tubepilot' && uri.host == 'oauth-success') {
          final hasYoutubeParam = uri.queryParameters.containsKey('youtube_connected');
          final hasDriveParam = uri.queryParameters.containsKey('drive_connected');
          final ctx = navigatorKey.currentContext;

          if (hasYoutubeParam) {
            final connected = uri.queryParameters['youtube_connected'] == '1';
            if (ctx != null) {
              showToast(ctx, connected ? 'YouTube channel connected!' : 'Failed to connect YouTube channel', isSuccess: connected, isError: !connected);
            }
          } else if (hasDriveParam) {
            final connected = uri.queryParameters['drive_connected'] == '1';
            if (ctx != null) {
              showToast(ctx, connected ? 'Google Drive connected!' : 'Failed to connect Google Drive', isSuccess: connected, isError: !connected);
            }
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