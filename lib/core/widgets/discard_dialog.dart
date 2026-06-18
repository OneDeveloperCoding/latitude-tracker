import 'package:flutter/material.dart';

import 'package:latitude_tracker/core/l10n/app_strings.dart';

/// Shows a "Discard changes?" confirmation dialog.
/// Returns true if the user chose to discard, false or null otherwise.
Future<bool> showDiscardDialog(BuildContext context) async {
  final s = context.s;
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(s.discardChanges),
          content: Text(s.discardChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.discard),
            ),
          ],
        ),
      ) ==
      true;
}
