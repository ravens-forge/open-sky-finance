import 'package:flutter/material.dart';

import '../../../core/finance_colors.dart';
import '../../../core/widgets/category_avatar.dart';
import '../../../data/enums/assets_account_type.dart';

/// Round icon of an assets account type: `primary` for assets, `expense` for
/// liabilities.
class AssetsAccountAvatar extends StatelessWidget {
  const AssetsAccountAvatar(this.type, {super.key});

  final AssetsAccountType type;

  @override
  Widget build(BuildContext context) {
    return CategoryAvatar(
      size: 36,
      icon: switch (type) {
        AssetsAccountType.bank => Icons.account_balance_outlined,
        AssetsAccountType.cash => Icons.payments_outlined,
        AssetsAccountType.investment => Icons.trending_up,
        AssetsAccountType.crypto => Icons.currency_bitcoin,
        AssetsAccountType.receivable => Icons.call_received,
        AssetsAccountType.property => Icons.home_outlined,
        AssetsAccountType.virtual => Icons.cloud_outlined,
        AssetsAccountType.creditCard => Icons.credit_card,
        AssetsAccountType.loan ||
        AssetsAccountType.payable => Icons.attach_money,
        AssetsAccountType.mortgage => Icons.house_outlined,
        AssetsAccountType.externalAsset ||
        AssetsAccountType.externalLiability => Icons.open_in_new,
        AssetsAccountType.otherAsset ||
        AssetsAccountType.otherLiability => Icons.wallet_outlined,
      },
      color: type.isLiability
          ? FinanceColors.of(context).expense
          : Theme.of(context).colorScheme.primary,
    );
  }
}
