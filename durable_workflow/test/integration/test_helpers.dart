import 'dart:async';

import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow_sqlite/durable_workflow_sqlite.dart';

import '../test_helpers.dart' as shared;

// Re-export shared helpers so integration tests can use them.
export '../test_helpers.dart'
    show
        idGenerator,
        nowTimestamp,
        pastTimestamp,
        futureTimestamp,
        simulateCrash;

/// Creates a [SqliteCheckpointStore] backed by an in-memory database
/// with foreign key constraints disabled.
///
/// The engine does not manage the `workflows` table, so foreign key
/// constraints on `workflow_executions.workflow_id` would cause failures.
/// Integration tests disable foreign keys to test the engine end-to-end.
SqliteCheckpointStore createTestStore() {
  final store = SqliteCheckpointStore.inMemory();
  store.database.execute('PRAGMA foreign_keys = OFF');
  return store;
}

/// Polls the store until the execution reaches the expected status.
///
/// Throws [TimeoutException] if [timeout] elapses before the
/// status is reached.
Future<void> waitForStatus<T extends ExecutionStatus>(
  CheckpointStore store,
  String execId, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final exec = await store.loadExecution(execId);
    if (exec != null && exec.status is T) return;
    await Future<void>.delayed(
      const Duration(milliseconds: 20),
    );
  }
  throw TimeoutException(
    'Execution $execId did not reach $T',
    timeout,
  );
}

/// Creates a [DurableEngineImpl] configured for integration testing.
DurableEngineImpl createIntegrationEngine(
  CheckpointStore store, {
  String Function()? generateId,
  Duration timerPollInterval =
      const Duration(milliseconds: 50),
}) {
  return DurableEngineImpl(
    store: store,
    generateId: generateId ?? shared.idGenerator(),
    timerPollInterval: timerPollInterval,
  );
}
