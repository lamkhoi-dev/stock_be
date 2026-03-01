import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart' as app_logger;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import '../services/api_client.dart';

final _logger = app_logger.Logger(printer: app_logger.PrettyPrinter(methodCount: 0));

/// WebSocket connection status.
enum WSStatus { disconnected, connecting, connected, reconnecting }

/// WebSocket state.
class WSState {
  const WSState({
    this.status = WSStatus.disconnected,
    this.subscribedSymbols = const {},
    this.lastPrices = const {},
    this.marketStatus,
    this.error,
  });

  final WSStatus status;
  final Set<String> subscribedSymbols;
  final Map<String, Map<String, dynamic>> lastPrices; // symbol → price data
  final String? marketStatus;
  final String? error;

  WSState copyWith({
    WSStatus? status,
    Set<String>? subscribedSymbols,
    Map<String, Map<String, dynamic>>? lastPrices,
    String? marketStatus,
    String? error,
  }) {
    return WSState(
      status: status ?? this.status,
      subscribedSymbols: subscribedSymbols ?? this.subscribedSymbols,
      lastPrices: lastPrices ?? this.lastPrices,
      marketStatus: marketStatus ?? this.marketStatus,
      error: error,
    );
  }
}

/// WebSocket notifier — manages real-time connection to backend.
class WSNotifier extends StateNotifier<WSState> {
  WSNotifier(this._storage) : super(const WSState());

  final FlutterSecureStorage _storage;
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Connect to WebSocket server.
  Future<void> connect() async {
    if (state.status == WSStatus.connecting ||
        state.status == WSStatus.connected) {
      return;
    }

    state = state.copyWith(status: WSStatus.connecting, error: null);

    try {
      final uri = Uri.parse(Env.wsBaseUrl);
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection
      await _channel!.ready;

      // Authenticate with JWT
      final token = await _storage.read(key: Env.accessTokenKey);
      if (token != null) {
        _send({'type': 'auth', 'token': token});
      }

      state = state.copyWith(status: WSStatus.connected);
      _reconnectAttempts = 0;

      // Start ping timer
      _startPingTimer();

      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _logger.e('WebSocket connect error: $e');
      state = state.copyWith(
        status: WSStatus.disconnected,
        error: e.toString(),
      );
      _scheduleReconnect();
    }
  }

  /// Subscribe to real-time price updates for a symbol.
  void subscribe(String symbol) {
    if (state.status != WSStatus.connected) return;
    _send({'type': 'subscribe', 'symbol': symbol});
    state = state.copyWith(
      subscribedSymbols: {...state.subscribedSymbols, symbol},
    );
  }

  /// Unsubscribe from a symbol.
  void unsubscribe(String symbol) {
    if (state.status != WSStatus.connected) return;
    _send({'type': 'unsubscribe', 'symbol': symbol});
    final symbols = {...state.subscribedSymbols};
    symbols.remove(symbol);
    state = state.copyWith(subscribedSymbols: symbols);
  }

  /// Disconnect and clean up.
  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = const WSState();
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'auth_success':
          _logger.i('WebSocket authenticated');
          // Re-subscribe to previously tracked symbols
          for (final symbol in state.subscribedSymbols) {
            _send({'type': 'subscribe', 'symbol': symbol});
          }
          break;

        case 'price_update':
          final symbol = data['symbol'] as String;
          final prices = {...state.lastPrices};
          prices[symbol] = data;
          state = state.copyWith(lastPrices: prices);
          break;

        case 'market_status':
          state = state.copyWith(marketStatus: data['status'] as String?);
          break;

        case 'pong':
          // Heartbeat response — connection alive
          break;

        case 'error':
          _logger.w('WebSocket error: ${data['message']}');
          state = state.copyWith(error: data['message'] as String?);
          break;

        default:
          _logger.d('WebSocket unknown message type: $type');
      }
    } catch (e) {
      _logger.e('WebSocket message parse error: $e');
    }
  }

  void _onError(dynamic error) {
    _logger.e('WebSocket error: $error');
    state = state.copyWith(
      status: WSStatus.disconnected,
      error: error.toString(),
    );
    _scheduleReconnect();
  }

  void _onDone() {
    _logger.w('WebSocket connection closed');
    _pingTimer?.cancel();
    state = state.copyWith(status: WSStatus.disconnected);
    _scheduleReconnect();
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(milliseconds: Env.wsPingInterval),
      (_) => _send({'type': 'ping'}),
    );
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= Env.wsMaxReconnectAttempts) {
      _logger.e('WebSocket max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delay = Env.wsReconnectDelay * _reconnectAttempts; // exponential-ish

    _logger.i('WebSocket reconnecting in ${delay}ms '
        '(attempt $_reconnectAttempts/${Env.wsMaxReconnectAttempts})');

    state = state.copyWith(status: WSStatus.reconnecting);
    _reconnectTimer = Timer(Duration(milliseconds: delay), connect);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// WebSocket provider instance.
final websocketProvider = StateNotifierProvider<WSNotifier, WSState>((ref) {
  final storage = ref.read(secureStorageProvider);
  return WSNotifier(storage);
});
