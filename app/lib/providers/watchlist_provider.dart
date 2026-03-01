import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/watchlist_item.dart';
import '../services/api_client.dart';

/// Watchlist state.
class WatchlistState {
  const WatchlistState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  final List<WatchlistItem> items;
  final bool isLoading;
  final String? error;

  WatchlistState copyWith({
    List<WatchlistItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return WatchlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Watchlist notifier — manages user's watchlist.
class WatchlistNotifier extends StateNotifier<WatchlistState> {
  WatchlistNotifier(this._api) : super(const WatchlistState());
  final ApiClient _api;

  /// Map backend watchlist item to WatchlistItem model.
  WatchlistItem _mapItem(Map<String, dynamic> w) {
    return WatchlistItem(
      id: (w['_id'] ?? w['id'] ?? w['symbol'] ?? '').toString(),
      symbol: (w['symbol'] ?? '').toString(),
      name: (w['nameKo'] ?? w['name'] ?? '').toString(),
      englishName: (w['name'] ?? '').toString(),
      exchange: (w['market'] ?? w['exchange'] ?? '').toString(),
      order: (w['order'] as num?)?.toInt() ?? 0,
      addedAt: w['addedAt'] != null ? DateTime.tryParse(w['addedAt'].toString()) : null,
      currentPrice: (w['currentPrice'] as num?)?.toDouble(),
      change: (w['change'] as num?)?.toDouble(),
      changePercent: (w['changePct'] ?? w['changePercent'] as num?)?.toDouble(),
    );
  }

  /// Load watchlist with optional live prices.
  Future<void> loadWatchlist({bool withPrices = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.getWatchlist(withPrices: withPrices);
      if (response.data['success'] == true) {
        final rawData = response.data['data'];
        // Backend returns {items: [...], count: n} or possibly a raw list
        final List rawItems;
        if (rawData is Map) {
          rawItems = rawData['items'] as List? ?? [];
        } else if (rawData is List) {
          rawItems = rawData;
        } else {
          rawItems = [];
        }
        final items = rawItems
            .map((w) => _mapItem(w as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a stock to watchlist.
  Future<bool> addStock(String symbol) async {
    try {
      final response = await _api.addToWatchlist(symbol);
      if (response.data['success'] == true) {
        await loadWatchlist();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove a stock from watchlist.
  Future<bool> removeStock(String symbol) async {
    try {
      final response = await _api.removeFromWatchlist(symbol);
      if (response.data['success'] == true) {
        state = state.copyWith(
          items: state.items.where((w) => w.symbol != symbol).toList(),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Check if a stock is in the watchlist.
  bool isWatched(String symbol) {
    return state.items.any((w) => w.symbol == symbol);
  }
}

/// Watchlist provider instance.
final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
  return WatchlistNotifier(ref.read(apiClientProvider));
});
