import 'package:flutter/material.dart';
import '../../utils/helpers.dart';

/// Company icon — colored circle with first letter of company name.
class CompanyIcon extends StatelessWidget {
  const CompanyIcon({
    super.key,
    required this.name,
    this.size = 44,
    this.fontSize = 18,
  });

  final String name;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = companyColor(name);
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
