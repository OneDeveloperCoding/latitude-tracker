import 'package:flutter/material.dart';

class StatusIndicatorDot {
  const StatusIndicatorDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

/// A colored circle with a tinted background — the shared atom for all status
/// indicators. [size] controls the circle diameter.
class StatusBubble extends StatelessWidget {
  const StatusBubble({
    required this.icon,
    required this.color,
    this.size = 24,
    this.iconSize = 13,
    super.key,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(40),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// A vertical column of color-coded icon bubbles, one per domain area.
/// Sits on the left edge of SaleCard and RepairCard.
/// spaceEvenly distributes equal space above the first bubble, between
/// bubbles, and below the last — matching whatever card height the content
/// determines.
class StatusIndicatorStrip extends StatelessWidget {
  const StatusIndicatorStrip({required this.dots, super.key});

  final List<StatusIndicatorDot> dots;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dots
          .map((d) => StatusBubble(icon: d.icon, color: d.color))
          .toList(),
    );
  }
}
