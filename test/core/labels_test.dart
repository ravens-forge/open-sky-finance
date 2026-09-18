import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_sky_finance/core/l10n.dart';
import 'package:open_sky_finance/core/labels.dart';
import 'package:open_sky_finance/core/result.dart';
import 'package:open_sky_finance/data/enums/assets_account_type.dart';
import 'package:open_sky_finance/data/enums/category_kind.dart';
import 'package:open_sky_finance/data/enums/transaction_type.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    test('labels are distinct in $locale', () {
      final l10n = lookupAppLocalizations(locale);
      for (final labels in [
        AssetsAccountType.values.map((e) => e.label(l10n)),
        TransactionType.values.map((e) => e.label(l10n)),
        CategoryKind.values.map((e) => e.label(l10n)),
        ThemeMode.values.map((e) => e.label(l10n)),
        AppError.values.map((e) => e.message(l10n)),
      ]) {
        expect(labels.toSet(), hasLength(labels.length));
      }
    });
  }

  test('labels come from the locale', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    expect(AssetsAccountType.creditCard.label(fr), 'Carte de crédit');
    expect(TransactionType.transfer.label(fr), 'Virement');
  });
}
