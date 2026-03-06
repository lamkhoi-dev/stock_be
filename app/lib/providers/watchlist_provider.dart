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
  bool _isEnriching = false;

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

  /// Load watchlist — fast 2-step: items first, then prices via batch endpoint.
  Future<void> loadWatchlist({bool withPrices = true}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Load items WITHOUT prices (fast response)
      final response = await _api.getWatchlist(withPrices: false);
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

        // Step 2: Enrich with live prices via batch endpoint (background)
        if (items.isNotEmpty && withPrices) {
          _enrichPrices(); // Fire-and-forget — prices fill in progressively
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Enrich current items with live prices from batch-prices endpoint.
  /// Retries up to 2 times for missing items with a short delay.
  Future<void> _enrichPrices() async {
    if (_isEnriching) return;
    _isEnriching = true;
    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final items = state.items;
          // Only request prices for items still missing data
          final needPrice = items
              .where((w) => w.currentPrice == null || w.currentPrice == 0)
              .map((w) => w.symbol)
              .toList();
          if (needPrice.isEmpty) return; // All items have prices

          final response = await _api.getBatchPrices(needPrice);
          if (response.data['success'] == true) {
            final prices = response.data['data'] as Map<String, dynamic>;
            if (prices.isNotEmpty) {
              final enriched = state.items.map((item) {
                if (prices.containsKey(item.symbol)) {
                  final p = prices[item.symbol] as Map<String, dynamic>;
                  return item.copyWith(
                    currentPrice: (p['price'] as num?)?.toDouble(),
                    change: (p['change'] as num?)?.toDouble(),
                    changePercent: (p['changePct'] as num?)?.toDouble(),
                  );
                }
                return item;
              }).toList();
              state = state.copyWith(items: enriched);
            }
            // Check if all items now have prices
            final stillMissing = state.items
                .where((w) => w.currentPrice == null || w.currentPrice == 0)
                .length;
            if (stillMissing == 0) return; // All done
          }
        } catch (_) {
          // Price enrichment failure is not critical
        }
        // Wait before retry
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } finally {
      _isEnriching = false;
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
