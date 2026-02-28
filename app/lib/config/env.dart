/// Environment configuration for the app.
///
/// Build with Render URL:
///   flutter build apk --dart-define=API_BASE_URL=https://YOUR-APP.onrender.com/api
///                      --dart-define=WS_BASE_URL=wss://YOUR-APP.onrender.com/ws
///
/// Build for local dev (emulator):
///   flutter run  (uses defaults below)
///
/// Build for local dev (real device on same WiFi):
///   flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:5000/api
///               --dart-define=WS_BASE_URL=ws://YOUR_PC_IP:5000/ws
class Env {
  Env._();

  // API
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stock-be-sv3n.onrender.com/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'wss://stock-be-sv3n.onrender.com/ws',
  );

  // Timeouts (ms) — generous for Render free-tier cold starts + KIS batch calls
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 60000;
  static const int sendTimeout = 15000;

  // WebSocket
  static const int wsReconnectDelay = 3000; // ms
  static const int wsMaxReconnectAttempts = 10;
  static const int wsPingInterval = 25000; // ms

  // Cache TTL (seconds)
  static const int quoteCacheTtl = 30;
  static const int historyCacheTtl = 300;
  static const int searchCacheTtl = 60;

  // Pagination
  static const int defaultPageSize = 20;

  // Auth
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
}
