/// Base exception for all durable workflow errors.
///
/// All workflow-specific exceptions extend this class, allowing callers
/// to catch workflow errors generically or by specific subtype.
class DurableWorkflowException implements Exception {
  /// Human-readable error message.
  final String message;

  /// Creates a [DurableWorkflowException].
  const DurableWorkflowException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when a workflow execution is cancelled during step execution.
class WorkflowCancelledException extends DurableWorkflowException {
  /// The execution ID that was cancelled.
  final String workflowExecutionId;

  /// Creates a [WorkflowCancelledException].
  const WorkflowCancelledException(this.workflowExecutionId)
      : super('$workflowExecutionId was cancelled');
}

/// Exception thrown when a signal wait times out.
class WorkflowTimeoutException extends DurableWorkflowException {
  /// The execution ID where the timeout occurred.
  final String workflowExecutionId;

  /// The signal name that timed out.
  final String signalName;

  /// The timeout duration that was exceeded.
  final Duration? timeout;

  /// Creates a [WorkflowTimeoutException].
  const WorkflowTimeoutException({
    required this.workflowExecutionId,
    required this.signalName,
    this.timeout,
  }) : super(
          'Signal "$signalName" timed out for execution $workflowExecutionId',
        );
}

/// Exception thrown when a workflow execution is not found.
class WorkflowExecutionNotFoundException extends DurableWorkflowException {
  /// The execution ID that was not found.
  final String workflowExecutionId;

  /// Creates a [WorkflowExecutionNotFoundException].
  const WorkflowExecutionNotFoundException(this.workflowExecutionId)
      : super('Execution $workflowExecutionId not found');
}

/// Exception thrown when saga compensation fails.
class CompensationException extends DurableWorkflowException {
  /// The execution ID where compensation failed.
  final String workflowExecutionId;

  /// The step name that failed to compensate.
  final String stepName;

  /// The original error that caused the compensation failure.
  final Object originalError;

  /// Creates a [CompensationException].
  CompensationException({
    required this.workflowExecutionId,
    required this.stepName,
    required this.originalError,
  }) : super(
          'Compensation failed for step "$stepName" in execution '
          '$workflowExecutionId: $originalError',
        );
}

/// Callback signature for step name mismatch warnings during replay.
///
/// Called when a step's name at replay time differs from the checkpointed name,
/// which can happen when dynamic step names (e.g. `'process-${item.id}'`)
/// are used and parameters change between original execution and recovery.
///
/// - [workflowExecutionId]: The execution that encountered the mismatch.
/// - [stepIndex]: The zero-based step position.
/// - [checkpointedName]: The step name recorded in the checkpoint store.
/// - [currentName]: The step name provided during this (replay) execution.
typedef StepNameMismatchWarning = void Function(
  String workflowExecutionId,
  int stepIndex,
  String checkpointedName,
  String currentName,
);
