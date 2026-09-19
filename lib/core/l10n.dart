import 'package:flutter/widgets.dart';
import 'package:open_sky_finance/l10n/generated/app_localizations.dart';

export 'package:open_sky_finance/l10n/generated/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String get localeName => l10n.localeName;
}

/// Language names in their own language, never translated.
const languageEndonyms = {'en': 'English', 'es': 'Español', 'fr': 'Français'};
