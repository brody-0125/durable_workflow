import '../model/retry_policy.dart';

/// Abstract interface for workflow step execution context.
///
/// Provided to the workflow function body to execute durable steps,
/// sleep with durable timers, and wait for external signals.
abstract class WorkflowContext {
  /// The unique identifier for this workflow execution.
  ///
  /// Useful for logging, correlation, and external system integration.
  String get executionId;

  /// Executes a named step with checkpoint/resume semantics.
  ///
  /// - [name]: Human-readable step name (used as checkpoint key).
  /// - [action]: The function to execute. Should contain a single side effect.
  /// - [compensate]: Optional compensation function for saga rollback.
  ///   Receives the step result as a parameter, enabling direct access
  ///   to the result without mutable variable workarounds.
  /// - [retry]: Retry policy for this step. Defaults to no retry.
  /// - [serialize]: Custom serializer to convert the step result to a string
  ///   for checkpoint persistence. If omitted, `jsonEncode(result)` is used.
  /// - [deserialize]: Custom deserializer to reconstruct the step result from
  ///   the persisted string on recovery. If omitted, `jsonDecode` + cast is used,
  ///   which only works for primitive types. **Required for custom object types.**
  ///
  /// Returns the result of [action] (or the cached result on resume).
  Future<T> step<T>(
    String name,
    Future<T> Function() action, {
    Future<void> Function(T result)? compensate,
    RetryPolicy retry,
    String Function(T value)? serialize,
    T Function(String data)? deserialize,
  });

  /// Suspends the workflow for the given [duration] using a durable timer.
  ///
  /// The timer survives process restarts via database persistence.
  /// - [name]: Human-readable name for this sleep step.
  /// - [duration]: How long to sleep.
  Future<void> sleep(String name, Duration duration);

  /// Suspends the workflow until an external signal is received.
  ///
  /// - [signalName]: The name of the signal to wait for.
  /// - [timeout]: Optional maximum wait time before expiring.
  ///
  /// Returns the signal payload, or `null` if timed out.
  Future<T?> waitSignal<T>(
    String signalName, {
    Duration? timeout,
  });
}
