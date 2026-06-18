import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/features/buyers/models/buyer_address.dart' show BuyerAddress;
import 'package:url_launcher/url_launcher.dart';

/// Launches [uri] in an external application.
/// Shows a SnackBar with [errorMessage] if the launch fails.
Future<void> launchExternalUrl(
  BuildContext context,
  Uri uri, {
  required String errorMessage,
}) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

/// Convenience wrapper for launching a [BuyerAddress]-derived Maps URI.
Future<void> launchMapsUrl(BuildContext context, Uri mapsUri) =>
    launchExternalUrl(context, mapsUri,
        errorMessage: context.s.couldNotOpenMaps);
