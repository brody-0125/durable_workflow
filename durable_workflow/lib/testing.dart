/// Test-only utilities for the durable_workflow package.
///
/// This library exposes [InMemoryCheckpointStore], shared fixture factories,
/// and [runCheckpointStoreContractTests] for verifying custom [CheckpointStore]
/// implementations.
///
/// For production use, prefer a persistent implementation such as
/// `SqliteCheckpointStore` from `package:durable_workflow_sqlite`.
///
/// ```dart
/// import 'package:durable_workflow/testing.dart';
///
/// final store = InMemoryCheckpointStore();
/// ```
library durable_workflow_testing;

export 'src/persistence/in_memory_checkpoint_store.dart';
export 'src/testing/contract_tests.dart';
export 'src/testing/fixtures.dart';
