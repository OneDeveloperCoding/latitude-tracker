import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';

/// Shows a scrollable bottom sheet displaying [notes] as selectable text.
///
/// Uses isScrollControlled so long notes can scroll instead of overflowing
/// the sheet's default max height.
void showNotePreviewSheet(BuildContext context, String notes) {
  final s = context.s;
  unawaited(showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.9,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  s.sectionNotes,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              notes,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ),
  ));
}
