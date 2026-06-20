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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < dots.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Icon(dots[i].icon, size: 16, color: dots[i].color),
          ],
        ],
      ),
    );
  }
}
