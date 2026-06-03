import 'package:flutter/material.dart';

import '../models/sale.dart';

enum UrgencyLevel { overdue, thisWeek, none }

enum UrgencyReasonType {
  waitingForMaterials,
  assemblyNotReady,
  paymentPending,
  notYetShipped,
}

class UrgencyReason {
  final UrgencyReasonType type;
  final IconData icon;
  final Color color;

  const UrgencyReason({
    required this.type,
    required this.icon,
    required this.color,
  });
}

extension SaleUrgency on Sale {
  UrgencyLevel urgencyLevel({DateTime? now}) {
    if (scheduledDate == null) return UrgencyLevel.none;
    if (shipment.status == ShipmentStatus.delivered) return UrgencyLevel.none;
    final today = _today(now);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    if (scheduledDate!.isBefore(startOfThisWeek)) return UrgencyLevel.overdue;
    if (scheduledDate!.isBefore(startOfNextWeek)) return UrgencyLevel.thisWeek;
    return UrgencyLevel.none;
  }

  List<UrgencyReason> urgencyReasons({DateTime? now}) {
    final level = urgencyLevel(now: now);
    if (level == UrgencyLevel.none) return const [];

    final reasons = <UrgencyReason>[];
    final assembly = derivedAssemblyStatus;
    if (assembly == AssemblyStatus.waitingForMaterials) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.waitingForMaterials,
        icon: Icons.shopping_bag_outlined,
        color: Colors.orange,
      ));
    } else if (assembly != AssemblyStatus.ready) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.assemblyNotReady,
        icon: Icons.construction,
        color: Colors.orange,
      ));
    }
    if (payment.status == PaymentStatus.unpaid) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.paymentPending,
        icon: Icons.credit_card_off,
        color: Colors.orange,
      ));
    }
    if (level == UrgencyLevel.overdue && shipment.status == ShipmentStatus.pending) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.notYetShipped,
        icon: Icons.schedule,
        color: Colors.red,
      ));
    }
    return reasons;
  }

  int? daysUntilScheduled({DateTime? now}) {
    if (scheduledDate == null) return null;
    final today = _today(now);
    final scheduled = DateTime(
      scheduledDate!.year,
      scheduledDate!.month,
      scheduledDate!.day,
    );
    return scheduled.difference(today).inDays;
  }
}

DateTime _today(DateTime? now) {
  final t = now ?? DateTime.now();
  return DateTime(t.year, t.month, t.day);
}
