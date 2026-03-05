import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stock_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../providers/websocket_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/exchange_badge.dart';
import '../../widgets/common/error_retry_widget.dart';
import 'widgets/chart_tab.dart';
import 'widgets/info_tab.dart';
import 'widgets/ai_analysis_tab.dart';


/// Stock Detail Screen — Header with price + 3 tabs (Chart, Info, AI).
class StockDetailScreen extends ConsumerStatefulWidget {
  const StockDetailScreen({super.key, required this.symbol});
  final String symbol;

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Rebuild when tab changes so we can toggle swipe physics
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    // Subscribe to real-time WebSocket updates for this symbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear previous AI analysis results when entering a new stock
      ref.read(aiProvider.notifier).clear();
      final ws = ref.read(websocketProvider.notifier);
      final wsState = ref.read(websocketProvider);
      if (wsState.status == WSStatus.connected) {
        ws.subscribe(widget.symbol);
      }
    });
  }

  @override
  void dispose() {
    // Unsubscribe from WebSocket when leaving this screen
    ref.read(websocketProvider.notifier).unsubscribe(widget.symbol);
    _tabController.dispose();
    super.dispose();
  }

  /// Build a data map from StockState for child widgets (chart_tab, info_tab).
  Map<String, dynamic> _buildStockData(StockState state) {
    final q = state.quote;
    if (q == null) return {'symbol': widget.symbol};

    // Start from raw backend price data (contains ALL fields)
    final raw = state.rawPrice ?? {};

    // Check for real-time WebSocket update
    final wsState = ref.watch(websocketProvider);
    final wsPrice = wsState.lastPrices[widget.symbol];

    // Use WS price if available and fresher, else use API quote
    final price = (wsPrice?['price'] as num?)?.toDouble() ?? q.currentPrice;
    final change = (wsPrice?['change'] as num?)?.toDouble() ?? q.change;
    final changePct = (wsPrice?['changePct'] as num?)?.toDouble() ?? q.changePercent;
    final volume = (wsPrice?['volume'] as num?)?.toDouble() ?? q.volume;
    final high = (wsPrice?['high'] as num?)?.toDouble() ?? q.high;
    final low = (wsPrice?['low'] as num?)?.toDouble() ?? q.low;
    final open = (wsPrice?['open'] as num?)?.toDouble() ?? q.open;

    return {
      'symbol': q.symbol,
      'nameKo': raw['name'] as String? ?? '',
      'nameEn': raw['englishName'] as String? ?? '',
      'exchange': raw['exchange'] as String? ?? q.marketStatus ?? 'KOSPI',
      'price': price,
      'change': change,
      'changePercent': changePct,
      'previousClose': q.previousClose,
      'open': open,
      'high': high,
      'low': low,
      'volume': volume,
      'value': q.value != 0 ? q.value : (raw['tradingValue'] as num?)?.toDouble() ?? 0,
      // Extra fields from the backend
      'marketCap': (raw['marketCap'] as num?)?.toDouble() ?? 0.0,
      'per': (raw['per'] as num?)?.toDouble() ?? 0.0,
      'pbr': (raw['pbr'] as num?)?.toDouble() ?? 0.0,
      'eps': (raw['eps'] as num?)?.toDouble() ?? 0.0,
      'dividendYield': (raw['dividendYield'] as num?)?.toDouble() ?? 0.0,
      'high52w': (raw['high52w'] as num?)?.toDouble() ?? q.high,
      'low52w': (raw['low52w'] as num?)?.toDouble() ?? q.low,
      'upperLimit': (raw['upperLimit'] as num?)?.toDouble(),
      'lowerLimit': (raw['lowerLimit'] as num?)?.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Watch the stock provider for this symbol — autoloads on first access
    final stockState = ref.watch(stockProvider(widget.symbol));
    final watchlistState = ref.watch(watchlistProvider);
    final isWatched =
        watchlistState.items.any((w) => w.symbol == widget.symbol);
    final appColors = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    if (stockState.isLoading && stockState.quote == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.symbol),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    if (stockState.error != null && stockState.quote == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.symbol),
        ),
        body: Center(
          child: ErrorRetryWidget(
            message: S.of(context).failedLoadStock,
            onRetry: () =>
                ref.read(stockProvider(widget.symbol).notifier).loadStock(widget.symbol),
          ),
        ),
      );
    }

    final stockData = _buildStockData(stockState);

    // Enrich with indicator data if available
    if (stockState.indicators != null) {
      stockData['overallSignal'] = stockState.indicators!.overallSignal;
      stockData['technicalScore'] = stockState.indicators!.score;
    }

    // Enrich with KIS price data (high52w, low52w, per, pbr, eps, etc.)
    // These fields come from getPrice API as part of the quote
    // The backend enriches the response

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(stockData, isWatched, appColors),
        ],
        body: TabBarView(
          controller: _tabController,
          // Disable swiping on Chart tab so chart pan/zoom gestures work
          physics: _tabController.index == 0
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          children: [
            ChartTab(symbol: widget.symbol, stockData: stockData),
            InfoTab(stockData: stockData),
            AiAnalysisTab(symbol: widget.symbol, stockData: stockData),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    Map<String, dynamic> stockData,
    bool isWatched,
    AppColors appColors,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final price = (stockData['price'] as num?)?.toDouble() ?? 0;
    final change = (stockData['change'] as num?)?.toDouble() ?? 0;
    final changePct = (stockData['changePercent'] as num?)?.toDouble() ?? 0;
    final isUp = change >= 0;

    final nameKo = (stockData['nameKo'] as String?) ?? '';
    final nameEn = (stockData['nameEn'] as String?) ?? '';
    final displayName = nameKo.isNotEmpty
        ? nameKo
        : nameEn.isNotEmpty
            ? nameEn
            : widget.symbol;
    final exchange = (stockData['exchange'] as String?) ?? 'KOSPI';
    final priceColor = isUp ? appColors.priceUp : appColors.priceDown;

    // kToolbarHeight ≈ 56, TabBar height ≈ 46, status bar varies
    const double expandedHeight = 270;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: expandedHeight,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => context.pop(),
      ),
      // Compact title shown when collapsed
      title: null, // We handle this in flexibleSpace
      actions: [
        IconButton(
          icon: Icon(
            isWatched ? Icons.star : Icons.star_outline,
            color: isWatched ? const Color(0xFFF59E0B) : null,
          ),
          onPressed: () {
            final auth = ref.read(authProvider);
            if (!auth.isAuthenticated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).loginForWatchlist),
                  backgroundColor: colorScheme.surface,
                ),
              );
              return;
            }
            HapticFeedback.lightImpact();
            final notifier = ref.read(watchlistProvider.notifier);
            if (isWatched) {
              notifier.removeStock(widget.symbol);
            } else {
              notifier.addStock(widget.symbol);
            }
          },
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final statusBarHeight = MediaQuery.of(context).padding.top;
          final minHeight = statusBarHeight + kToolbarHeight + 46; // toolbar + tabBar
          final maxHeight = expandedHeight + statusBarHeight;
          final currentHeight = constraints.maxHeight;
          // 1.0 = fully expanded, 0.0 = fully collapsed
          final expandRatio = ((currentHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
          final isCollapsed = expandRatio < 0.3;

          return FlexibleSpaceBar(
            background: Stack(
              children: [
                // Expanded header content with opacity fade
                Opacity(
                  opacity: expandRatio,
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 90, bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stock name
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (nameEn.isNotEmpty && nameKo.isNotEmpty)
                              Flexible(
                                child: Text(
                                  nameEn,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.secondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (nameEn.isNotEmpty && nameKo.isNotEmpty)
                              const SizedBox(width: 8),
                            ExchangeBadge(exchange: exchange, small: true),
                            const SizedBox(width: 6),
                            Text(widget.symbol,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.38))),
                            const SizedBox(width: 6),
                            Text('KRW 🇰🇷',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.38))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Price
                        Text(
                          formatKRW(price),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Change
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priceColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isUp ? "▲" : "▼"} ${formatKRW(change.abs())} (${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: priceColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Collapsed compact title — shows name + price in the toolbar area
                Positioned(
                  left: 48,
                  right: 48,
                  top: statusBarHeight + 12,
                  child: Opacity(
                    opacity: (1.0 - expandRatio).clamp(0.0, 1.0),
                    child: isCollapsed
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Text(
                                    formatKRW(price),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: priceColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(46),
        child: Container(
          color: colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 2.5,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.secondary,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: S.of(context).tabChart),
              Tab(text: S.of(context).tabInfo),
              Tab(
                  child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(S.of(context).tabAI),
                  const SizedBox(width: 4),
                  const Text('✨', style: TextStyle(fontSize: 12)),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}
