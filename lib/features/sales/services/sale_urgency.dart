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

class SaleUrgency {
  SaleUrgency._();

  static UrgencyLevel levelOf(Sale sale, {DateTime? now}) {
    if (sale.scheduledDate == null) return UrgencyLevel.none;
    if (sale.shipment.status == ShipmentStatus.delivered) return UrgencyLevel.none;
    final today = _today(now);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfNextWeek = startOfThisWeek.add(const Duration(days: 7));
    if (sale.scheduledDate!.isBefore(startOfThisWeek)) return UrgencyLevel.overdue;
    if (sale.scheduledDate!.isBefore(startOfNextWeek)) return UrgencyLevel.thisWeek;
    return UrgencyLevel.none;
  }

  static List<UrgencyReason> reasonsFor(Sale sale, {DateTime? now}) {
    final level = levelOf(sale, now: now);
    if (level == UrgencyLevel.none) return const [];

    final reasons = <UrgencyReason>[];
    if (sale.assemblyStatus == AssemblyStatus.waitingForMaterials) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.waitingForMaterials,
        icon: Icons.shopping_bag_outlined,
        color: Colors.orange,
      ));
    } else if (sale.assemblyStatus != AssemblyStatus.ready) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.assemblyNotReady,
        icon: Icons.construction,
        color: Colors.orange,
      ));
    }
    if (sale.payment.status == PaymentStatus.unpaid) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.paymentPending,
        icon: Icons.credit_card_off,
        color: Colors.orange,
      ));
    }
    if (level == UrgencyLevel.overdue &&
        sale.shipment.status == ShipmentStatus.pending) {
      reasons.add(const UrgencyReason(
        type: UrgencyReasonType.notYetShipped,
        icon: Icons.schedule,
        color: Colors.red,
      ));
    }
    return reasons;
  }

  static int? daysUntilScheduled(Sale sale, {DateTime? now}) {
    if (sale.scheduledDate == null) return null;
    final today = _today(now);
    final scheduled = DateTime(
      sale.scheduledDate!.year,
      sale.scheduledDate!.month,
      sale.scheduledDate!.day,
    );
    return scheduled.difference(today).inDays;
  }

  static DateTime _today(DateTime? now) {
    final t = now ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }
}
