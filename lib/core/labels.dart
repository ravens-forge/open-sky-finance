import 'package:flutter/material.dart';

import '../data/enums/assets_account_type.dart';
import '../data/enums/budget_period.dart';
import '../data/enums/category_kind.dart';
import '../data/enums/transaction_type.dart';
import 'l10n.dart';
import 'result.dart';

extension AssetsAccountTypeLabel on AssetsAccountType {
  String label(AppLocalizations l10n) => switch (this) {
    AssetsAccountType.bank => l10n.assetsAccountTypeBank,
    AssetsAccountType.cash => l10n.assetsAccountTypeCash,
    AssetsAccountType.investment => l10n.assetsAccountTypeInvestment,
    AssetsAccountType.crypto => l10n.assetsAccountTypeCrypto,
    AssetsAccountType.receivable => l10n.assetsAccountTypeReceivable,
    AssetsAccountType.property => l10n.assetsAccountTypeProperty,
    AssetsAccountType.externalAsset => l10n.assetsAccountTypeExternalAsset,
    AssetsAccountType.virtual => l10n.assetsAccountTypeVirtual,
    AssetsAccountType.otherAsset => l10n.assetsAccountTypeOtherAsset,
    AssetsAccountType.creditCard => l10n.assetsAccountTypeCreditCard,
    AssetsAccountType.loan => l10n.assetsAccountTypeLoan,
    AssetsAccountType.payable => l10n.assetsAccountTypePayable,
    AssetsAccountType.mortgage => l10n.assetsAccountTypeMortgage,
    AssetsAccountType.externalLiability =>
      l10n.assetsAccountTypeExternalLiability,
    AssetsAccountType.otherLiability => l10n.assetsAccountTypeOtherLiability,
  };
}

extension TransactionTypeLabel on TransactionType {
  String label(AppLocalizations l10n) => switch (this) {
    TransactionType.expense => l10n.transactionTypeExpense,
    TransactionType.income => l10n.transactionTypeIncome,
    TransactionType.transfer => l10n.transactionTypeTransfer,
    TransactionType.openingBalance => l10n.transactionTypeOpeningBalance,
  };
}

extension CategoryKindLabel on CategoryKind {
  String label(AppLocalizations l10n) => switch (this) {
    CategoryKind.expense => l10n.categoryKindExpense,
    CategoryKind.income => l10n.categoryKindIncome,
  };
}

extension BudgetPeriodLabel on BudgetPeriod {
  String label(AppLocalizations l10n) => switch (this) {
    BudgetPeriod.monthly => l10n.budgetPeriodMonthly,
  };
}

extension ThemeModeLabel on ThemeMode {
  String label(AppLocalizations l10n) => switch (this) {
    ThemeMode.system => l10n.themeModeSystem,
    ThemeMode.light => l10n.themeModeLight,
    ThemeMode.dark => l10n.themeModeDark,
  };
}

extension AppErrorMessage on AppError {
  String message(AppLocalizations l10n) => switch (this) {
    AppError.loadFailed => l10n.errorLoadFailed,
    AppError.saveFailed => l10n.errorSaveFailed,
    AppError.invalidAmount => l10n.errorInvalidAmount,
  };
}
