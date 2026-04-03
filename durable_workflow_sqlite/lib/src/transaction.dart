import 'package:sqlite3/sqlite3.dart';

/// Executes [action] within a `BEGIN IMMEDIATE` transaction.
///
/// Automatically commits on success and rolls back on error.
/// Returns the result of [action].
T runInTransaction<T>(Database db, T Function() action) {
  db.execute('BEGIN IMMEDIATE');
  try {
    final result = action();
    db.execute('COMMIT');
    return result;
  } catch (e) {
    db.execute('ROLLBACK');
    rethrow;
  }
}
