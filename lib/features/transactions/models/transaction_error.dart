import '../../../core/l10n.dart';
import '../../../data/repositories/repository_data_error.dart';

String transactionErrorMessage(
  RepositoryDataError error,
  AppLocalizations l10n,
) => switch (error) {
  RepositoryDataError.invalidAmount => l10n.errorInvalidAmount,
  RepositoryDataError.toAmountRequired => l10n.errorAmountReceivedRequired,
  RepositoryDataError.transferToSameAssetsAccount => l10n.errorDestinationSame,
  RepositoryDataError.categoryKindMismatch => l10n.errorCategoryKindMismatch,
  RepositoryDataError.categoryNotAllowed => l10n.errorTransferCategory,
  RepositoryDataError.notFound => l10n.errorLoadFailed,
  _ => l10n.errorSaveFailed,
};
