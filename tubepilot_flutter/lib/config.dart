// ⚠️ EDIT THESE before running / building the app
class AppConfig {
  // Your deployed backend URL (use 10.0.2.2 instead of localhost for Android emulator)
  static const String apiBaseUrl = 'https://tubepilot-backend-9era.onrender.com/api';

  // Google OAuth "Web application" Client ID (the SAME one already in your
  // backend .env as GOOGLE_CLIENT_ID). This is passed as serverClientId so
  // the backend can verify the token — NOT the Android/iOS client ID.
  static const String googleServerClientId =
      '179051847539-rqn8vtp6ma7ub6dsggsnt2jvk73tuhq2.apps.googleusercontent.com';

  static const int diamondCostPerUpload = 10;
  static const int freeUploadsPerMonth = 20;
}