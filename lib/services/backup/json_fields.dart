import '../../core/dates/wall_clock.dart';
import 'models/backup_problem.dart';
import 'models/backup_problem_code.dart';

/// Problems found while reading a backup. Keeps the first [limit], counts
/// them all.
class ProblemCollector {
  ProblemCollector({this.limit = 100});

  final int limit;
  final problems = <BackupProblem>[];
  int total = 0;

  bool get isEmpty => total == 0;

  void add(BackupProblemCode code, String path) {
    total++;
    if (problems.length < limit) problems.add(BackupProblem(code, path));
  }
}

/// Largest amount that stays exact in JSON readers that use doubles.
const maxMoney = 9007199254740991;

final _currency = RegExp(r'^[A-Z]{3}$');

/// Typed reads of one JSON object that record a problem under [path] and go
/// on with a placeholder, so one pass finds everything wrong with a file.
/// The placeholders never reach the database: any problem rejects the file.
class JsonFields {
  JsonFields(Object? json, this.path, this.problems)
    : _map = json is Map<String, Object?> ? json : const {} {
    if (json is! Map<String, Object?>) {
      problems.add(BackupProblemCode.wrongType, path);
    }
  }

  final Map<String, Object?> _map;
  final String path;
  final ProblemCollector problems;

  String at(String key) => path.isEmpty ? key : '$path.$key';

  bool has(String key) => _map[key] != null;

  /// The value of [key], or `null` (recording [BackupProblemCode.missing]
  /// unless [optional]) when it is absent or `null`.
  T? _read<T>(String key, {required bool optional}) {
    final value = _map[key];
    if (value == null) {
      if (!optional) problems.add(BackupProblemCode.missing, at(key));
      return null;
    }
    if (value is T) return value as T;
    problems.add(BackupProblemCode.wrongType, at(key));
    return null;
  }

  void invalid(String key) =>
      problems.add(BackupProblemCode.invalidValue, at(key));

  String string(String key, {String? orElse}) =>
      _read<String>(key, optional: orElse != null) ?? orElse ?? '';

  String? nullableString(String key) => _read<String>(key, optional: true);

  int integer(String key) => _read<int>(key, optional: false) ?? 0;

  int? nullableInteger(String key) => _read<int>(key, optional: true);

  bool boolean(String key, {bool? orElse}) =>
      _read<bool>(key, optional: orElse != null) ?? orElse ?? false;

  /// A non-empty string.
  String id(String key) {
    final value = string(key);
    if (has(key) && value.isEmpty) invalid(key);
    return value;
  }

  String? nullableId(String key) {
    final value = nullableString(key);
    if (value != null && value.isEmpty) invalid(key);
    return value;
  }

  /// 1 to 100 characters, as the tables require.
  String name(String key) {
    final value = string(key);
    if (has(key) && (value.isEmpty || value.length > 100)) invalid(key);
    return value;
  }

  /// ISO 4217: three uppercase letters.
  String currency(String key) {
    final value = string(key);
    if (has(key) && !_currency.hasMatch(value)) invalid(key);
    return value;
  }

  /// Micro-units.
  int money(String key) => _checkMoney(key, integer(key));

  int? nullableMoney(String key) => _checkMoney(key, nullableInteger(key));

  T _checkMoney<T extends int?>(String key, T value) {
    if (value != null && value.abs() > maxMoney) invalid(key);
    return value;
  }

  T enumValue<T extends Enum>(String key, List<T> values) =>
      _enum(key, values, optional: false) ?? values.first;

  T? nullableEnum<T extends Enum>(String key, List<T> values) =>
      _enum(key, values, optional: true);

  T? _enum<T extends Enum>(
    String key,
    List<T> values, {
    required bool optional,
  }) {
    final name = _read<String>(key, optional: optional);
    if (name == null) return null;
    final value = values.asNameMap()[name];
    if (value == null) invalid(key);
    return value;
  }

  /// Local wall-clock time without offset: `2026-03-14T18:30:00`.
  DateTime wallClock(String key) =>
      nullableWallClock(key, optional: false) ?? DateTime(2000);

  DateTime? nullableWallClock(String key, {bool optional = true}) {
    final text = _read<String>(key, optional: optional);
    if (text == null) return null;
    final value = parseWallClock(text);
    if (value == null) invalid(key);
    return value;
  }

  /// UTC instant ending in `Z`.
  DateTime instant(String key) =>
      nullableInstant(key, optional: false) ?? DateTime.utc(2000);

  DateTime? nullableInstant(String key, {bool optional = true}) {
    final text = _read<String>(key, optional: optional);
    if (text == null) return null;
    final value = DateTime.tryParse(text);
    if (value == null || !value.isUtc) {
      invalid(key);
      return null;
    }
    return value;
  }

  /// A nested object, or `null` when absent (a problem unless [optional]).
  JsonFields? object(String key, {bool optional = false}) {
    final value = _read<Map<String, Object?>>(key, optional: optional);
    return value == null ? null : JsonFields(value, at(key), problems);
  }

  /// An array of objects; absent is empty when [optional].
  List<JsonFields> objects(String key, {bool optional = false}) {
    final list = _read<List<Object?>>(key, optional: optional) ?? const [];
    return [
      for (final (i, item) in list.indexed)
        JsonFields(item, '${at(key)}[$i]', problems),
    ];
  }

  /// An array of ids; absent is empty.
  List<String> ids(String key) {
    final list = _read<List<Object?>>(key, optional: true) ?? const [];
    return [
      for (final (i, item) in list.indexed)
        if (item is String && item.isNotEmpty)
          item
        else
          _skip(BackupProblemCode.wrongType, '${at(key)}[$i]'),
    ];
  }

  String _skip(BackupProblemCode code, String path) {
    problems.add(code, path);
    return '';
  }
}
