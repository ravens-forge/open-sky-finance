import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n.dart';
import 'logging.dart';

Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.errorNoBrowser;
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception catch (e) {
    Log.error(e);
  }
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(failed)));
}
