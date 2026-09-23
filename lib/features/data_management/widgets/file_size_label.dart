import 'package:intl/intl.dart';

import '../../../core/l10n.dart';

const _kb = 1024;
const _mb = 1024 * 1024;

/// "214 KB" or "1.1 MB", with the locale's digits.
String fileSizeLabel(AppLocalizations l10n, int bytes) => bytes < _mb
    ? l10n.fileSizeKb(
        NumberFormat.decimalPattern(l10n.localeName)
            .format((bytes / _kb).ceil()),
      )
    : l10n.fileSizeMb(
        NumberFormat('#,##0.0', l10n.localeName).format(bytes / _mb),
      );
