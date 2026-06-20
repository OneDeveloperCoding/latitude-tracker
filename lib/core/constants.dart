import 'package:flutter/material.dart';

// Tax ID (NIF) icon — used wherever a buyer's NIF is displayed or required.
const IconData kNifIcon = Icons.badge;

// AT submission icon — used for the fiscal receipt / AT filing flow.
const IconData kAtSubmissionIcon = Icons.receipt_long;

// Earliest date the app was in use — used as the lower bound for date pickers
// that capture past events (e.g. shipped-at timestamp).
final kShippedAtFirstDate = DateTime(2020);

// A shipment can be marked as shipped at most one day into the future, to
// allow recording a drop-off before the courier scans the parcel.
const kShippedAtMaxFutureOffset = Duration(days: 1);
