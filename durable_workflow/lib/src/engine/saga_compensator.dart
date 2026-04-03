import '../model/execution_status.dart';
import '../model/step_checkpoint.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';

/// Executes saga compensation (rollback) for failed workflow executions.
///
/// When a workflow execution fails, the compensator:
/// 1. Transitions execution to COMPENSATING status
/// 2. Finds all COMPLETED steps with registered compensate functions (reverse order)
/// 3. Executes each compensation function
/// 4. Records COMPENSATED checkpoint for each
/// 5. Transitions execution to FAILED status
class SagaCompensator {
  final CheckpointStore _store;

  /// Creates a [SagaCompensator].
  SagaCompensator({required CheckpointStore store}) : _store = store;

  /// Runs saga compensation for the given execution.
  ///
  /// [workflowExecutionId] identifies the failed execution.
  /// [compensateFunctions] maps step names to their compensation functions.
  ///
  /// The compensator finds all COMPLETED steps with a matching compensation
  /// function and runs them in reverse order (last completed first).
  ///
  /// If a compensation function throws, the error is logged and the
  /// compensator continues with the next step (skip on failure).
  ///
  /// [onCompensateError] is called when a compensation function fails,
  /// receiving the step name and the error. Defaults to no-op.
  Future<void> compensate(
    String workflowExecutionId,
    Map<String, Future<void> Function(dynamic)> compensateFunctions, {
    Map<String, dynamic> compensateResults = const {},
    void Function(String stepName, Object error)? onCompensateError,
  }) async {
    final execution = await _store.loadExecution(workflowExecutionId);
    if (execution == null) return;

    await _store.saveExecution(
      execution.copyWith(
        status: const Compensating(),
        updatedAt: utcNow(),
      ),
    );

    // Load all checkpoints
    final checkpoints = await _store.loadCheckpoints(workflowExecutionId);

    // Find COMPLETED steps with compensate functions, in reverse order
    final completedSteps = checkpoints
        .where((cp) => cp.status == StepStatus.completed)
        .toList()
      ..sort((a, b) => b.stepIndex.compareTo(a.stepIndex)); // reverse order

    for (final cp in completedSteps) {
      final compensateFn = compensateFunctions[cp.stepName];
      if (compensateFn == null) continue; // skip steps without compensate

      try {
        await compensateFn(compensateResults[cp.stepName]);

        // Record COMPENSATED checkpoint with attempt=0 to avoid
        // overwriting the original COMPLETED checkpoint via the
        // UNIQUE(workflow_execution_id, step_index, attempt) constraint.
        final compensatedCheckpoint = StepCheckpoint(
          workflowExecutionId: workflowExecutionId,
          stepIndex: cp.stepIndex,
          stepName: '${cp.stepName}:compensate',
          status: StepStatus.compensated,
          attempt: 0,
          startedAt: utcNow(),
          completedAt: utcNow(),
        );
        await _store.saveCheckpoint(compensatedCheckpoint);
      } catch (e) {
        // Log and skip — DLQ is Phase 2
        onCompensateError?.call(cp.stepName, e);
      }
    }

    final current = await _store.loadExecution(workflowExecutionId);
    if (current != null) {
      await _store.saveExecution(
        current.copyWith(
          status: const Failed(),
          updatedAt: utcNow(),
        ),
      );
    }
  }
}
