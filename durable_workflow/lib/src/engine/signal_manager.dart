import 'dart:async';

import '../model/execution_status.dart';
import '../model/workflow_signal.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';
import 'types.dart';

/// Manages durable signals for workflow waitSignal operations.
///
/// When a workflow calls `ctx.waitSignal(name, timeout)`, a PENDING signal
/// record is persisted to the [CheckpointStore] and a [Completer] is returned.
/// When `sendSignal()` is called, the matching PENDING signal is found,
/// marked as DELIVERED, and its completer is completed with the payload.
///
/// If a signal has already been sent before `waitSignal` is called, the
/// existing PENDING signal is consumed immediately.
class SignalManager {
  final CheckpointStore _store;

  /// Pending completers keyed by a composite key of executionId:signalName.
  final Map<String, Completer<Object?>> _completers = {};

  /// Active timeout timers keyed by the same composite key.
  final Map<String, Timer> _timeoutTimers = {};

  /// Creates a [SignalManager].
  SignalManager({required CheckpointStore store}) : _store = store;

  /// Disposes all resources.
  void dispose() {
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();

    for (final entry in _completers.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(
          StateError(
              'SignalManager disposed while waiting for signal ${entry.key}'),
        );
      }
    }
    _completers.clear();
  }

  /// Waits for a signal to be delivered to a workflow execution.
  ///
  /// Checks for already-delivered (PENDING) signals first. If found,
  /// consumes it immediately. Otherwise, creates a PENDING signal record
  /// and suspends execution until [deliverSignal] is called.
  ///
  /// If [timeout] is provided, the signal will be marked EXPIRED and a
  /// [TimeoutException] will be thrown after the duration elapses.
  Future<Object?> waitForSignal({
    required String workflowExecutionId,
    required String signalName,
    Duration? timeout,
  }) async {
    // Check for already-arrived signal (pre-sent before waitSignal was called)
    final existingSignals = await _store.loadPendingSignals(
      workflowExecutionId,
      signalName: signalName,
    );
    if (existingSignals.isNotEmpty) {
      final signal = existingSignals.first;
      await _store.saveSignal(
        signal.copyWith(status: SignalStatus.delivered),
      );
      return signal.payload;
    }

    // No signal yet — create a PENDING record and suspend
    final now = utcNow();
    final pendingSignal = WorkflowSignal(
      workflowExecutionId: workflowExecutionId,
      signalName: signalName,
      status: SignalStatus.pending,
      createdAt: now,
    );
    await _store.saveSignal(pendingSignal);

    final execution = await _store.loadExecution(workflowExecutionId);
    if (execution != null) {
      await _store.saveExecution(
        execution.copyWith(
          status: const Suspended(),
          updatedAt: utcNow(),
        ),
      );
    }

    final key = _compositeKey(workflowExecutionId, signalName);
    final completer = Completer<Object?>();
    _completers[key] = completer;

    // Set up timeout if specified
    if (timeout != null) {
      _timeoutTimers[key] = Timer(timeout, () async {
        // Guard: if deliverSignal() already completed this completer,
        // or if it was removed from the map, skip timeout handling.
        if (completer.isCompleted || !_completers.containsKey(key)) {
          _timeoutTimers.remove(key);
          return;
        }
        // Mark signal as EXPIRED
        final signals = await _store.loadPendingSignals(
          workflowExecutionId,
          signalName: signalName,
        );
        for (final s in signals) {
          await _store.saveSignal(
            s.copyWith(status: SignalStatus.expired),
          );
        }
        _completers.remove(key);
        _timeoutTimers.remove(key);
        if (!completer.isCompleted) {
          completer.completeError(
            WorkflowTimeoutException(
              workflowExecutionId: workflowExecutionId,
              signalName: signalName,
              timeout: timeout,
            ),
          );
        }
      });
    }

    return completer.future;
  }

  /// Delivers a signal to a waiting workflow.
  ///
  /// If a completer is registered (workflow is actively waiting), the signal
  /// is delivered immediately. Otherwise the signal remains PENDING in the
  /// store for later consumption by [waitForSignal].
  Future<void> deliverSignal({
    required String workflowExecutionId,
    required String signalName,
    Object? payload,
  }) async {
    final key = _compositeKey(workflowExecutionId, signalName);

    // Check if there's an active waiter
    final completer = _completers.remove(key);
    if (completer != null && !completer.isCompleted) {
      // Find the pending signal in the store and mark as DELIVERED
      final signals = await _store.loadPendingSignals(
        workflowExecutionId,
        signalName: signalName,
      );
      for (final s in signals) {
        await _store.saveSignal(
          s.copyWith(
            status: SignalStatus.delivered,
            payload: payload?.toString(),
          ),
        );
      }

      // Cancel timeout timer
      _timeoutTimers[key]?.cancel();
      _timeoutTimers.remove(key);

      // Resume execution
      final execution = await _store.loadExecution(workflowExecutionId);
      if (execution != null && execution.status is Suspended) {
        await _store.saveExecution(
          execution.copyWith(
            status: const Running(),
            updatedAt: utcNow(),
          ),
        );
      }

      completer.complete(payload?.toString());
    }
    // If no active waiter, the signal was already saved by DurableEngineImpl.sendSignal()
    // and will be picked up when waitForSignal is called.
  }

  /// Cancels all pending signals for a given execution.
  Future<void> cancelSignals(String workflowExecutionId) async {
    final signals = await _store.loadPendingSignals(workflowExecutionId);
    for (final signal in signals) {
      await _store.saveSignal(
        signal.copyWith(status: SignalStatus.expired),
      );
    }

    // Cancel any active completers and timeouts for this execution
    final keysToRemove = <String>[];
    for (final key in _completers.keys) {
      if (key.startsWith('$workflowExecutionId:')) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _timeoutTimers[key]?.cancel();
      _timeoutTimers.remove(key);

      final completer = _completers.remove(key);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(
          WorkflowCancelledException(workflowExecutionId),
        );
      }
    }
  }

  /// Restores pending signals from the store after a process restart.
  ///
  /// Re-creates completers for any PENDING signals so that resumed
  /// workflows can await them again.
  Future<void> restorePendingSignals(String workflowExecutionId) async {
    final signals = await _store.loadPendingSignals(workflowExecutionId);
    for (final signal in signals) {
      final key = _compositeKey(workflowExecutionId, signal.signalName);
      if (!_completers.containsKey(key)) {
        _completers[key] = Completer<Object?>();
      }
    }
  }

  String _compositeKey(String executionId, String signalName) =>
      '$executionId:$signalName';
}
