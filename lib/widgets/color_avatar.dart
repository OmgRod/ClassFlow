import 'package:flutter/material.dart';

/// A reusable circular or rounded avatar with colored background and text/icon
class ColorAvatar extends StatelessWidget {
  final Color color;
  final String? text;
  final IconData? icon;
  final double size;
  final double borderRadius;
  final double? borderWidth;
  final double fontSize;

  const ColorAvatar({
    required this.color,
    this.text,
    this.icon,
    this.size = 60,
    this.borderRadius = 12,
    this.borderWidth = 2,
    this.fontSize = 28,
    super.key,
  }) : assert(text != null || icon != null, 'Either text or icon must be provided');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth != null ? Border.all(color: color, width: borderWidth!) : null,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color, size: fontSize)
            : Text(
                text!,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
      ),
    );
  }
}
