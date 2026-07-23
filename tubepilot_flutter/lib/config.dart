// ⚠️ EDIT THESE before running / building the app
class AppConfig {
  // Your deployed backend URL (use 10.0.2.2 instead of localhost for Android emulator)
  static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

  // Google OAuth "Web application" Client ID (the SAME one already in your
  // backend .env as GOOGLE_CLIENT_ID). This is passed as serverClientId so
  // the backend can verify the token — NOT the Android/iOS client ID.
  static const String googleServerClientId =
      'your_web_client_id.apps.googleusercontent.com';

  static const int diamondCostPerUpload = 10;
  static const int freeUploadsPerMonth = 20;
}
