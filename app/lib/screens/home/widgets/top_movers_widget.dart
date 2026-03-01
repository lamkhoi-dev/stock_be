import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../widgets/common/company_icon.dart';
import '../../../widgets/common/price_text.dart';
import '../../../widgets/common/shimmer_loading.dart';

/// Top movers section — tabs for Top Gainers / Top Losers.
class TopMoversWidget extends StatefulWidget {
  const TopMoversWidget({
    super.key,
    required this.gainers,
    required this.losers,
    this.isLoading = false,
  });

  final List<Map<String, dynamic>> gainers;
  final List<Map<String, dynamic>> losers;
  final bool isLoading;

  @override
  State<TopMoversWidget> createState() => _TopMoversWidgetState();
}

class _TopMoversWidgetState extends State<TopMoversWidget> {
  int _selectedTab = 0; // 0 = Gainers, 1 = Losers

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    final currentList = _selectedTab == 0 ? widget.gainers : widget.losers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'Top Movers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Tab toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Row(
                  children: [
                    _TabPill(
                      label: 'Gainers',
                      isActive: _selectedTab == 0,
                      color: const Color(0xFF22C55E),
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                    _TabPill(
                      label: 'Losers',
                      isActive: _selectedTab == 1,
                      color: const Color(0xFFEF4444),
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // List
        if (widget.isLoading)
          const ShimmerStockList(itemCount: 5)
        else if (currentList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('No data available', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.38))),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentList.length > 5 ? 5 : currentList.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 56,
              color: appColors.surfaceHover,
            ),
            itemBuilder: (context, index) {
              final item = currentList[index];
              return _MoverItem(
                rank: index + 1,
                symbol: item['symbol'] as String? ?? '',
                name: item['name'] as String? ?? '',
                price: (item['price'] as num?)?.toDouble() ?? 0,
                change: (item['change'] as num?)?.toDouble() ?? 0,
                changePercent: (item['changePercent'] as num?)?.toDouble() ?? 0,
                isGainer: _selectedTab == 0,
              );
            },
          ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withAlpha(25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? color : colorScheme.onSurface.withValues(alpha: 0.38),
          ),
        ),
      ),
    );
  }
}

class _MoverItem extends StatelessWidget {
  const _MoverItem({
    required this.rank,
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.isGainer,
  });
  final int rank;
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final bool isGainer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isGainer ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return InkWell(
      onTap: () => context.push('/stock/$symbol'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3 ? color : colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            CompanyIcon(name: name, size: 36, fontSize: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    symbol,
                    style: TextStyle(fontSize: 11, color: colorScheme.secondary),
                  ),
                ],
              ),
            ),
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
