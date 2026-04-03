import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

import 'fixtures.dart';

/// Creates a fresh in-memory [SqliteCheckpointStore] with
/// a default workflow and execution pre-seeded.
///
/// Useful for tests that need FK parents to be present.
Future<SqliteCheckpointStore> createSeededStore() async {
  final store = SqliteCheckpointStore.inMemory();
  await store.saveWorkflow(testWorkflow());
  await store.saveExecution(testExecution());
  return store;
}
