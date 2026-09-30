import 'package:flutter/widgets.dart';

/// Whether the text scale is above 150 %, where side-by-side layouts no
/// longer fit a phone.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(10) > 15;
