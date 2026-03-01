import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';

/// Shimmer loading skeleton that matches the design system.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Shimmer.fromColors(
      baseColor: appColors.surfaceHover,
      highlightColor: colorScheme.outline,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: appColors.surfaceHover,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer card skeleton for stock list items.
class ShimmerStockCard extends StatelessWidget {
  const ShimmerStockCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Shimmer.fromColors(
      baseColor: appColors.surfaceHover,
      highlightColor: colorScheme.outline,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appColors.surfaceHover,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: appColors.surfaceHover,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: appColors.surfaceHover,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 32,
              decoration: BoxDecoration(
                color: appColors.surfaceHover,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 70,
                  height: 14,
                  decoration: BoxDecoration(
                    color: appColors.surfaceHover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 50,
                  height: 12,
                  decoration: BoxDecoration(
                    color: appColors.surfaceHover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer list — repeated shimmer stock cards.
class ShimmerStockList extends StatelessWidget {
  const ShimmerStockList({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ShimmerStockCard(),
    );
  }
}

/// Shimmer horizontal card for market overview.
class ShimmerMarketCard extends StatelessWidget {
  const ShimmerMarketCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Shimmer.fromColors(
      baseColor: appColors.surfaceHover,
      highlightColor: colorScheme.outline,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appColors.surfaceHover,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: colorScheme.outline, shape: BoxShape.circle)),
            const SizedBox(height: 12),
            Container(width: 80, height: 14, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 4),
            Container(width: 50, height: 12, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Container(width: 100, height: 30, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(width: 60, height: 12, decoration: BoxDecoration(color: colorScheme.outline, borderRadius: BorderRadius.circular(4))),
          ],
        ),
      ),
    );
  }
}
