import 'dart:convert';

import '../model/execution_status.dart';
import '../model/retry_policy.dart';
import '../model/step_checkpoint.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';
import 'retry_executor.dart';
import 'types.dart';

export 'types.dart' show WorkflowCancelledException, StepNameMismatchWarning;

/// Executes individual workflow steps with checkpoint/resume semantics.
///
/// The execution loop for each step:
/// 1. Check CheckpointStore for existing COMPLETED checkpoint -> skip if found
/// 2. Record INTENT checkpoint
/// 3. Execute the step action
/// 4. Record COMPLETED checkpoint with output
/// 5. On exception: record FAILED checkpoint
class StepExecutor {
  final CheckpointStore _store;
  final String _workflowExecutionId;
  final RetryExecutor _retryExecutor;

  /// Tracks whether this execution has been cancelled.
  bool _cancelled = false;

  /// Current step index, incremented as steps are executed.
  int _stepIndex = 0;

  /// Completed checkpoints indexed by step index for O(1) replay lookup.
  Map<int, StepCheckpoint> _completedByIndex = {};

  /// Registered compensation functions keyed by step name.
  /// Each function accepts the step result as a dynamic parameter.
  final Map<String, Future<void> Function(dynamic)> compensateFunctions = {};

  /// Cached step results for compensation, keyed by step name.
  final Map<String, dynamic> compensateResults = {};

  /// Injectable delay function for testing (avoids real waits in tests).
  Future<void> Function(Duration delay)? delayFn;

  /// Callback invoked when a step name mismatch is detected during replay.
  /// This warns that a dynamic step name has changed between the original
  /// execution and recovery, which may indicate non-deterministic workflow
  /// logic or changed input parameters.
  final StepNameMismatchWarning onStepNameMismatch;

  /// Creates a [StepExecutor].
  ///
  /// [retryExecutor] is injectable for testing.
  /// [onStepNameMismatch] is called when a replayed step's name differs from
  /// the checkpointed name. Defaults to printing a warning to stdout.
  StepExecutor({
    required CheckpointStore store,
    required String workflowExecutionId,
    RetryExecutor? retryExecutor,
    this.delayFn,
    StepNameMismatchWarning? onStepNameMismatch,
  })  : _store = store,
        _workflowExecutionId = workflowExecutionId,
        _retryExecutor = retryExecutor ?? RetryExecutor(),
        onStepNameMismatch = onStepNameMismatch ?? _defaultMismatchWarning;

  /// Default warning handler that prints to stdout.
  static void _defaultMismatchWarning(
    String workflowExecutionId,
    int stepIndex,
    String checkpointedName,
    String currentName,
  ) {
    // ignore: avoid_print
    print(
      '[durable_workflow] WARNING: Step name mismatch in execution '
      '"$workflowExecutionId" at index $stepIndex during replay. '
      'Checkpointed: "$checkpointedName", Current: "$currentName". '
      'This may indicate non-deterministic workflow logic or changed parameters.',
    );
  }

  /// The current step index.
  int get stepIndex => _stepIndex;

  /// Whether this execution has been cancelled.
  bool get isCancelled => _cancelled;

  /// Marks this execution as cancelled.
  ///
  /// The next call to [executeStep] will throw [WorkflowCancelledException].
  void cancel() {
    _cancelled = true;
  }

  /// Loads existing checkpoints from the store for replay.
  ///
  /// Must be called before the first [executeStep] call.
  /// Checkpoints are loaded and used for replay detection, but the
  /// step counter remains at 0 since the workflow body will call steps
  /// in order from the beginning.
  Future<void> initialize() async {
    final checkpoints = await _store.loadCheckpoints(_workflowExecutionId);
    _completedByIndex = {
      for (final cp in checkpoints)
        if (cp.status == StepStatus.completed) cp.stepIndex: cp,
    };
  }

