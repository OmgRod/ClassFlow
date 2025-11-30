import 'package:flutter/material.dart';
import '../models/models.dart';

/// Widget displaying lesson status with icon and color
class LessonStatusIndicator extends StatelessWidget {
  final LessonStatus status;
  final bool showLabel;
  final double size;

  const LessonStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (status == LessonStatus.normal) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: size, color: status.color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                fontSize: size * 0.875,
                color: status.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
