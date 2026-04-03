import 'dart:async';

import '../context/workflow_context.dart';
import '../context/workflow_context_impl.dart';
import '../model/execution_status.dart';
import '../model/workflow_execution.dart';
import '../model/workflow_guarantee.dart';
import '../model/workflow_signal.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';
import 'durable_engine.dart';
import 'saga_compensator.dart';
import 'signal_manager.dart';
import 'step_executor.dart';
import 'timer_manager.dart';
import 'types.dart';
import '../util/validation.dart';

/// Concrete implementation of [DurableEngine].
///
/// Orchestrates workflow execution by creating [WorkflowExecution] records,
/// delegating step execution to [StepExecutor] via [WorkflowContextImpl],
/// and managing lifecycle state transitions.
class DurableEngineImpl implements DurableEngine {
  final CheckpointStore _store;

  /// Active step executors keyed by workflow execution ID.
  final Map<String, StepExecutor> _executors = {};

  /// Broadcast stream controllers for observe(), keyed by execution ID.
  final Map<String, StreamController<WorkflowExecution>> _observers = {};

  /// ID generator function, injectable for testing.
  final String Function() _generateId;

  int _idCounter = 0;

  /// Timer manager for durable sleep operations.
  final TimerManager _timerManager;

  /// Signal manager for durable signal operations.
  final SignalManager _signalManager;

  /// Optional callback for step name mismatch warnings during replay.
  /// Passed through to each [StepExecutor] instance.
  final StepNameMismatchWarning? _onStepNameMismatch;

  /// Creates a [DurableEngineImpl].
  ///
  /// [store] is the checkpoint store for persistence.
  /// [generateId] is an optional ID generator for testing determinism.
  /// [timerPollInterval] controls how often the timer poller checks for
  /// expired timers. Defaults to 1 second.
  /// [onStepNameMismatch] is called when a replayed step's current name
  /// differs from the checkpointed name. See [StepNameMismatchWarning].
  DurableEngineImpl({
    required CheckpointStore store,
    String Function()? generateId,
    Duration timerPollInterval = const Duration(seconds: 1),
    StepNameMismatchWarning? onStepNameMismatch,
  })  : _store = store,
        _generateId = generateId ?? _defaultGenerateId,
        _onStepNameMismatch = onStepNameMismatch,
        _timerManager = TimerManager(
          store: store,
          pollInterval: timerPollInterval,
        ),
        _signalManager = SignalManager(store: store) {
    _timerManager.start();
  }

