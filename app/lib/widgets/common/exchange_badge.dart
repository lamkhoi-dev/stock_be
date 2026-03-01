import 'package:flutter/material.dart';

/// Exchange badge pill — KOSPI or KOSDAQ.
class ExchangeBadge extends StatelessWidget {
  const ExchangeBadge({
    super.key,
    required this.exchange,
    this.small = false,
  });

  final String exchange;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final isKospi = exchange.toUpperCase().contains('KOSPI');
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 4 : 6,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: isKospi
            ? colorScheme.primary.withAlpha(30)
            : const Color(0xFF8B5CF6).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isKospi
              ? colorScheme.primary.withAlpha(60)
              : const Color(0xFF8B5CF6).withAlpha(60),
          width: 0.5,
        ),
      ),
      child: Text(
        exchange.toUpperCase(),
        style: TextStyle(
          fontSize: small ? 9 : 10,
          fontWeight: FontWeight.w600,
          color: isKospi ? colorScheme.primary : const Color(0xFF8B5CF6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
