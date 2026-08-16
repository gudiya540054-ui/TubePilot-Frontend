import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'services/auth_provider.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/meta_page_picker_screen.dart';
import 'widgets/common.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// ⚠️ TODO: replace with your real OneSignal App ID
const String oneSignalAppId = '205c5c05-ad00-4e06-a8f4-d7ff9245ccfd';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 8),
      onTimeout: () => throw Exception('Firebase.initializeApp() timed out after 8s'),
    );
  } catch (e) {
    debugPrint('⚠️ Firebase init failed/skipped, continuing without push notifications: $e');
  }

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
  final LanguageProvider _languageProvider = LanguageProvider();

  // Guards against handling the same OAuth callback link twice — e.g. if
  // the app was cold-started BY the deep link, both getInitialLink() and
  // the very first uriLinkStream event can sometimes deliver the same URI.
  Uri? _lastHandledUri;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initOneSignalPlayerIdSync();
    // Restore the last-selected language before first paint so the app
    // doesn't flash English then switch — see LanguageProvider.loadSaved().
    _languageProvider.loadSaved();
  }

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

  // Listens for "tubepilot://oauth-success" from YouTube, Google Drive, AND
  // now Meta (Facebook/Instagram) connect flows. Query params tell us which:
  // "youtube_connected", "drive_connected", "meta_connected". For Meta, an
  // extra "multiple_pages" param tells us whether to show the Page picker.
  //
  // IMPORTANT: uriLinkStream ONLY delivers links that arrive while the
  // listener is already registered (i.e. the app was alive in memory).
  // If Android/iOS killed the app while the user was in the Custom Tab
  // (common on low-memory devices, or after several seconds in the
  // browser) and the OAuth redirect then COLD-STARTS the app, that first
  // link is delivered via getInitialLink()/getInitialAppLink() instead —
  // uriLinkStream never sees it. Without checking the initial link too,
  // that cold-start callback is silently dropped, which is exactly what
  // produced the empty-query "ghost" callback hits seen on the backend
  // (the OS/browser still separately pinged the redirect URI, but the app
  // never processed the result).
  Future<void> _initDeepLinks() async {
    try {
      final appLinks = AppLinks();

      // 1) Handle the link that launched/cold-started the app, if any.
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }

      // 2) Handle any links that arrive while the app is already running.
      _linkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
    } catch (e) {
      debugPrint('⚠️ Deep link listener failed to start: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'tubepilot' || uri.host != 'oauth-success') return;

    // Avoid double-handling the exact same callback URI (see note above).
    if (_lastHandledUri == uri) return;
    _lastHandledUri = uri;

    final hasYoutubeParam = uri.queryParameters.containsKey('youtube_connected');
    final hasDriveParam = uri.queryParameters.containsKey('drive_connected');
    final hasMetaParam = uri.queryParameters.containsKey('meta_connected');
    final ctx = navigatorKey.currentContext;

    bool metaSuccess = false;
    bool metaMultiplePages = false;

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
    } else if (hasMetaParam) {
      metaSuccess = uri.queryParameters['meta_connected'] == '1';
      metaMultiplePages = uri.queryParameters['multiple_pages'] == '1';
      if (ctx != null && !metaMultiplePages) {
        showToast(ctx, metaSuccess ? 'Facebook / Instagram connected!' : 'Failed to connect Facebook / Instagram', isSuccess: metaSuccess, isError: !metaSuccess);
      }
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );

    // If the user manages multiple Facebook Pages, send them straight
    // to the picker so they can choose which one to connect.
    if (hasMetaParam && metaSuccess && metaMultiplePages) {
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const MetaPagePickerScreen()));
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _languageProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider<LanguageProvider>.value(value: _languageProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return LanguageScope(
            languageProvider: _languageProvider,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'TubePilot',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeProvider.themeMode,
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}