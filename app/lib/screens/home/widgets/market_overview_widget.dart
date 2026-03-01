import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/common/stock_card.dart';
import '../../../widgets/common/shimmer_loading.dart';

/// Market overview section — horizontal scrolling popular stock cards.
class MarketOverviewWidget extends StatelessWidget {
  const MarketOverviewWidget({
    super.key,
    required this.stocks,
    this.isLoading = false,
  });

  final List<Map<String, dynamic>> stocks;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Stocks',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/stocks'),
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
        const SizedBox(height: 12),
        // Horizontal scroll
        SizedBox(
          height: 170,
          child: isLoading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => const ShimmerMarketCard(),
                )
              : stocks.isEmpty
                  ? Center(
                      child: Text(
                        'No market data available',
                        style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38)),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: stocks.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final s = stocks[index];
                        return StockCardCompact(
                          symbol: s['symbol'] as String? ?? '',
                          nameKo: s['nameKo'] as String? ?? '',
                          nameEn: s['nameEn'] as String? ?? '',
                          exchange: s['exchange'] as String? ?? 'KOSPI',
                          price: (s['price'] as num?)?.toDouble() ?? 0,
                          change: (s['change'] as num?)?.toDouble() ?? 0,
                          changePercent: (s['changePercent'] as num?)?.toDouble() ?? 0,
                          sparklineData: s['sparkline'] as List<double>?,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
