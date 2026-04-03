/// SQLite implementation of CheckpointStore for durable_workflow.
///
/// Provides [SqliteCheckpointStore] backed by sqlite3 FFI,
/// with automatic schema migration and WAL journal mode.
library durable_workflow_sqlite;

export 'src/migrations.dart' show migrate;
export 'src/schema.dart' show schemaVersion;
export 'src/sqlite_checkpoint_store.dart';
