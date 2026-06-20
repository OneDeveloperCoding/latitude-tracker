import 'package:flutter/material.dart';

class StatusIndicatorDot {
  const StatusIndicatorDot({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

/// A vertical column of color-coded icon dots, one per domain area.
/// Sits on the left edge of SaleCard and RepairCard.
class StatusIndicatorStrip extends StatelessWidget {
  const StatusIndicatorStrip({required this.dots, super.key});

  final List<StatusIndicatorDot> dots;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dots
          .map(
            (d) => Icon(d.icon, size: 16, color: d.color),
          )
          .toList(),
    );
  }
}
