import 'package:durable_workflow/durable_workflow.dart';
import 'package:durable_workflow/internals.dart';
import 'package:durable_workflow/testing.dart';

// Re-export shared fixtures so existing test imports keep working.
export 'package:durable_workflow/testing.dart'
    show
        createTestExecution,
        createTestCheckpoint,
        createTestTimer,
        createTestSignal,
        nowTimestamp,
        pastTimestamp,
        futureTimestamp;

/// Creates a deterministic ID generator for engine tests.
///
/// Returns IDs in the format `exec-0`, `exec-1`, etc.
String Function() idGenerator() {
  var counter = 0;
  return () => 'exec-${counter++}';
}

/// Creates a [DurableEngineImpl] configured for deterministic testing.
///
/// Uses [InMemoryCheckpointStore] and a sequential ID generator.
/// The [timerPollInterval] defaults to 50ms for fast test execution.
DurableEngineImpl createTestEngine(
  InMemoryCheckpointStore store, {
  String Function()? generateId,
  Duration timerPollInterval = const Duration(milliseconds: 50),
  StepNameMismatchWarning? onStepNameMismatch,
}) {
  return DurableEngineImpl(
    store: store,
    generateId: generateId ?? idGenerator(),
    timerPollInterval: timerPollInterval,
    onStepNameMismatch: onStepNameMismatch,
  );
}

/// Creates a [StepExecutor] with a pre-initialized store for testing.
///
/// Saves the execution and initializes the executor in one call.
Future<StepExecutor> createTestExecutor(
  InMemoryCheckpointStore store, {
  required String executionId,
  String workflowId = 'wf-test-0',
  Future<void> Function(Duration)? delayFn,
  StepNameMismatchWarning? onStepNameMismatch,
}) async {
  await store.saveExecution(createTestExecution(executionId));
  final executor = StepExecutor(
    store: store,
    workflowExecutionId: executionId,
    delayFn: delayFn,
    onStepNameMismatch: onStepNameMismatch,
  );
  await executor.initialize();
  return executor;
}

/// Simulates a crash by resetting execution status to RUNNING.
///
/// Loads the execution, clears the error message, and saves it
/// back with RUNNING status — mimicking a process that terminated
/// before writing the FAILED status.
Future<void> simulateCrash(
  CheckpointStore store,
  String executionId,
) async {
  final exec = await store.loadExecution(executionId);
  if (exec == null) {
    throw StateError('Execution $executionId not found');
  }
  await store.saveExecution(exec.copyWith(
    status: const Running(),
    errorMessage: null,
    updatedAt: nowTimestamp(),
  ));
}
