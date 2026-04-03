/// Exception thrown when a workflow execution is cancelled during step execution.
class WorkflowCancelledException implements Exception {
  /// The execution ID that was cancelled.
  final String workflowExecutionId;

  /// Creates a [WorkflowCancelledException].
  const WorkflowCancelledException(this.workflowExecutionId);

  @override
  String toString() =>
      'WorkflowCancelledException: $workflowExecutionId was cancelled';
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
