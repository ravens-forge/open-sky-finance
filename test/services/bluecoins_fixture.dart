import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// A synthetic Bluecoins backup built from the committed SQL scripts: the
/// schema, then the sample data unless [sample] is false, then [extra]. The
/// file lives in a temporary folder deleted after the test.
File bluecoinsFixture({bool sample = true, String? extra}) {
  final dir = Directory.systemTemp.createTempSync('bluecoins_test');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}${Platform.pathSeparator}sample.fydb');
  final db = sqlite3.open(file.path);
  try {
    db.execute(
      File('test/fixtures/bluecoins/schema_v47.sql').readAsStringSync(),
    );
    if (sample) {
      db.execute(
        File('test/fixtures/bluecoins/sample_data.sql').readAsStringSync(),
      );
    }
    if (extra != null) db.execute(extra);
  } finally {
    db.close();
  }
  return file;
}
