import 'package:flutter/material.dart';

import 'picker_row.dart';
import 'picker_sheet.dart';

/// A picker sheet listing [options] with their labels; `null` when dismissed.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  required T selected,
}) => showPickerSheet<T>(
  context,
  (context) => PickerSheet(
    title: title,
    children: [
      for (final (value, label) in options)
        PickerRow(
          title: label,
          selected: value == selected,
          onTap: () => Navigator.pop(context, value),
        ),
    ],
  ),
);
