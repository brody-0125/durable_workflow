import 'dart:async';

import '../model/execution_status.dart';
import '../model/workflow_timer.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';
import 'step_executor.dart';

/// Manages durable timers for workflow sleep operations.
///
/// When a workflow calls `ctx.sleep(name, duration)`, a timer record is
/// persisted to the [CheckpointStore] and a [Completer] is returned.
/// A periodic poller checks for expired timers and completes them.
///
/// On recovery, pending timers are loaded from the store and either
/// fired immediately (if past due) or scheduled via [Timer].
class TimerManager {
  final CheckpointStore _store;

  /// Pending completers keyed by timer ID.
  final Map<String, Completer<void>> _completers = {};

  /// Active dart:async timers keyed by timer ID.
  final Map<String, Timer> _dartTimers = {};

  /// Periodic poller for expired timers.
  Timer? _poller;

  /// Poll interval for checking expired timers.
  final Duration pollInterval;

  /// Creates a [TimerManager].
  TimerManager({
    required CheckpointStore store,
    this.pollInterval = const Duration(seconds: 1),
  }) : _store = store;

  /// Starts the timer poller.
  void start() {
    _poller?.cancel();
    _poller = Timer.periodic(pollInterval, (_) => _pollExpiredTimers());
  }

  /// Stops the timer poller.
  void stop() {
    _poller?.cancel();
    _poller = null;
  }

  /// Disposes all resources.
  void dispose() {
    stop();
    for (final timer in _dartTimers.values) {
      timer.cancel();
    }
    _dartTimers.clear();
    // Complete any remaining completers with an error to avoid dangling futures
    for (final entry in _completers.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(
          StateError('TimerManager disposed while timer ${entry.key} pending'),
        );
      }
    }
    _completers.clear();
  }

  /// Registers a durable timer for a workflow sleep.
  ///
  /// Persists the timer to the store, marks the execution as SUSPENDED,
  /// and returns a [Future] that completes when the timer fires.
  Future<void> registerTimer({
    required String workflowExecutionId,
    required String stepName,
    required Duration duration,
  }) async {
    final now = DateTime.now().toUtc();
    final fireAt = now.add(duration);
    final timerId = 'timer-$workflowExecutionId-$stepName';

    final timer = WorkflowTimer(
      workflowTimerId: timerId,
      workflowExecutionId: workflowExecutionId,
      stepName: stepName,
      fireAt: fireAt.toIso8601String(),
      status: TimerStatus.pending,
      createdAt: now.toIso8601String(),
    );
    await _store.saveTimer(timer);

    final execution = await _store.loadExecution(workflowExecutionId);
    if (execution != null) {
      await _store.saveExecution(
        execution.copyWith(
          status: const Suspended(),
          updatedAt: utcNow(),
        ),
      );
    }

    final completer = Completer<void>();
    _completers[timerId] = completer;

    _scheduleOrFire(timerId, fireAt);

    return completer.future;
  }

  /// Restores pending timers from the store after a process restart.
  ///
  /// Timers that are past due are fired immediately.
  /// Future timers get a dart:async Timer scheduled.
  Future<void> restorePendingTimers() async {
    final pendingTimers = await _store.loadPendingTimers();
    for (final timer in pendingTimers) {
      final timerId = timer.workflowTimerId;
      if (_completers.containsKey(timerId)) continue; // Already tracked

      final completer = Completer<void>();
      _completers[timerId] = completer;

      _scheduleOrFire(timerId, DateTime.parse(timer.fireAt));
    }
  }

  /// Cancels all pending timers for a given execution.
  Future<void> cancelTimers(String workflowExecutionId) async {
    final pendingTimers = await _store.loadPendingTimers();
    for (final timer in pendingTimers) {
      if (timer.workflowExecutionId != workflowExecutionId) continue;

      final timerId = timer.workflowTimerId;

      await _store.saveTimer(
        timer.copyWith(status: TimerStatus.cancelled),
      );

      _dartTimers[timerId]?.cancel();
      _dartTimers.remove(timerId);

      // Complete the completer with WorkflowCancelledException so the
      // engine's run() method catches it properly.
      final completer = _completers.remove(timerId);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(
          WorkflowCancelledException(workflowExecutionId),
        );
      }
    }
  }

  /// Returns the completer for a given timer ID (used in recovery).
  Completer<void>? getCompleter(String timerId) => _completers[timerId];

  /// Schedules a dart:async Timer for precise firing, or fires immediately
  /// if already past due.
  void _scheduleOrFire(String timerId, DateTime fireAt) {
    final remaining = fireAt.difference(DateTime.now().toUtc());
    if (remaining.isNegative || remaining == Duration.zero) {
      _fireTimerById(timerId);
    } else {
      _dartTimers[timerId] = Timer(remaining, () => _fireTimerById(timerId));
    }
  }

  /// Fires a timer directly from its [WorkflowTimer] object, avoiding a
  /// redundant full-table lookup.
  Future<void> _fireTimer(WorkflowTimer timer) async {
    final timerId = timer.workflowTimerId;

    await _store.saveTimer(
      timer.copyWith(status: TimerStatus.fired),
    );

    final execution =
        await _store.loadExecution(timer.workflowExecutionId);
    if (execution != null && execution.status is Suspended) {
      await _store.saveExecution(
        execution.copyWith(
          status: const Running(),
          updatedAt: utcNow(),
        ),
      );
    }

    _dartTimers[timerId]?.cancel();
    _dartTimers.remove(timerId);

    final completer = _completers.remove(timerId);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  /// Fires a timer by ID. Loads all pending timers to find the matching one.
  /// Prefer [_fireTimer] when the timer object is already available.
  Future<void> _fireTimerById(String timerId) async {
    final pendingTimers = await _store.loadPendingTimers();
    for (final timer in pendingTimers) {
      if (timer.workflowTimerId == timerId) {
        await _fireTimer(timer);
        return;
      }
    }

    // Timer not found in store (already fired or cancelled) — just clean up
    _dartTimers[timerId]?.cancel();
    _dartTimers.remove(timerId);
    final completer = _completers.remove(timerId);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _pollExpiredTimers() async {
    if (_completers.isEmpty) return;

    final pendingTimers = await _store.loadPendingTimers();
    final now = DateTime.now().toUtc();

    for (final timer in pendingTimers) {
      final fireAt = DateTime.parse(timer.fireAt);
      if (now.isAfter(fireAt) || now.isAtSameMomentAs(fireAt)) {
        await _fireTimer(timer);
      }
    }
  }
}
