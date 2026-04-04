import '../model/execution_status.dart';

/// Observer interface for monitoring durable engine lifecycle events.
///
/// Subclass and override only the methods you need. All methods have
/// empty default implementations, following the Flutter observer pattern
/// (e.g., [NavigatorObserver]).
///
/// Register observers via [DurableEngineImpl]'s `observers` parameter.
/// Observer method errors are caught internally and do not affect
/// engine execution.
abstract class DurableEngineObserver {
  /// Called when a workflow execution starts.
  void onExecutionStart(String executionId, String workflowType) {}

  /// Called when a workflow execution reaches a terminal state.
  void onExecutionComplete(
    String executionId,
    ExecutionStatus status,
  ) {}

  /// Called when a step begins executing.
  void onStepStart(
    String executionId,
    String stepName,
    int stepIndex,
  ) {}

  /// Called when a step completes successfully.
  void onStepComplete(
    String executionId,
    String stepName,
    int stepIndex,
    Duration elapsed,
  ) {}

  /// Called when a step is retried after failure.
  void onStepRetry(
    String executionId,
    String stepName,
    int attempt,
    Object error,
  ) {}

  /// Called when saga compensation begins.
  void onCompensationStart(
    String executionId,
    List<String> stepsToCompensate,
  ) {}

  /// Called when a recovery scan starts.
  void onRecoveryStart(String executionId) {}

  /// Called when a recovery scan completes for an execution.
  void onRecoveryComplete(String executionId, bool success) {}

  /// Called when an error occurs during execution.
  void onError(String executionId, String context, Object error) {}
}
