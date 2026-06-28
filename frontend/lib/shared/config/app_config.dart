class AppConfig {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  static const bool enableOcr = bool.fromEnvironment(
    'ENABLE_OCR',
    defaultValue: false,
  );

  static const bool enableNotifications = bool.fromEnvironment(
    'ENABLE_NOTIFICATIONS',
    defaultValue: true,
  );

  static const String firebaseWebVapidKey = String.fromEnvironment(
    'FIREBASE_WEB_VAPID_KEY',
    defaultValue: 'BByFZgPis7H9VOxreoKe70XY6-1ww9QtPxIDKJ9ha372nQbtyKIuyN3KYDEMMQvUXbAZey-Rj-glpG_yZo5Kbvo',
  );

  static const bool enableSentry = bool.fromEnvironment(
    'ENABLE_SENTRY',
    defaultValue: false,
  );

  static const String turnstileSiteKey = String.fromEnvironment(
    'TURNSTILE_SITE_KEY',
    defaultValue: '',
  );

  static const String sentryFlutterDsn = String.fromEnvironment(
    'SENTRY_FLUTTER_DSN',
    defaultValue: '',
  );

  static const String sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String sentryRelease = String.fromEnvironment(
    'SENTRY_RELEASE',
    defaultValue: '1.0.0',
  );
}
