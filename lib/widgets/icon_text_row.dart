import 'package:flutter/material.dart';

/// A reusable row with icon and text, commonly used for detail displays
class IconTextRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final EdgeInsetsGeometry padding;
  final Color? iconColor;
  final TextStyle? textStyle;

  const IconTextRow({
    required this.icon,
    required this.text,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
    this.iconColor,
    this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textStyle ?? TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
