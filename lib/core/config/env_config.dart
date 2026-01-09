import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
/// Loads configuration from .env files based on build flavor
class EnvConfig {
  static String get fileName {
    // This will be set during build time
    const environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
    return '.env.$environment';
  }

  /// Initialize environment configuration
  static Future<void> initialize() async {
    await dotenv.load(fileName: fileName);
  }

  // App Configuration
  static String get appName => dotenv.get('APP_NAME', fallback: 'Prism');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');

  // Firebase Configuration
  static String get firebaseApiKey => dotenv.get('FIREBASE_API_KEY');
  static String get firebaseAppId => dotenv.get('FIREBASE_APP_ID');
  static String get firebaseMessagingSenderId => dotenv.get('FIREBASE_MESSAGING_SENDER_ID');
  static String get firebaseProjectId => dotenv.get('FIREBASE_PROJECT_ID');
  static String get firebaseStorageBucket => dotenv.get('FIREBASE_STORAGE_BUCKET');

  // Platform Specific
  static String get iosBundleId => dotenv.get('IOS_BUNDLE_ID', fallback: 'com.example.prism');
  static String get androidPackageName => dotenv.get('ANDROID_PACKAGE_NAME', fallback: 'com.example.prism');

  // API Configuration
  static String get apiBaseUrl => dotenv.get('API_BASE_URL', fallback: 'https://api.example.com');
  static int get apiTimeout => int.parse(dotenv.get('API_TIMEOUT', fallback: '30000'));

  // Feature Flags
  static bool get enableAnalytics => dotenv.get('ENABLE_ANALYTICS', fallback: 'true') == 'true';
  static bool get enableCrashlytics => dotenv.get('ENABLE_CRASHLYTICS', fallback: 'true') == 'true';
  static bool get enableChat => dotenv.get('ENABLE_CHAT', fallback: 'false') == 'true';
  static bool get enableVideoCalls => dotenv.get('ENABLE_VIDEO_CALLS', fallback: 'false') == 'true';

  // Third-party Services
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  static String get stripePublishableKey => dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');

  // Debug Settings
  static bool get debugMode => dotenv.get('DEBUG_MODE', fallback: 'false') == 'true';
  static bool get showDebugBanner => dotenv.get('SHOW_DEBUG_BANNER', fallback: 'false') == 'true';

  // Environment Checks
  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';

  /// Print configuration (for debugging, never log in production!)
  static void printConfig() {
    if (!isProduction) {
      print('=== Environment Configuration ===');
      print('App Name: $appName');
      print('Environment: $environment');
      print('Firebase Project: $firebaseProjectId');
      print('API Base URL: $apiBaseUrl');
      print('Analytics Enabled: $enableAnalytics');
      print('Debug Mode: $debugMode');
      print('=================================');
    }
  }
}
