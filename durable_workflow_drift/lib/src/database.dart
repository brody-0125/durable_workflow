import 'package:drift/drift.dart';

import 'tables.dart';

part 'database.g.dart';

/// Drift database for durable workflow persistence.
///
/// Includes all five workflow tables with indexes and foreign keys.
/// Schema migrations are managed by Drift's built-in migration system.
@DriftDatabase(tables: [
  Workflows,
  WorkflowExecutions,
  StepCheckpoints,
  WorkflowTimers,
  WorkflowSignals,
])
class DurableWorkflowDatabase extends _$DurableWorkflowDatabase {
  DurableWorkflowDatabase(super.e);

  @override

  /// Current database schema version.
  int get schemaVersion => 1;

  @override

  /// Migration strategy for schema creation and upgrades.
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here
        },
        beforeOpen: (details) async {
          // Enable foreign keys and WAL mode for performance
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
          await customStatement('PRAGMA busy_timeout = 5000');
          await customStatement('PRAGMA cache_size = -8000');
          await customStatement('PRAGMA temp_store = MEMORY');
          await customStatement('PRAGMA mmap_size = 268435456');
        },
      );
}
