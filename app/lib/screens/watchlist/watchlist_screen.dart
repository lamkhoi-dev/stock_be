import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/watchlist_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/watchlist_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/company_icon.dart';
import '../../widgets/common/exchange_badge.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/error_retry_widget.dart';
import '../../widgets/common/shimmer_loading.dart';

/// Watchlist screen — user's saved stocks with swipe-to-delete + sort.
class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  String _sortBy = 'added'; // added, name, change
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // Load watchlist if authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAuth = ref.read(authProvider).isAuthenticated;
      if (isAuth) {
        _loadWithRetry();
      }
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  /// Load watchlist with auto-retry on failure (handles backend cold start)
  Future<void> _loadWithRetry() async {
    await ref.read(watchlistProvider.notifier).loadWatchlist();
    // If failed and retries left, schedule another attempt
    final state = ref.read(watchlistProvider);
    if (state.error != null && _retryCount < 4 && mounted) {
      _retryTimer?.cancel();
      _retryCount++;
      _retryTimer = Timer(Duration(seconds: 5 * _retryCount), () {
        if (mounted && ref.read(authProvider).isAuthenticated) {
          _loadWithRetry();
        }
      });
    }
  }

  List<WatchlistItem> _sortedItems(List<WatchlistItem> items) {
    final sorted = List<WatchlistItem>.from(items);
    switch (_sortBy) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case 'change':
        sorted.sort((a, b) => (b.changePercent ?? 0).compareTo(a.changePercent ?? 0));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final watchState = ref.watch(watchlistProvider);
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          // Sort button
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            icon: const Icon(Icons.sort, size: 22),
            itemBuilder: (_) => [
              _menuItem('added', 'Date Added', _sortBy == 'added'),
              _menuItem('name', 'Name', _sortBy == 'name'),
              _menuItem('change', 'Change %', _sortBy == 'change'),
            ],
          ),
        ],
      ),
      body: !authState.isAuthenticated
          ? _buildLoginPrompt()
          : watchState.isLoading
              ? const ShimmerStockList(itemCount: 5)
              : watchState.error != null
                  ? ErrorRetryWidget(
                      message: 'Failed to load watchlist',
                      onRetry: () => ref.read(watchlistProvider.notifier).loadWatchlist(),
                    )
                  : watchState.items.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.star_outline,
                          message: 'Your watchlist is empty',
                          subtitle: 'Add stocks from search or stock detail page',
                        )
                      : _buildWatchlist(appColors, watchState.items),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool active) {
    final colorScheme = Theme.of(context).colorScheme;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (active)
            Icon(Icons.check, size: 16, color: colorScheme.primary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_outline, size: 48, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign in to manage\nyour watchlist',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your favorite stocks and get real-time updates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: colorScheme.secondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/auth/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchlist(AppColors appColors, List<WatchlistItem> rawItems) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = _sortedItems(rawItems);
    return RefreshIndicator(
      onRefresh: () => ref.read(watchlistProvider.notifier).loadWatchlist(),
      color: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: appColors.surfaceHover),
        itemBuilder: (context, index) {
          final item = items[index];
          final change = item.change ?? 0;
          final changePct = item.changePercent ?? 0;
          final isUp = change >= 0;

          return Dismissible(
            key: Key(item.symbol),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: const Color(0xFFEF4444),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              HapticFeedback.mediumImpact();
              final result = await ref.read(watchlistProvider.notifier).removeStock(item.symbol);
              if (!result && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to remove from watchlist'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
              return result;
            },
            onDismissed: (direction) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.name} removed from watchlist'),
                  backgroundColor: appColors.surfaceHover,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: colorScheme.primary,
                    onPressed: () {
                      ref.read(watchlistProvider.notifier).addStock(item.symbol);
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              onTap: () => context.push('/stock/${item.symbol}'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CompanyIcon(name: item.name, size: 44, fontSize: 18),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.exchange != null && item.exchange!.isNotEmpty)
                              ExchangeBadge(exchange: item.exchange!, small: true),
                            if (item.exchange != null && item.exchange!.isNotEmpty)
                              const SizedBox(width: 6),
                            Text(
                              item.symbol,
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.38)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.currentPrice != null
                            ? formatKRW(item.currentPrice!)
                            : '--',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isUp ? appColors.priceUp : appColors.priceDown).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isUp ? appColors.priceUp : appColors.priceDown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
