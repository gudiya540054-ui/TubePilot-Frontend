import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import '../main.dart';
import '../widgets/common.dart';

class PushService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Call once after a successful login (email, signup, or Google) so the
  /// backend has this device's token and can send real phone notifications
  /// (e.g. "your video just went public") even when the app is closed.
  static Future<void> initAfterLogin() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // user declined notification permission — nothing more to do
      }

      final token = await _messaging.getToken();
      if (token != null) {
        await ApiService.instance.registerDeviceToken(token);
      }

      // If the token rotates later (rare, but happens), keep the backend in sync
      _messaging.onTokenRefresh.listen((newToken) {
        ApiService.instance.registerDeviceToken(newToken).catchError((_) => <String, dynamic>{});
      });

      if (!_initialized) {
        _initialized = true;
        // Show an in-app toast when a push arrives while the app is open
        // (system tray already handles it automatically when the app is
        // backgrounded/closed, as long as the FCM payload has a "notification" block).
        FirebaseMessaging.onMessage.listen((message) {
          final ctx = navigatorKey.currentContext;
          final title = message.notification?.title;
          final body = message.notification?.body;
          if (ctx != null && title != null) {
            showToast(ctx, body != null ? '$title — $body' : title, isSuccess: true);
          }
        });
      }
    } catch (e) {
      // Push notifications are a nice-to-have — never let a failure here break login
      // ignore: avoid_print
      print('PushService init failed: $e');
    }
  }
}
