import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';
import 'transaction.dart';

/// Applies PRAGMA settings for optimal performance and safety.
void applyPragmas(Database db) {
  for (final pragma in pragmaStatements) {
    db.execute(pragma);
  }
}

/// Runs schema migrations based on the `user_version` PRAGMA.
///
/// Throws [StateError] if the database version is newer than
/// the code supports.
void migrate(Database db) {
  final currentVersion = _getUserVersion(db);

  if (currentVersion > schemaVersion) {
    throw StateError(
      'Database schema version ($currentVersion) is newer than '
      'the supported version ($schemaVersion). '
      'Please upgrade the durable_workflow_sqlite package.',
    );
  }

  if (currentVersion < 1) {
    _migrateToV1(db);
  }
}

int _getUserVersion(Database db) {
  final result = db.select('PRAGMA user_version');
  return result.first['user_version'] as int;
}

void _setUserVersion(Database db, int version) {
  db.execute('PRAGMA user_version = $version');
}

void _migrateToV1(Database db) {
  runInTransaction(db, () {
    for (final statement in schemaV1Statements) {
      db.execute(statement);
    }
    _setUserVersion(db, 1);
  });
}
