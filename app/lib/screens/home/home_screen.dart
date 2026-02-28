import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../services/api_client.dart';
import '../../utils/formatters.dart';
import 'widgets/market_status_widget.dart';
import 'widgets/market_overview_widget.dart';
import 'widgets/watchlist_preview_widget.dart';
import 'widgets/top_movers_widget.dart';
import 'widgets/latest_news_widget.dart';

/// Home screen — main dashboard with 5 sections.
/// Market Status | Market Overview | Watchlist Preview | Top Movers | Latest News
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Per-section loading states — each section loads independently
  bool _isLoadingMarket = true;
  bool _isLoadingIndices = true;
  bool _isLoadingMovers = true;
  bool _isLoadingNews = true;
  bool _isLoadingWatchlist = true;

  // Live data holders
  List<Map<String, dynamic>> _marketStocks = [];
  List<Map<String, dynamic>> _watchlistItems = [];
  List<Map<String, dynamic>> _gainers = [];
  List<Map<String, dynamic>> _losers = [];
  List<Map<String, dynamic>> _news = [];
  double? _kospiValue;
  double? _kospiChange;
  double? _kosdaqValue;
  double? _kosdaqChange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMarket = true;
      _isLoadingIndices = true;
      _isLoadingMovers = true;
      _isLoadingNews = true;
      _isLoadingWatchlist = true;
    });

    final api = ref.read(apiClientProvider);

    // Fire all fetches in parallel — each one calls setState independently
    _fetchIndices(api);
    _fetchTopMovers(api);
    _fetchNews(api);
    _fetchWatchlist(api);
    // Market overview last (slowest — batch KIS calls)
    _fetchMarketOverview(api);
  }

  Future<void> _fetchMarketOverview(ApiClient api) async {
    try {
      final response = await api.getMarketOverview();
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List<Map<String, dynamic>> parsed = [];
        final rawList = (data is Map && data['stocks'] is List)
            ? data['stocks'] as List
            : (data is List ? data : null);
        if (rawList != null) {
          parsed = rawList.map((s) {
            final item = s as Map<String, dynamic>;
            return <String, dynamic>{
              'symbol': item['symbol'] ?? '',
              'nameKo': item['name'] ?? item['nameKo'] ?? '',
              'nameEn': item['nameEn'] ?? item['name'] ?? '',
              'exchange': item['exchange'] ?? 'KOSPI',
              'price': (item['price'] as num?)?.toDouble() ?? 0.0,
              'change': (item['change'] as num?)?.toDouble() ?? 0.0,
              'changePercent': (item['changePct'] as num?)?.toDouble() ??
                  (item['changePercent'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();
        }
        if (mounted) {
          setState(() {
            _marketStocks = parsed;
            _isLoadingMarket = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMarket = false);
  }

  Future<void> _fetchIndices(ApiClient api) async {
    try {
      final kospiRes =
          await api.getIndex(code: '0001'); // KOSPI
      if (kospiRes.data['success'] == true) {
        final d = kospiRes.data['data'] as Map<String, dynamic>?;
        if (d != null) {
          _kospiValue = (d['value'] as num?)?.toDouble() ??
              (d['price'] as num?)?.toDouble();
          _kospiChange = (d['changePct'] as num?)?.toDouble() ??
              (d['changePercent'] as num?)?.toDouble();
        }
      }
    } catch (_) {}

    try {
      final kosdaqRes =
          await api.getIndex(code: '1001'); // KOSDAQ
      if (kosdaqRes.data['success'] == true) {
        final d = kosdaqRes.data['data'] as Map<String, dynamic>?;
        if (d != null) {
          _kosdaqValue = (d['value'] as num?)?.toDouble() ??
              (d['price'] as num?)?.toDouble();
          _kosdaqChange = (d['changePct'] as num?)?.toDouble() ??
              (d['changePercent'] as num?)?.toDouble();
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingIndices = false);
  }

  Future<void> _fetchTopMovers(ApiClient api) async {
    try {
      final gainersRes = await api.getTopGainers();
      if (gainersRes.data['success'] == true) {
        final data = gainersRes.data['data'];
        if (data is List) {
          _gainers = data.take(10).map((s) {
            final item = s as Map<String, dynamic>;
            return <String, dynamic>{
              'symbol': item['symbol'] ?? item['code'] ?? '',
              'name': item['name'] ?? item['hts_kor_isnm'] ?? '',
              'price': (item['price'] as num?)?.toDouble() ??
                  (item['stck_prpr'] as num?)?.toDouble() ?? 0.0,
              'change': (item['change'] as num?)?.toDouble() ??
                  (item['prdy_vrss'] as num?)?.toDouble() ?? 0.0,
              'changePercent': (item['changePct'] as num?)?.toDouble() ??
                  (item['prdy_ctrt'] as num?)?.toDouble() ??
                  (item['changePercent'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();
        }
      }
    } catch (_) {}

    try {
      final losersRes = await api.getTopLosers();
      if (losersRes.data['success'] == true) {
        final data = losersRes.data['data'];
        if (data is List) {
          _losers = data.take(10).map((s) {
            final item = s as Map<String, dynamic>;
            return <String, dynamic>{
              'symbol': item['symbol'] ?? item['code'] ?? '',
              'name': item['name'] ?? item['hts_kor_isnm'] ?? '',
              'price': (item['price'] as num?)?.toDouble() ??
                  (item['stck_prpr'] as num?)?.toDouble() ?? 0.0,
              'change': (item['change'] as num?)?.toDouble() ??
                  (item['prdy_vrss'] as num?)?.toDouble() ?? 0.0,
              'changePercent': (item['changePct'] as num?)?.toDouble() ??
                  (item['prdy_ctrt'] as num?)?.toDouble() ??
                  (item['changePercent'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoadingMovers = false);
  }

  Future<void> _fetchNews(ApiClient api) async {
    try {
      // Fetch news for Samsung (005930) as general market news
      final response = await api.getStockNews('005930');
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          _news = data.take(5).map((n) {
            final item = n as Map<String, dynamic>;
            final publishedAt = item['publishedAt'] != null
                ? DateTime.tryParse(item['publishedAt'].toString())
                : null;
            return <String, dynamic>{
              'title': item['title'] ?? '',
              'source': item['source'] ?? item['publisher'] ?? '',
              'timeAgo': publishedAt != null ? timeAgo(publishedAt) : '',
              'url': item['url'] ?? item['link'],
              'thumbnailUrl': item['thumbnailUrl'] ?? item['thumbnail'],
            };
          }).toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingNews = false);
  }

  Future<void> _fetchWatchlist(ApiClient api) async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (mounted) setState(() => _isLoadingWatchlist = false);
      return;
    }
    try {
      final response = await api.getWatchlist(withPrices: true);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        List items;
        if (data is Map && data['items'] is List) {
          items = data['items'] as List;
        } else if (data is List) {
          items = data;
        } else {
          if (mounted) setState(() => _isLoadingWatchlist = false);
          return;
        }
        _watchlistItems = items.take(5).map((w) {
          final item = w as Map<String, dynamic>;
          return <String, dynamic>{
            'symbol': item['symbol'] ?? '',
            'nameKo': item['nameKo'] ?? item['name'] ?? '',
            'nameEn': item['nameEn'] ?? item['name'] ?? '',
            'exchange': item['market'] ?? item['exchange'] ?? 'KOSPI',
            'price': (item['currentPrice'] as num?)?.toDouble() ?? 0.0,
            'change': (item['change'] as num?)?.toDouble() ?? 0.0,
            'changePercent': (item['changePct'] as num?)?.toDouble() ??
                (item['changePercent'] as num?)?.toDouble() ?? 0.0,
          };
        }).toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingWatchlist = false);
  }

  Future<void> _handleRefresh() async {
    final api = ref.read(apiClientProvider);
    // Fire all independently and wait for the fast ones
    await Future.wait([
      _fetchIndices(api),
      _fetchTopMovers(api),
      _fetchNews(api),
      _fetchWatchlist(api),
    ]);
    // Market overview in background (slow)
    _fetchMarketOverview(api);
    // Invalidate cached providers to get fresh data
    ref.invalidate(marketOverviewProvider);
    ref.invalidate(topGainersProvider);
    ref.invalidate(topLosersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'K',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'KRX Analysis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            onPressed: () {
              final shell = StatefulNavigationShell.maybeOf(context);
              if (shell != null) shell.goBranch(1);
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {/* Phase 7 — Notifications */},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF3B82F6),
        backgroundColor: const Color(0xFF141620),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Section A: Market Status
              MarketStatusWidget(
                kospiValue: _isLoadingIndices ? null : _kospiValue,
                kospiChange: _isLoadingIndices ? null : _kospiChange,
                kosdaqValue: _isLoadingIndices ? null : _kosdaqValue,
                kosdaqChange: _isLoadingIndices ? null : _kosdaqChange,
              ),
              const SizedBox(height: 24),
              // Section B: Market Overview (horizontal scroll)
              MarketOverviewWidget(
                stocks: _marketStocks,
                isLoading: _isLoadingMarket,
              ),
              const SizedBox(height: 24),
              // Section C: Watchlist Preview
              WatchlistPreviewWidget(
                items: _isLoadingWatchlist ? [] : _watchlistItems,
                isLoading: _isLoadingWatchlist,
                isLoggedIn: authState.isAuthenticated,
              ),
              const SizedBox(height: 24),
              // Section D: Top Movers
              TopMoversWidget(
                gainers: _gainers,
                losers: _losers,
                isLoading: _isLoadingMovers,
              ),
              const SizedBox(height: 24),
              // Section E: Latest News
              LatestNewsWidget(
                news: _news,
                isLoading: _isLoadingNews,
              ),
              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}
