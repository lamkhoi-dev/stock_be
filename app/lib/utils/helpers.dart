import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Get price color based on change direction.
Color priceColor(BuildContext context, double change) {
  final appColors = Theme.of(context).extension<AppColors>()!;
  if (change > 0) return appColors.priceUp;
  if (change < 0) return appColors.priceDown;
  return appColors.priceNeutral;
}

/// Get price arrow icon.
IconData priceIcon(double change) {
  if (change > 0) return Icons.arrow_drop_up;
  if (change < 0) return Icons.arrow_drop_down;
  return Icons.remove;
}

/// Company icon color based on first character hash.
Color companyColor(String name) {
  final colors = [
    const Color(0xFF3B82F6), // blue
    const Color(0xFFEF4444), // red
    const Color(0xFF22C55E), // green
    const Color(0xFFF59E0B), // amber
    const Color(0xFF8B5CF6), // purple
    const Color(0xFFEC4899), // pink
    const Color(0xFF06B6D4), // cyan
    const Color(0xFFF97316), // orange
  ];
  final hash = name.codeUnitAt(0) % colors.length;
  return colors[hash];
}

/// Email validation.
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email is required';
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
  if (!emailRegex.hasMatch(value)) return 'Invalid email format';
  return null;
}

/// Password validation.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < 8) return 'Password must be at least 8 characters';
  return null;
}

/// Name validation.
String? validateName(String? value) {
  if (value == null || value.isEmpty) return 'Name is required';
  if (value.length < 2) return 'Name must be at least 2 characters';
  return null;
}
