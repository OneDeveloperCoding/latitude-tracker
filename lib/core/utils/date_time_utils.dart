import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/constants.dart';

/// Shows a date-then-time picker sequence initialised to [initial] (or now if
/// null). Returns the combined [DateTime], or null if the user cancelled either
/// picker.
Future<DateTime?> pickShippedAt(
  BuildContext context, {
  DateTime? initial,
}) async {
  final from = initial ?? DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: from,
    firstDate: kShippedAtFirstDate,
    lastDate: DateTime.now().add(kShippedAtMaxFutureOffset),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(from),
  );
  if (time == null || !context.mounted) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
