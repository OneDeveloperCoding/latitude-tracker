import 'package:flutter/material.dart';

class StatusIndicatorDot {
  const StatusIndicatorDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;
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
              child: Center(child: _StatusBubble(icon: d.icon, color: d.color)),
            ),
          )
          .toList(),
    );
  }
}

class _StatusBubble extends StatelessWidget {
  const _StatusBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
}
