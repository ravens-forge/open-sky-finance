import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A new random primary key (UUID v4, cryptographically secure RNG).
String newId() => _uuid.v4();
