import 'package:intl/intl.dart';

/// Format Korean Won currency.
String formatKRW(double value) {
  final formatter = NumberFormat('#,###', 'en_US');
  return '₩${formatter.format(value.round())}';
}

/// Format number with commas.
String formatNumber(double value, {int decimals = 0}) {
  if (decimals == 0) {
    return NumberFormat('#,###', 'en_US').format(value.round());
  }
  return NumberFormat.decimalPatternDigits(
    locale: 'en_US',
    decimalDigits: decimals,
  ).format(value);
}

/// Format price change with sign and percentage.
String formatPriceChange(double change, double changePercent) {
  final sign = change >= 0 ? '+' : '';
  return '$sign${formatNumber(change)} ($sign${changePercent.toStringAsFixed(2)}%)';
}

/// Format large numbers (e.g. volume, market cap).
String formatCompact(double value) {
  if (value >= 1e12) {
    return '${(value / 1e12).toStringAsFixed(1)}T';
  } else if (value >= 1e8) {
    return '${(value / 1e8).toStringAsFixed(1)}억';
  } else if (value >= 1e4) {
    return '${(value / 1e4).toStringAsFixed(1)}만';
  }
  return formatNumber(value);
}

/// Format date for display.
String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

/// Format date and time for display.
String formatDateTime(DateTime date) {
  return DateFormat('yyyy-MM-dd HH:mm').format(date);
}

/// Format time only (KST).
String formatTime(DateTime date) {
  return DateFormat('HH:mm KST').format(date);
}

/// Get time ago string.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
  if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
  return 'just now';
}
