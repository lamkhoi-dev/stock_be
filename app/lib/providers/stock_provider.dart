import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stock.dart';
import '../models/indicator.dart';
import '../services/api_client.dart';

/// Stock data state.
class StockState {
  const StockState({
    this.quote,
    this.rawPrice,
    this.history,
    this.indicators,
    this.news = const [],
    this.isLoading = false,
    this.error,
  });

  final Quote? quote;
  /// Raw price response from backend — contains extra fields like
  /// name, marketCap, per, pbr, eps, dividendYield, high52w, low52w.
  final Map<String, dynamic>? rawPrice;
  final List<Map<String, dynamic>>? history;
  final TechnicalSummary? indicators;
  final List<Map<String, dynamic>> news;
  final bool isLoading;
  final String? error;

  StockState copyWith({
    Quote? quote,
    Map<String, dynamic>? rawPrice,
    List<Map<String, dynamic>>? history,
    TechnicalSummary? indicators,
    List<Map<String, dynamic>>? news,
    bool? isLoading,
    String? error,
  }) {
    return StockState(
      quote: quote ?? this.quote,
      rawPrice: rawPrice ?? this.rawPrice,
      history: history ?? this.history,
      indicators: indicators ?? this.indicators,
      news: news ?? this.news,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─── Helpers to map backend JSON → Flutter models ─────────────

/// Map backend /stocks/price/:symbol response → Quote.
Quote _mapQuote(Map<String, dynamic> d) {
  return Quote(
    symbol: d['symbol'] as String? ?? '',
    currentPrice: (d['price'] as num?)?.toDouble() ?? 0,
    change: (d['change'] as num?)?.toDouble() ?? 0,
    changePercent: (d['changePct'] as num?)?.toDouble() ?? 0,
    open: (d['open'] as num?)?.toDouble() ?? 0,
    high: (d['high'] as num?)?.toDouble() ?? 0,
    low: (d['low'] as num?)?.toDouble() ?? 0,
    previousClose: (d['prevClose'] as num?)?.toDouble() ?? 0,
    volume: (d['volume'] as num?)?.toDouble() ?? 0,
    value: (d['tradingValue'] as num?)?.toDouble() ?? 0,
  );
}

/// Map backend news item → raw map with Flutter-friendly keys.
Map<String, dynamic> _mapNewsItem(Map<String, dynamic> n) {
  final timeVal = n['time'] ?? n['providerPublishTime'];
  DateTime? publishedAt;
  if (timeVal is int) {
    publishedAt = DateTime.fromMillisecondsSinceEpoch(timeVal * 1000);
  } else if (timeVal is String) {
    publishedAt = DateTime.tryParse(timeVal);
  }
  return {
    'title': n['title'] ?? '',
    'source': n['publisher'] ?? n['source'] ?? '',
    'url': n['link'] ?? n['url'] ?? '',
    'thumbnailUrl': n['thumbnail'] ?? n['thumbnailUrl'],
    'publishedAt': publishedAt,
  };
}

/// Stock detail notifier — fetches all data for a single stock.
class StockNotifier extends StateNotifier<StockState> {
  StockNotifier(this._api) : super(const StockState());
  final ApiClient _api;

  /// Load all data for a stock symbol.
  Future<void> loadStock(String symbol) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Fetch quote first — this is essential
      final quoteRes = await _api.getQuote(symbol);
      Quote? quote;
      Map<String, dynamic>? rawPrice;
      if (quoteRes.data['success'] == true) {
        rawPrice = Map<String, dynamic>.from(quoteRes.data['data'] as Map);
        quote = _mapQuote(rawPrice);
      }

      // Show the quote immediately, then load the rest in the background
      state = state.copyWith(
        quote: quote,
        rawPrice: rawPrice,
        isLoading: false,
      );

      // Fetch remaining data in parallel — failures are non-fatal
      final results = await Future.wait([
        _api.getHistory(symbol).catchError((_) => _emptyResponse()),
        _api.getIndicators(symbol).catchError((_) => _emptyResponse()),
        _api.getStockNews(symbol).catchError((_) => _emptyResponse()),
      ]);

      final historyRes = results[0];
      final indicatorsRes = results[1];
      final newsRes = results[2];

      List<Map<String, dynamic>>? history;
      if (historyRes.data != null && historyRes.data['success'] == true) {
        final raw = historyRes.data['data'];
        if (raw is List) {
          history = raw.cast<Map<String, dynamic>>();
        }
      }

      TechnicalSummary? indicators;
      if (indicatorsRes.data != null && indicatorsRes.data['success'] == true) {
        indicators = TechnicalSummary.fromJson(
            indicatorsRes.data['data'] as Map<String, dynamic>);
      }

      List<Map<String, dynamic>> news = [];
      if (newsRes.data != null && newsRes.data['success'] == true) {
        news = (newsRes.data['data'] as List)
            .map((n) => _mapNewsItem(n as Map<String, dynamic>))
            .toList();
      }

      state = state.copyWith(
        history: history,
        indicators: indicators,
        news: news,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a dummy Response for failed non-critical requests.
  dynamic _emptyResponse() {
    return _FakeResponse();
  }

  /// Refresh just the quote (for real-time updates).
  Future<void> refreshQuote(String symbol) async {
    try {
      final response = await _api.getQuote(symbol);
      if (response.data['success'] == true) {
        final rawPrice = Map<String, dynamic>.from(response.data['data'] as Map);
        state = state.copyWith(
          quote: _mapQuote(rawPrice),
          rawPrice: rawPrice,
        );
      }
    } catch (_) {}
  }
}

/// Stock detail provider (family — one per symbol).
final stockProvider =
    StateNotifierProvider.family<StockNotifier, StockState, String>(
  (ref, symbol) {
    final notifier = StockNotifier(ref.read(apiClientProvider));
    notifier.loadStock(symbol);
    return notifier;
  },
);

/// Search results provider.
final stockSearchProvider =
    FutureProvider.family<List<Stock>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final api = ref.read(apiClientProvider);
  final response = await api.searchStocks(query);
  if (response.data['success'] == true) {
    return (response.data['data'] as List)
        .map((s) => Stock.fromJson(s as Map<String, dynamic>))
        .toList();
  }
  return [];
});

/// Market overview provider.
final marketOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.getMarketOverview();
  if (response.data['success'] == true) {
    return response.data['data'] as Map<String, dynamic>;
  }
  return {};
});

