import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Mini sparkline chart — 5-day area chart used in stock lists and cards.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.data,
    this.width = 80,
    this.height = 32,
    this.lineWidth = 1.5,
    this.showArea = true,
  });

  /// Price data points (at least 2 required).
  final List<double> data;
  final double width;
  final double height;
  final double lineWidth;
  final bool showArea;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(width: width, height: height);
    }

    final appColors = Theme.of(context).extension<AppColors>()!;
    final isUp = data.last >= data.first;
    final color = isUp ? appColors.priceUp : appColors.priceDown;

    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: color,
              barWidth: lineWidth,
              dotData: const FlDotData(show: false),
              belowBarData: showArea
                  ? BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withAlpha(60),
                          color.withAlpha(5),
                        ],
                      ),
                    )
                  : BarAreaData(show: false),
            ),
          ],
        ),
        duration: Duration.zero,
      ),
    );
  }
}
