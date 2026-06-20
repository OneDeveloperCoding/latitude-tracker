import 'package:flutter/material.dart';

class StatusIndicatorDot {
  const StatusIndicatorDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

/// A colored circle with a white icon — the shared atom for all status
/// indicators. [size] controls the circle diameter.
class StatusBubble extends StatelessWidget {
  const StatusBubble({
    required this.icon,
    required this.color,
    this.size = 28,
    this.iconSize = 15,
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}

/// A vertical column of color-coded icon bubbles, one per domain area.
/// Sits on the left edge of SaleCard and RepairCard.
/// Each bubble is an Expanded child so the three icons spread evenly over
/// the full card height, anchoring each to its corresponding content row.
class StatusIndicatorStrip extends StatelessWidget {
  const StatusIndicatorStrip({required this.dots, super.key});

  final List<StatusIndicatorDot> dots;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dots
          .map(
            (d) => Expanded(
              child: Center(child: StatusBubble(icon: d.icon, color: d.color)),
            ),
          )
          .toList(),
    );
  }
}
