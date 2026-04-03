import '../context/workflow_context.dart';
import '../model/workflow_execution.dart';
import '../model/workflow_guarantee.dart';

/// Abstract interface for the durable workflow execution engine.
///
/// Provides the top-level API for running, cancelling, observing,
/// and sending signals to workflow executions.
abstract class DurableEngine {
  /// Runs a workflow and returns its result.
  ///
  /// - [workflowType]: The type/name of the workflow.
  /// - [body]: The workflow function that receives a [WorkflowContext].
  /// - [input]: Optional JSON-serializable input data.
  /// - [ttl]: Optional time-to-live for the workflow execution.
  /// - [guarantee]: The execution guarantee level.
  ///
  /// Returns the result produced by [body].
  Future<T> run<T>(
    String workflowType,
    Future<T> Function(WorkflowContext ctx) body, {
    String? input,
    Duration? ttl,
    WorkflowGuarantee guarantee,
  });

  /// Cancels a running workflow execution.
  ///
  /// If the execution is in a compensatable state, saga compensation
  /// will be triggered before marking as cancelled.
  Future<void> cancel(String workflowExecutionId);

  /// Returns a stream of execution state changes for observation.
  ///
  /// Emits the current state immediately, then subsequent updates.
  Stream<WorkflowExecution> observe(String workflowExecutionId);

  /// Sends an external signal to a workflow execution.
  ///
  /// - [workflowExecutionId]: The target execution.
  /// - [signalName]: The name of the signal (matched by `waitSignal`).
  /// - [payload]: Optional JSON-serializable payload.
  Future<void> sendSignal(
    String workflowExecutionId,
    String signalName, [
    Object? payload,
  ]);

  /// Releases all resources held by this engine.
  ///
  /// After calling dispose, the engine should not be used.
  void dispose();
}
