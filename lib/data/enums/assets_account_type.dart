enum AssetsAccountType {
  bank,
  cash,
  investment,
  crypto,
  receivable,
  property,
  externalAsset,
  virtual,
  otherAsset,
  creditCard,
  loan,
  payable,
  mortgage,
  externalLiability,
  otherLiability;

  /// Credit cards, loans… what the user owes. The rest are assets.
  bool get isLiability => index >= creditCard.index;
}