/// Top gainers provider.
final topGainersProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.getTopGainers();
  if (response.data['success'] == true) {
    return response.data['data'] as List<dynamic>;
  }
  return [];
});

/// Top losers provider.
final topLosersProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.getTopLosers();
  if (response.data['success'] == true) {
    return response.data['data'] as List<dynamic>;
  }
  return [];
});

/// Volume ranking provider.
final volumeRankingProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final response = await api.getVolumeRanking();
  if (response.data['success'] == true) {
    return response.data['data'] as List<dynamic>;
  }
  return [];
});

/// Market index provider (KOSPI or KOSDAQ).
final marketIndexProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, code) async {
  final api = ref.read(apiClientProvider);
  final response = await api.getIndex(code: code);
  if (response.data['success'] == true) {
    return response.data['data'] as Map<String, dynamic>;
  }
  return {};
});

/// Stock chart history provider with period support.
final stockHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, (String, String)>((ref, params) async {
  final (symbol, period) = params;
  final api = ref.read(apiClientProvider);
  final response = await api.getHistory(symbol, period: period);
  if (response.data['success'] == true) {
    final raw = response.data['data'];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    }
  }
  return [];
});

/// Fake response for non-critical API calls that failed.
class _FakeResponse {
  dynamic get data => null;
}
