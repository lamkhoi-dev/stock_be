import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart' as app_logger;

import '../config/env.dart';

final _logger = app_logger.Logger(printer: app_logger.PrettyPrinter(methodCount: 0));

/// Secure storage provider.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Dio HTTP client provider.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: Env.connectTimeout),
    receiveTimeout: const Duration(milliseconds: Env.receiveTimeout),
    sendTimeout: const Duration(milliseconds: Env.sendTimeout),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  final storage = ref.read(secureStorageProvider);

  // 1. Auth Interceptor — attach JWT token
  dio.interceptors.add(AuthInterceptor(storage));

  // 2. Refresh Interceptor — auto refresh on 401
  dio.interceptors.add(RefreshInterceptor(dio, storage));

  // 3. Log Interceptor — debug mode logging
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => _logger.d(obj.toString()),
  ));

  return dio;
});

/// API client service for all HTTP requests.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(dioProvider));
});

// ─── Interceptors ──────────────────────────────────

/// Attaches JWT access token to every request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: Env.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Automatically refreshes token on 401 and retries the request.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._dio, this._storage);
  final Dio _dio;
  final FlutterSecureStorage _storage;
  bool _isRefreshing = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _storage.read(key: Env.refreshTokenKey);
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Call refresh endpoint
        final response = await Dio(BaseOptions(
          baseUrl: Env.apiBaseUrl,
          connectTimeout: const Duration(milliseconds: Env.connectTimeout),
          receiveTimeout: const Duration(milliseconds: Env.receiveTimeout),
        )).post('/auth/refresh-token', data: {
          'refreshToken': refreshToken,
        });

        if (response.statusCode == 200 && response.data['success'] == true) {
          final newAccessToken = response.data['data']['accessToken'] as String;
          final newRefreshToken =
              response.data['data']['refreshToken'] as String;

          // Store new tokens
          await _storage.write(key: Env.accessTokenKey, value: newAccessToken);
          await _storage.write(
              key: Env.refreshTokenKey, value: newRefreshToken);

          // Retry the failed request with new token
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccessToken';
          final retryResponse = await _dio.fetch(opts);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        _logger.e('Token refresh failed: $e');
        // Clear tokens — force re-login
        await _storage.delete(key: Env.accessTokenKey);
        await _storage.delete(key: Env.refreshTokenKey);
      }
      _isRefreshing = false;
    }
    handler.next(err);
  }
}

// ─── API Client ────────────────────────────────────

/// Centralized API client wrapping Dio for all backend calls.
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  // ─── Auth ──────────────────────────────────────
  /// Health check — quick ping to wake up backend on Render
  Future<Response> healthCheck() => _dio.get('/health');

  Future<Response> login(String email, String password) =>
      _dio.post('/auth/login', data: {'email': email, 'password': password});

  Future<Response> register(String name, String email, String password) =>
      _dio.post('/auth/register',
          data: {'name': name, 'email': email, 'password': password});

  Future<Response> getMe() => _dio.get('/auth/me');

  Future<Response> refreshToken(String refreshToken) =>
      _dio.post('/auth/refresh-token', data: {'refreshToken': refreshToken});

  Future<Response> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  // ─── Stocks ────────────────────────────────────
  Future<Response> searchStocks(String query) =>
      _dio.get('/stocks/search', queryParameters: {'q': query});

  Future<Response> getQuote(String symbol) =>
      _dio.get('/stocks/price/$symbol');

  Future<Response> getHistory(String symbol,
          {String period = 'D', String? startDate, String? endDate}) =>
      _dio.get('/stocks/chart/$symbol',
          queryParameters: {
            'period': period,
            if (startDate != null) 'startDate': startDate,
            if (endDate != null) 'endDate': endDate,
          });

  Future<Response> getMinuteChart(String symbol,
          {String? time, int maxPages = 6}) =>
      _dio.get('/stocks/minutechart/$symbol',
          queryParameters: {
            if (time != null) 'time': time,
            'pages': maxPages,
          });

  Future<Response> getMarketOverview() => _dio.get('/stocks/market');

  Future<Response> getTopGainers() =>
      _dio.get('/stocks/ranking/fluctuation', queryParameters: {'type': '1'});

  Future<Response> getTopLosers() =>
      _dio.get('/stocks/ranking/fluctuation', queryParameters: {'type': '3'});

  Future<Response> getVolumeRanking() =>
      _dio.get('/stocks/ranking/volume');

  Future<Response> getStockList({String sort = 'change', String market = 'all'}) =>
      _dio.get('/stocks/list', queryParameters: {'sort': sort, 'market': market});

  Future<Response> getIndex({String code = '0001'}) =>
      _dio.get('/stocks/index', queryParameters: {'code': code});

  Future<Response> getIndicators(String symbol, {String period = 'D'}) =>
      _dio.get('/stocks/indicators/$symbol',
          queryParameters: {'period': period});

  Future<Response> getIndicatorHistory(String symbol,
          {String period = 'D'}) =>
      _dio.get('/stocks/indicators/$symbol/history',
          queryParameters: {'period': period});

  Future<Response> getStockNews(String symbol) =>
      _dio.get('/stocks/news/$symbol');

  Future<Response> getInvestor(String symbol) =>
      _dio.get('/stocks/investor/$symbol');

  Future<Response> getTrades(String symbol) =>
      _dio.get('/stocks/trades/$symbol');

  // ─── Watchlist ─────────────────────────────────
  Future<Response> getWatchlist({bool withPrices = false}) =>
      _dio.get('/watchlist', queryParameters: {'withPrice': withPrices.toString()});

  Future<Response> addToWatchlist(String symbol) =>
      _dio.post('/watchlist', data: {'symbol': symbol});

  Future<Response> removeFromWatchlist(String symbol) =>
      _dio.delete('/watchlist/$symbol');

  Future<Response> isWatched(String symbol) =>
      _dio.get('/watchlist/check/$symbol');

  // ─── AI Analysis ───────────────────────────────
  Future<Response> analyzeStock(String symbol,
          {String level = 'basic', String model = 'gemini'}) =>
      _dio.post('/ai/analyze',
          data: {'symbol': symbol, 'level': level, 'model': model});

  Future<Response> getAIAnalysis(String id) => _dio.get('/ai/analysis/$id');

  Future<Response> getAIHistory({int page = 1, int limit = 10}) =>
      _dio.get('/ai/history',
          queryParameters: {'page': page, 'limit': limit});

  Future<Response> getAICredits() => _dio.get('/ai/credits');

  // ─── User ──────────────────────────────────────
  Future<Response> updateProfile(Map<String, dynamic> data) =>
      _dio.put('/users/profile', data: data);

  Future<Response> changePassword(
          String currentPassword, String newPassword) =>
      _dio.put('/users/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

  Future<Response> deleteAccount() => _dio.delete('/users/account');
}