  static String _defaultGenerateId() {
    return 'exec-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// The underlying checkpoint store.
  CheckpointStore get store => _store;

  /// The timer manager instance.
  TimerManager get timerManager => _timerManager;

  /// The signal manager instance.
  SignalManager get signalManager => _signalManager;

  @override
  Future<T> run<T>(
    String workflowType,
    Future<T> Function(WorkflowContext ctx) body, {
    String? input,
    Duration? ttl,
    WorkflowGuarantee guarantee = WorkflowGuarantee.foregroundOnly,
  }) async {
    validateIdentifier(workflowType, 'workflowType');
    final executionId = _generateId();
    final now = utcNow();

    final workflowId = 'wf-$workflowType-${_idCounter++}';

    String? ttlExpiresAt;
    if (ttl != null) {
      ttlExpiresAt = DateTime.now().toUtc().add(ttl).toIso8601String();
    }

    final execution = WorkflowExecution(
      workflowExecutionId: executionId,
      workflowId: workflowId,
      status: const Running(),
      inputData: input,
      ttlExpiresAt: ttlExpiresAt,
      guarantee: guarantee,
      createdAt: now,
      updatedAt: now,
    );

    await _store.saveExecution(execution);
    _notifyObservers(executionId, execution);

    return _executeBody<T>(executionId, execution, body);
  }

  /// Resumes a previously interrupted workflow execution.
  ///
  /// Used by [RecoveryScanner] to continue executions that were
  /// in RUNNING or SUSPENDED state.
  Future<T> resume<T>(
    String workflowExecutionId,
    Future<T> Function(WorkflowContext ctx) body,
  ) async {
    var execution = await _store.loadExecution(workflowExecutionId);
    if (execution == null) {
      throw WorkflowExecutionNotFoundException(workflowExecutionId);
    }

    execution = execution.copyWith(
      status: const Running(),
      updatedAt: utcNow(),
    );
    await _store.saveExecution(execution);
    _notifyObservers(workflowExecutionId, execution);

    return _executeBody<T>(workflowExecutionId, execution, body);
  }

  /// Shared execution body for [run] and [resume].
  ///
  /// Creates a [StepExecutor] and [WorkflowContextImpl], runs the workflow
  /// body, and handles completion, cancellation, failure, and saga compensation.
  Future<T> _executeBody<T>(
    String executionId,
    WorkflowExecution execution,
    Future<T> Function(WorkflowContext ctx) body,
  ) async {
    final executor = StepExecutor(
      store: _store,
      workflowExecutionId: executionId,
      onStepNameMismatch: _onStepNameMismatch,
    );
    await executor.initialize();
    _executors[executionId] = executor;

    final context = WorkflowContextImpl(
      executor: executor,
      timerManager: _timerManager,
      signalManager: _signalManager,
      workflowExecutionId: executionId,
    );

    try {
      final result = await body(context);

      final completed = execution.copyWith(
        status: const Completed(),
        updatedAt: utcNow(),
      );
      await _store.saveExecution(completed);
      _notifyObservers(executionId, completed);
      _cleanupObserver(executionId);

      return result;
    } on WorkflowCancelledException {
      // Already marked as CANCELLED by cancel()
      final current = await _store.loadExecution(executionId);
      if (current != null) {
        _notifyObservers(executionId, current);
      }
      _cleanupObserver(executionId);
      throw StateError('Workflow $executionId was cancelled');
    } catch (e) {
      final current = await _store.loadExecution(executionId);
      WorkflowExecution latest = execution;
      if (current != null && current.status is! Failed) {
        latest = current.copyWith(
          status: const Failed(),
          errorMessage: e.toString(),
          updatedAt: utcNow(),
        );
        await _store.saveExecution(latest);
      } else if (current != null) {
        latest = current;
      }
      _notifyObservers(executionId, latest);

      if (executor.compensateFunctions.isNotEmpty) {
        final compensator = SagaCompensator(store: _store);
        await compensator.compensate(
          executionId,
          executor.compensateFunctions,
          compensateResults: executor.compensateResults,
        );
        final finalExec = await _store.loadExecution(executionId);
        if (finalExec != null) {
          _notifyObservers(executionId, finalExec);
        }
      }

      _cleanupObserver(executionId);
      rethrow;
    } finally {
      _executors.remove(executionId);
    }
  }

  @override
  Future<void> cancel(String workflowExecutionId) async {
    final executor = _executors[workflowExecutionId];
    if (executor != null) {
      executor.cancel();
    }

    await _timerManager.cancelTimers(workflowExecutionId);
    await _signalManager.cancelSignals(workflowExecutionId);

    final execution = await _store.loadExecution(workflowExecutionId);
    if (execution == null) {
      throw WorkflowExecutionNotFoundException(workflowExecutionId);
    }

    final updated = execution.copyWith(
      status: const Cancelled(),
      updatedAt: utcNow(),
    );
    await _store.saveExecution(updated);
    _notifyObservers(workflowExecutionId, updated);
  }

  @override
  Stream<WorkflowExecution> observe(String workflowExecutionId) {
    _observers.putIfAbsent(
      workflowExecutionId,
      () => StreamController<WorkflowExecution>.broadcast(),
    );

    return _observeStream(workflowExecutionId);
  }

  Stream<WorkflowExecution> _observeStream(
    String workflowExecutionId,
  ) async* {
    final execution = await _store.loadExecution(workflowExecutionId);
    if (execution != null) {
      yield execution;
    } else {
      return;
    }

    final controller = _observers[workflowExecutionId];
    if (controller != null && !controller.isClosed) {
      yield* controller.stream;
    }
  }

  @override
  Future<void> sendSignal(
    String workflowExecutionId,
    String signalName, [
    Object? payload,
  ]) async {
    validateIdentifier(workflowExecutionId, 'workflowExecutionId');
    validateIdentifier(signalName, 'signalName');
    final signal = WorkflowSignal(
      workflowExecutionId: workflowExecutionId,
      signalName: signalName,
      payload: payload?.toString(),
      createdAt: utcNow(),
    );
    await _store.saveSignal(signal);

    await _signalManager.deliverSignal(
      workflowExecutionId: workflowExecutionId,
      signalName: signalName,
      payload: payload,
    );
  }

  void _notifyObservers(
    String workflowExecutionId,
    WorkflowExecution execution,
  ) {
    final controller = _observers[workflowExecutionId];
    if (controller != null && !controller.isClosed) {
      controller.add(execution);
    }
  }

  /// Closes and removes the observer for a terminal execution,
  /// preventing unbounded growth of the [_observers] map.
  void _cleanupObserver(String workflowExecutionId) {
    final controller = _observers.remove(workflowExecutionId);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  /// Closes all observer streams. Call when the engine is disposed.
  @override
  void dispose() {
    _timerManager.dispose();
    _signalManager.dispose();
    for (final controller in _observers.values) {
      controller.close();
    }
    _observers.clear();
  }
}
