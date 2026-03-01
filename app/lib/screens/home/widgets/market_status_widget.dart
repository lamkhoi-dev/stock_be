import 'package:flutter/material.dart';
import 'dart:async';

/// Market status header — shows KST time, market open/closed status, KOSPI & KOSDAQ indices.
class MarketStatusWidget extends StatefulWidget {
  const MarketStatusWidget({
    super.key,
    this.kospiValue,
    this.kospiChange,
    this.kosdaqValue,
    this.kosdaqChange,
  });

  final double? kospiValue;
  final double? kospiChange;
  final double? kosdaqValue;
  final double? kosdaqChange;

  @override
  State<MarketStatusWidget> createState() => _MarketStatusWidgetState();
}

class _MarketStatusWidgetState extends State<MarketStatusWidget> {
  late Timer _timer;
  DateTime _kstTime = DateTime.now().toUtc().add(const Duration(hours: 9));

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _kstTime = DateTime.now().toUtc().add(const Duration(hours: 9));
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _isMarketOpen {
    final hour = _kstTime.hour;
    final minute = _kstTime.minute;
    final weekday = _kstTime.weekday;
    if (weekday > 5) return false; // Weekend
    final timeInMinutes = hour * 60 + minute;
    return timeInMinutes >= 540 && timeInMinutes <= 930; // 9:00 - 15:30
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr =
        'KST ${_kstTime.hour.toString().padLeft(2, '0')}:${_kstTime.minute.toString().padLeft(2, '0')}:${_kstTime.second.toString().padLeft(2, '0')}';
    final isOpen = _isMarketOpen;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surface.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          // Time + Status
          Row(
            children: [
              const Text('🇰🇷', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.secondary,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              _MarketStatusChip(isOpen: isOpen),
            ],
          ),
          const SizedBox(height: 16),
          // KOSPI + KOSDAQ
          Row(
            children: [
              Expanded(
                child: _IndexTile(
                  name: 'KOSPI',
                  value: widget.kospiValue ?? 2645.32,
                  change: widget.kospiChange ?? 0.45,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline,
              ),
              Expanded(
                child: _IndexTile(
                  name: 'KOSDAQ',
                  value: widget.kosdaqValue ?? 872.15,
                  change: widget.kosdaqChange ?? -0.12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketStatusChip extends StatelessWidget {
  const _MarketStatusChip({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOpen ? const Color(0xFF22C55E) : colorScheme.secondary).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOpen ? const Color(0xFF22C55E) : colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'OPEN' : 'CLOSED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOpen ? const Color(0xFF22C55E) : colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndexTile extends StatelessWidget {
  const _IndexTile({
    required this.name,
    required this.value,
    required this.change,
  });
  final String name;
  final double value;
  final double change;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUp = change >= 0;
    final color = isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
    final sign = isUp ? '+' : '';
    final arrow = isUp ? '▲' : '▼';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '$arrow $sign${change.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
