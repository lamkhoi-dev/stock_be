import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/formatters.dart';
import 'company_icon.dart';
import 'exchange_badge.dart';
import 'sparkline_chart.dart';
import 'price_text.dart';

/// Stock card — data-rich card used in lists and horizontal scrolls.
/// Shows: company icon, name (Korean+English), exchange badge, sparkline, price, change.
class StockCard extends StatelessWidget {
  const StockCard({
    super.key,
    required this.symbol,
    required this.nameKo,
    required this.nameEn,
    this.exchange = 'KOSPI',
    required this.price,
    required this.change,
    required this.changePercent,
    this.volume,
    this.sparklineData,
    this.onTap,
  });

  final String symbol;
  final String nameKo;
  final String nameEn;
  final String exchange;
  final double price;
  final double change;
  final double changePercent;
  final double? volume;
  final List<double>? sparklineData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ?? () => context.push('/stock/$symbol'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Company icon
            CompanyIcon(name: nameKo.isNotEmpty ? nameKo : nameEn),
            const SizedBox(width: 12),
            // Name + Exchange
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameKo.isNotEmpty ? nameKo : nameEn,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      ExchangeBadge(exchange: exchange, small: true),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          nameKo.isNotEmpty ? nameEn : symbol,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Sparkline
            if (sparklineData != null && sparklineData!.length >= 2) ...[
              const SizedBox(width: 8),
              SparklineChart(data: sparklineData!, width: 60, height: 28),
            ],
            const SizedBox(width: 12),
            // Price + Change
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

/// Compact stock card — for horizontal scroll (market overview).
class StockCardCompact extends StatelessWidget {
  const StockCardCompact({
    super.key,
    required this.symbol,
    required this.nameKo,
    required this.nameEn,
    this.exchange = 'KOSPI',
    required this.price,
    required this.change,
    required this.changePercent,
    this.sparklineData,
    this.onTap,
  });

  final String symbol;
  final String nameKo;
  final String nameEn;
  final String exchange;
  final double price;
  final double change;
  final double changePercent;
  final List<double>? sparklineData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap ?? () => context.push('/stock/$symbol'),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CompanyIcon(name: nameKo.isNotEmpty ? nameKo : nameEn, size: 36, fontSize: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameKo.isNotEmpty ? nameKo : nameEn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      ExchangeBadge(exchange: exchange, small: true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sparklineData != null && sparklineData!.length >= 2)
              SparklineChart(data: sparklineData!, width: 128, height: 32),
            if (sparklineData != null) const SizedBox(height: 8),
            Text(
              formatKRW(price),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            PriceChangeBadge(changePercent: changePercent, fontSize: 11),
          ],
        ),
      ),
    );
  }
}
