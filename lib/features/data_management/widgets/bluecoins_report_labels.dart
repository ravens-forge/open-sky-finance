import '../../../core/l10n.dart';
import '../../../services/bluecoins/models/bluecoins_note.dart';
import '../../../services/bluecoins/models/bluecoins_skip_reason.dart';

String bluecoinsSkipLabel(AppLocalizations l10n, BluecoinsSkipReason reason) =>
    switch (reason) {
      BluecoinsSkipReason.deleted => l10n.bluecoinsSkippedDeleted,
      BluecoinsSkipReason.reminder => l10n.bluecoinsSkippedReminder,
      BluecoinsSkipReason.orphanTransfer => l10n.bluecoinsSkippedOrphanTransfer,
      BluecoinsSkipReason.unknownType => l10n.bluecoinsSkippedUnknownType,
      BluecoinsSkipReason.otherCurrency => l10n.bluecoinsSkippedOtherCurrency,
      BluecoinsSkipReason.missingAssetsAccount =>
        l10n.bluecoinsSkippedMissingAssetsAccount,
      BluecoinsSkipReason.budget => l10n.bluecoinsSkippedBudget,
      BluecoinsSkipReason.invalid => l10n.bluecoinsSkippedInvalid,
    };

String bluecoinsNoteLabel(AppLocalizations l10n, BluecoinsNote note) =>
    switch (note) {
      BluecoinsNote.unknownAssetsAccountType =>
        l10n.bluecoinsNoteUnknownAssetsAccountType,
      BluecoinsNote.uncategorized => l10n.bluecoinsNoteUncategorized,
      BluecoinsNote.splitTransaction => l10n.bluecoinsNoteSplitTransaction,
    };
