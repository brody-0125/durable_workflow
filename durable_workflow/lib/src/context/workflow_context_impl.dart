import '../engine/signal_manager.dart';
import '../engine/step_executor.dart';
import '../engine/timer_manager.dart';
import '../model/retry_policy.dart';
import '../util/validation.dart';
import 'workflow_context.dart';

/// Concrete implementation of [WorkflowContext].
///
/// Delegates step execution to [StepExecutor] for checkpoint/resume semantics.
/// sleep() uses [TimerManager] for durable timers.
/// waitSignal() uses [SignalManager] for durable signal handling.
class WorkflowContextImpl implements WorkflowContext {
  final StepExecutor _executor;

  /// The timer manager for durable sleep operations.
  final TimerManager _timerManager;

  /// The signal manager for durable signal operations.
  final SignalManager _signalManager;

  /// The workflow execution ID (needed for timer/signal registration).
  final String _workflowExecutionId;

  @override
  String get executionId => _workflowExecutionId;

  /// Creates a [WorkflowContextImpl].
  WorkflowContextImpl({
    required StepExecutor executor,
    required TimerManager timerManager,
    required SignalManager signalManager,
    required String workflowExecutionId,
  })  : _executor = executor,
        _timerManager = timerManager,
        _signalManager = signalManager,
        _workflowExecutionId = workflowExecutionId;

  @override
  Future<T> step<T>(
    String name,
    Future<T> Function() action, {
    Future<void> Function(T result)? compensate,
    RetryPolicy retry = RetryPolicy.none,
    String Function(T value)? serialize,
    T Function(String data)? deserialize,
  }) {
    validateIdentifier(name, 'name');
    return _executor.executeStep<T>(
      name,
      action,
      serialize: serialize,
      deserialize: deserialize,
      retryPolicy: retry,
      compensate: compensate,
    );
  }

  @override
  Future<void> sleep(String name, Duration duration) {
    validateIdentifier(name, 'name');
    return _timerManager.registerTimer(
      workflowExecutionId: _workflowExecutionId,
      stepName: name,
      duration: duration,
    );
  }

  @override
  Future<T?> waitSignal<T>(
    String signalName, {
    Duration? timeout,
  }) async {
    validateIdentifier(signalName, 'signalName');
    final result = await _signalManager.waitForSignal(
      workflowExecutionId: _workflowExecutionId,
      signalName: signalName,
      timeout: timeout,
    );
    return result as T?;
  }
}
