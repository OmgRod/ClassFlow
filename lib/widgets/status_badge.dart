import 'package:flutter/material.dart';

/// A status badge widget with colored background and border
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool showDropdown;

  const StatusBadge({
    required this.label,
    required this.color,
    this.onTap,
    this.showDropdown = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showDropdown) const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: badge,
      );
    }

    return badge;
  }
}
