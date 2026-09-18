import 'package:flutter/foundation.dart';

/// An amount in micro-units (1.00 = 1 000 000) of [currency] (ISO 4217).
@immutable
class Money {
  const Money(this.micros, this.currency);

  final int micros;
  final String currency;

  @override
  bool operator ==(Object other) =>
      other is Money && other.micros == micros && other.currency == currency;

  @override
  int get hashCode => Object.hash(micros, currency);
}
