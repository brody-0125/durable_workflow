import '../model/execution_status.dart';
import '../model/step_checkpoint.dart';
import '../model/workflow_execution.dart';
import '../model/workflow_signal.dart';
import '../model/workflow_timer.dart';

/// Abstract persistence interface for durable workflow state.
///
/// Implementations (e.g., SQLite, Drift) provide actual storage.
/// All methods return [Future] to support async I/O.
abstract class CheckpointStore {
  /// Persists a step checkpoint.
  ///
  /// If a checkpoint with the same (workflowExecutionId, stepIndex, attempt)
  /// already exists, it should be updated.
  Future<void> saveCheckpoint(StepCheckpoint checkpoint);

  /// Loads all checkpoints for a given workflow execution,
  /// ordered by [StepCheckpoint.stepIndex] ascending.
  Future<List<StepCheckpoint>> loadCheckpoints(
    String workflowExecutionId,
  );

  /// Persists a workflow timer.
  Future<void> saveTimer(WorkflowTimer timer);

  /// Loads all pending timers that should have fired by now
  /// or will fire in the near future.
  Future<List<WorkflowTimer>> loadPendingTimers();

  /// Persists a workflow signal.
  Future<void> saveSignal(WorkflowSignal signal);

  /// Loads all pending signals for a given workflow execution
  /// and optional signal name filter.
  Future<List<WorkflowSignal>> loadPendingSignals(
    String workflowExecutionId, {
    String? signalName,
  });

  /// Persists a workflow execution state.
  Future<void> saveExecution(WorkflowExecution execution);

  /// Loads a workflow execution by its ID.
  ///
  /// Returns `null` if not found.
  Future<WorkflowExecution?> loadExecution(
    String workflowExecutionId,
  );

  /// Loads all workflow executions matching any of the given [statuses].
  ///
  /// Used by [RecoveryScanner] to find executions that need to be resumed.
  Future<List<WorkflowExecution>> loadExecutionsByStatus(
    List<ExecutionStatus> statuses,
  );

  /// Deletes a workflow execution and all associated data
  /// (checkpoints, timers, signals).
  ///
  /// Use this to clean up completed or failed executions.
  Future<void> deleteExecution(String workflowExecutionId);

  /// Deletes all completed executions with [updatedAt] before [cutoff].
  ///
  /// Returns the number of executions deleted.
  /// Use this for periodic maintenance to prevent unbounded database growth.
  Future<int> deleteCompletedBefore(DateTime cutoff);

  /// Persists multiple checkpoints in a single batch operation.
  ///
  /// Implementations should use transactions for atomicity where possible.
  Future<void> saveCheckpoints(List<StepCheckpoint> checkpoints);

  /// Deletes timers in terminal states (FIRED, CANCELLED) older than [cutoff].
  ///
  /// Returns the number of timers deleted.
  Future<int> deleteOldTimers(DateTime cutoff);

  /// Deletes signals in terminal states (DELIVERED, EXPIRED) older than [cutoff].
  ///
  /// Returns the number of signals deleted.
  Future<int> deleteOldSignals(DateTime cutoff);
}
