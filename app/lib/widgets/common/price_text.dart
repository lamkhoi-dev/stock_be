import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../utils/formatters.dart';

/// Price text widget — displays price with color-coded change.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.price,
    required this.change,
    required this.changePercent,
    this.priceFontSize = 15,
    this.changeFontSize = 13,
    this.crossAxisAlignment = CrossAxisAlignment.end,
    this.showCurrency = true,
  });

  final double price;
  final double change;
  final double changePercent;
  final double priceFontSize;
  final double changeFontSize;
  final CrossAxisAlignment crossAxisAlignment;
  final bool showCurrency;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final changeColor = change > 0
        ? appColors.priceUp
        : change < 0
            ? appColors.priceDown
            : appColors.priceNeutral;
    final sign = change >= 0 ? '+' : '';
    final arrow = change > 0
        ? '▲'
        : change < 0
            ? '▼'
            : '';

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          showCurrency ? formatKRW(price) : formatNumber(price),
          style: TextStyle(
            fontSize: priceFontSize,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$arrow $sign${formatNumber(change)} ($sign${changePercent.toStringAsFixed(2)}%)',
          style: TextStyle(
            fontSize: changeFontSize,
            fontWeight: FontWeight.w500,
            color: changeColor,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

/// Price change badge — compact version with colored background.
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({
    super.key,
    required this.changePercent,
    this.fontSize = 12,
  });

  final double changePercent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    final isPositive = changePercent >= 0;
    final color = changePercent > 0
        ? appColors.priceUp
        : changePercent < 0
            ? appColors.priceDown
            : appColors.priceNeutral;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$sign${changePercent.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
