import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../widgets/common/company_icon.dart';
import '../../../widgets/common/exchange_badge.dart';
import '../../../widgets/common/sparkline_chart.dart';
import '../../../widgets/common/price_text.dart';
import '../../../widgets/common/shimmer_loading.dart';

/// Watchlist preview section — shows first 5 watched stocks.
class WatchlistPreviewWidget extends StatelessWidget {
  const WatchlistPreviewWidget({
    super.key,
    required this.items,
    this.isLoading = false,
    this.isLoggedIn = false,
  });

  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, size: 18, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'Watchlist',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to watchlist tab (index 2)
                  final shell = StatefulNavigationShell.maybeOf(context);
                  if (shell != null) {
                    shell.goBranch(2);
                  }
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Content
        if (!isLoggedIn)
          _buildLoginPrompt(context)
        else if (isLoading)
          const ShimmerStockList(itemCount: 3)
        else if (items.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length > 5 ? 5 : items.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 72,
              color: appColors.surfaceHover,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _WatchlistItem(
                symbol: item['symbol'] as String? ?? '',
                nameKo: item['nameKo'] as String? ?? '',
                nameEn: item['nameEn'] as String? ?? '',
                exchange: item['exchange'] as String? ?? 'KOSPI',
                price: (item['price'] as num?)?.toDouble() ?? 0,
                change: (item['change'] as num?)?.toDouble() ?? 0,
                changePercent: (item['changePercent'] as num?)?.toDouble() ?? 0,
                sparkline: item['sparkline'] as List<double>?,
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.star_outline, size: 32, color: colorScheme.onSurface.withValues(alpha: 0.38)),
          const SizedBox(height: 12),
          Text(
            'Login to track your favorite stocks',
            style: TextStyle(color: colorScheme.secondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/auth/login'),
              child: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          children: [
            Icon(Icons.star_outline, size: 32, color: colorScheme.onSurface.withValues(alpha: 0.38)),
            const SizedBox(height: 8),
            Text(
              'Add stocks to your watchlist',
              style: TextStyle(color: colorScheme.secondary, fontSize: 13),
            ),
          ],
        ),
      );
    });
  }
}

class _WatchlistItem extends StatelessWidget {
  const _WatchlistItem({
    required this.symbol,
    required this.nameKo,
    required this.nameEn,
    required this.exchange,
    required this.price,
    required this.change,
    required this.changePercent,
    this.sparkline,
  });

  final String symbol;
  final String nameKo;
  final String nameEn;
  final String exchange;
  final double price;
  final double change;
  final double changePercent;
  final List<double>? sparkline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push('/stock/$symbol'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CompanyIcon(name: nameKo.isNotEmpty ? nameKo : nameEn, size: 40, fontSize: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameKo.isNotEmpty ? nameKo : nameEn,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      ExchangeBadge(exchange: exchange, small: true),
                      const SizedBox(width: 4),
                      Text(symbol, style: TextStyle(fontSize: 11, color: colorScheme.secondary)),
                    ],
                  ),
                ],
              ),
            ),
            if (sparkline != null && sparkline!.length >= 2) ...[
              SparklineChart(data: sparkline!, width: 50, height: 24),
              const SizedBox(width: 10),
            ],
            PriceText(
              price: price,
              change: change,
              changePercent: changePercent,
              priceFontSize: 14,
              changeFontSize: 11,
            ),
          ],
        ),
      ),
    );
  }
}
