import 'package:flutter/material.dart';

/// A reusable row of action buttons with consistent spacing
class ActionButtonsRow extends StatelessWidget {
  final List<ActionButtonData> buttons;
  final MainAxisAlignment alignment;

  const ActionButtonsRow({
    required this.buttons,
    this.alignment = MainAxisAlignment.end,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          buttons[i].isPrimary
              ? ElevatedButton.icon(
                  onPressed: buttons[i].onPressed,
                  icon: Icon(buttons[i].icon),
                  label: Text(buttons[i].label),
                )
              : TextButton.icon(
                  onPressed: buttons[i].onPressed,
                  icon: Icon(buttons[i].icon),
                  label: Text(buttons[i].label),
                ),
        ],
      ],
    );
  }
}

class ActionButtonData {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const ActionButtonData({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}