  /// Executes a single step with checkpoint/resume semantics and retry support.
  ///
  /// If a COMPLETED checkpoint exists for this step, returns the cached output.
  /// Otherwise records INTENT, executes [action], and records COMPLETED.
  /// On failure, retries according to [retryPolicy] before recording FAILED.
  ///
  /// If [compensate] is provided, it is registered for saga rollback.
  ///
  /// The [serialize] and [deserialize] functions handle converting the step
  /// result to/from a JSON-encodable string for persistence.
  Future<T> executeStep<T>(
    String name,
    Future<T> Function() action, {
    String Function(T value)? serialize,
    T Function(String data)? deserialize,
    RetryPolicy retryPolicy = RetryPolicy.none,
    Future<void> Function(T result)? compensate,
  }) async {
    if (_cancelled) {
      throw WorkflowCancelledException(_workflowExecutionId);
    }

    final currentIndex = _stepIndex++;
    final now = utcNow();

    // Check for existing COMPLETED checkpoint (replay)
    final existing = _findCompletedCheckpoint(currentIndex);
    if (existing != null) {
      // Detect dynamic step name mismatch
      if (existing.stepName != name) {
        onStepNameMismatch(
          _workflowExecutionId,
          currentIndex,
          existing.stepName,
          name,
        );
      }

      // Deserialize the cached result for replay
      T replayResult;
      if (existing.outputData != null && deserialize != null) {
        replayResult = deserialize(existing.outputData!);
      } else if (existing.outputData != null) {
        final decoded = jsonDecode(existing.outputData!);
        replayResult = decoded as T;
      } else {
        replayResult = null as T;
      }

      // Register compensate under the checkpointed name so that
      // SagaCompensator (which looks up by checkpoint stepName) can find it.
      if (compensate != null) {
        compensateFunctions[existing.stepName] =
            (dynamic v) => compensate(v as T);
        compensateResults[existing.stepName] = replayResult;
      }

      return replayResult;
    }

    // Register compensate function if provided (non-replay path).
    // The result will be stored after execution succeeds.
    Future<void> Function(dynamic)? wrappedCompensate;
    if (compensate != null) {
      wrappedCompensate = (dynamic v) => compensate(v as T);
    }

    final intentCheckpoint = StepCheckpoint(
      workflowExecutionId: _workflowExecutionId,
      stepIndex: currentIndex,
      stepName: name,
      status: StepStatus.intent,
      compensateRef: compensate != null ? name : null,
      startedAt: now,
    );
    await _store.saveCheckpoint(intentCheckpoint);

    try {
      final result = await _retryExecutor.executeWithRetry<T>(
        retryPolicy,
        action,
        delayFn: delayFn,
        onRetry: (attempt, error) async {
          // Record FAILED checkpoint for this attempt
          final failedCheckpoint = intentCheckpoint.copyWith(
            status: StepStatus.failed,
            attempt: attempt,
            errorMessage: error.toString(),
            completedAt: utcNow(),
          );
          await _store.saveCheckpoint(failedCheckpoint);
        },
      );

      // Register compensate with the result now that execution succeeded
      if (wrappedCompensate != null) {
        compensateFunctions[name] = wrappedCompensate;
        compensateResults[name] = result;
      }

      String? outputData;
      if (serialize != null) {
        outputData = serialize(result);
      } else if (result != null) {
        outputData = jsonEncode(result);
      }

      final completedCheckpoint = intentCheckpoint.copyWith(
        status: StepStatus.completed,
        outputData: outputData,
        compensateRef: compensate != null ? name : null,
        completedAt: utcNow(),
      );
      await _store.saveCheckpoint(completedCheckpoint);

      final execution = await _store.loadExecution(_workflowExecutionId);
      if (execution != null) {
        await _store.saveExecution(
          execution.copyWith(
            currentStep: currentIndex,
            updatedAt: utcNow(),
          ),
        );
      }

      return result;
    } catch (e) {
      if (e is WorkflowCancelledException) rethrow;

      final maxAttempt = switch (retryPolicy) {
        RetryPolicyNone() => 1,
        RetryPolicyFixed(maxAttempts: final max) => max,
        RetryPolicyExponential(maxAttempts: final max) => max,
      };
      final failedCheckpoint = intentCheckpoint.copyWith(
        status: StepStatus.failed,
        attempt: maxAttempt,
        errorMessage: e.toString(),
        completedAt: utcNow(),
      );
      await _store.saveCheckpoint(failedCheckpoint);

      final execution = await _store.loadExecution(_workflowExecutionId);
      if (execution != null) {
        await _store.saveExecution(
          execution.copyWith(
            status: const Failed(),
            errorMessage: e.toString(),
            updatedAt: utcNow(),
          ),
        );
      }

      rethrow;
    }
  }

  StepCheckpoint? _findCompletedCheckpoint(int stepIndex) {
    return _completedByIndex[stepIndex];
  }
}
