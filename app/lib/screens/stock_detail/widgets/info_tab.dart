import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';

/// Info tab — Price details grid + 52-week range + day range.
class InfoTab extends StatelessWidget {
  const InfoTab({super.key, required this.stockData});
  final Map<String, dynamic> stockData;

  /// Safely extract a double from stockData.
  double _d(String key) => (stockData[key] as num?)?.toDouble() ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price Details
          _buildSectionTitle('Price Details', colorScheme),
          const SizedBox(height: 10),
          _buildPriceGrid(colorScheme),
          const SizedBox(height: 20),

          // Day Range
          _buildSectionTitle('Day Range', colorScheme),
          const SizedBox(height: 10),
          _buildRangeBar(
            colorScheme: colorScheme,
            low: _d('low'),
            high: _d('high'),
            current: _d('price'),
          ),
          const SizedBox(height: 20),

          // 52 Week Range
          _buildSectionTitle('52-Week Range', colorScheme),
          const SizedBox(height: 10),
          _buildRangeBar(
            colorScheme: colorScheme,
            low: _d('low52w'),
            high: _d('high52w'),
            current: _d('price'),
          ),
          const SizedBox(height: 20),

          // Fundamentals
          _buildSectionTitle('Fundamentals', colorScheme),
          const SizedBox(height: 10),
          _buildFundamentalsGrid(colorScheme),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPriceGrid(ColorScheme colorScheme) {
    final items = [
      ('Open', formatKRW(_d('open'))),
      ('Previous Close', formatKRW(_d('previousClose'))),
      ('Day High', formatKRW(_d('high'))),
      ('Day Low', formatKRW(_d('low'))),
      ('Volume', formatCompact(_d('volume'))),
      ('Value', formatCompact(_d('value'))),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final (label, value) = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              top: entry.key == 0 ? 0 : 10,
              bottom: entry.key == items.length - 1 ? 0 : 10,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 13, color: colorScheme.secondary)),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangeBar({
    required ColorScheme colorScheme,
    required double low,
    required double high,
    required double current,
  }) {
    final range = high - low;
    final position = range > 0 ? ((current - low) / range).clamp(0.0, 1.0) : 0.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatKRW(low), style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              Text(formatKRW(current), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
              Text(formatKRW(high), style: const TextStyle(fontSize: 12, color: Color(0xFF22C55E))),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Track
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFF59E0B), Color(0xFF22C55E)],
                      ),
                    ),
                  ),
                  // Indicator
                  Positioned(
                    left: (constraints.maxWidth * position - 6).clamp(0, constraints.maxWidth - 12),
                    top: -3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onSurface,
                        border: Border.all(color: colorScheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFundamentalsGrid(ColorScheme colorScheme) {
    final marketCap = _d('marketCap');
    final per = _d('per');
    final pbr = _d('pbr');
    final eps = _d('eps');
    final divYield = _d('dividendYield');

    final items = [
      if (marketCap > 0) ('Market Cap', '${formatCompact(marketCap)}억'),
      if (per > 0) ('P/E Ratio', per.toStringAsFixed(2)),
      if (pbr > 0) ('P/B Ratio', pbr.toStringAsFixed(2)),
      if (eps != 0) ('EPS', formatKRW(eps)),
      if (divYield > 0) ('Div Yield', '${divYield.toStringAsFixed(2)}%'),
      ('52W High', formatKRW(_d('high52w'))),
      ('52W Low', formatKRW(_d('low52w'))),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Wrap(
        spacing: 0,
        runSpacing: 12,
        children: items.map((item) {
          final (label, value) = item;
          return SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.38))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
