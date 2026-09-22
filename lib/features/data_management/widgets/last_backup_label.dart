import 'package:intl/intl.dart';

import '../../../core/l10n.dart';

/// "Last backup: Sep 10, 2026", or "No backup yet".
String lastBackupLabel(AppLocalizations l10n, DateTime? at) => at == null
    ? l10n.settingsNoBackup
    : l10n.settingsLastBackup(DateFormat.yMMMd(l10n.localeName).format(at));
