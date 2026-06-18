import 'package:latitude_tracker/features/sales/models/sale.dart';

enum UrgencyLevel { overdue, thisWeek, none }

enum UrgencyReasonType {
  waitingForMaterials,
  assemblyNotReady,
  paymentPending,
  notYetShipped,
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

  List<UrgencyReasonType> urgencyReasons({DateTime? now, UrgencyLevel? level}) {
    final resolvedLevel = level ?? urgencyLevel(now: now);
    if (resolvedLevel == UrgencyLevel.none) return const [];

    final reasons = <UrgencyReasonType>[];
    final assembly = derivedAssemblyStatus;
    if (assembly == AssemblyStatus.waitingForMaterials) {
      reasons.add(UrgencyReasonType.waitingForMaterials);
    } else if (assembly != AssemblyStatus.ready) {
      reasons.add(UrgencyReasonType.assemblyNotReady);
    }
    if (payment.status == PaymentStatus.unpaid) {
      reasons.add(UrgencyReasonType.paymentPending);
    }
    if (resolvedLevel == UrgencyLevel.overdue &&
        shipment.status == ShipmentStatus.pending) {
      reasons.add(UrgencyReasonType.notYetShipped);
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

  int daysOpen({DateTime? now}) {
    final today = _today(now);
    final created = DateTime(createdAt.year, createdAt.month, createdAt.day);
    return today.difference(created).inDays;
  }
}

DateTime _today(DateTime? now) {
  final t = now ?? DateTime.now();
  return DateTime(t.year, t.month, t.day);
}
