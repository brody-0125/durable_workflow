import '../model/execution_status.dart';
import '../model/step_checkpoint.dart';
import '../model/workflow_execution.dart';
import '../model/workflow_signal.dart';
import '../model/workflow_timer.dart';
import 'checkpoint_store.dart';

/// In-memory implementation of [CheckpointStore] for **testing only**.
///
/// Stores all data in plain Dart collections. Data is lost when the process
/// exits — do **not** use in production. For persistent storage, use
/// `SqliteCheckpointStore` from `package:durable_workflow_sqlite`.
///
/// Import via the dedicated test barrel:
/// ```dart
/// import 'package:durable_workflow/testing.dart';
/// ```
class InMemoryCheckpointStore implements CheckpointStore {
  final Map<String, WorkflowExecution> _executions = {};
  final Map<String, List<StepCheckpoint>> _checkpoints = {};
  final List<WorkflowTimer> _timers = [];
  final List<WorkflowSignal> _signals = [];

  int _nextCheckpointId = 1;
  int _nextSignalId = 1;

  @override
  Future<void> saveCheckpoint(StepCheckpoint checkpoint) async {
    final key = checkpoint.workflowExecutionId;
    final list = _checkpoints.putIfAbsent(key, () => []);

    // Update existing checkpoint with same (executionId, stepIndex, attempt)
    final existingIndex = list.indexWhere(
      (cp) =>
          cp.stepIndex == checkpoint.stepIndex &&
          cp.attempt == checkpoint.attempt,
    );

    final saved = checkpoint.id != null
        ? checkpoint
        : checkpoint.copyWith(id: _nextCheckpointId++);

    if (existingIndex >= 0) {
      list[existingIndex] = saved;
    } else {
      list.add(saved);
    }
  }

  @override
  Future<List<StepCheckpoint>> loadCheckpoints(
    String workflowExecutionId,
  ) async {
    final list = _checkpoints[workflowExecutionId] ?? [];
    return List.unmodifiable(
      list.toList()..sort((a, b) => a.stepIndex.compareTo(b.stepIndex)),
    );
  }

  @override
  Future<void> saveTimer(WorkflowTimer timer) async {
    final existingIndex = _timers.indexWhere(
      (t) => t.workflowTimerId == timer.workflowTimerId,
    );
    if (existingIndex >= 0) {
      _timers[existingIndex] = timer;
    } else {
      _timers.add(timer);
    }
  }

  @override
  Future<List<WorkflowTimer>> loadPendingTimers() async {
    return _timers.where((t) => t.status == TimerStatus.pending).toList();
  }

  @override
  Future<void> saveSignal(WorkflowSignal signal) async {
    final saved = signal.workflowSignalId != null
        ? signal
        : signal.copyWith(workflowSignalId: _nextSignalId++);

    final existingIndex = _signals.indexWhere(
      (s) => s.workflowSignalId == saved.workflowSignalId,
    );
    if (existingIndex >= 0) {
      _signals[existingIndex] = saved;
    } else {
      _signals.add(saved);
    }
  }

  @override
  Future<List<WorkflowSignal>> loadPendingSignals(
    String workflowExecutionId, {
    String? signalName,
  }) async {
    return _signals.where((s) {
      if (s.workflowExecutionId != workflowExecutionId) return false;
      if (s.status != SignalStatus.pending) return false;
      if (signalName != null && s.signalName != signalName) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> saveExecution(WorkflowExecution execution) async {
    _executions[execution.workflowExecutionId] = execution;
  }

  @override
  Future<WorkflowExecution?> loadExecution(
    String workflowExecutionId,
  ) async {
    return _executions[workflowExecutionId];
  }

  @override
  Future<List<WorkflowExecution>> loadExecutionsByStatus(
    List<ExecutionStatus> statuses,
  ) async {
    return _executions.values
        .where((e) => statuses.any((s) => s == e.status))
        .toList();
  }

  @override
  Future<void> deleteExecution(String workflowExecutionId) async {
    _executions.remove(workflowExecutionId);
    _checkpoints.remove(workflowExecutionId);
    _timers.removeWhere((t) => t.workflowExecutionId == workflowExecutionId);
    _signals.removeWhere((s) => s.workflowExecutionId == workflowExecutionId);
  }

  @override
  Future<int> deleteCompletedBefore(DateTime cutoff) async {
    final toDelete = _executions.values
        .where((e) =>
            e.status is Completed &&
            DateTime.parse(e.updatedAt).isBefore(cutoff))
        .map((e) => e.workflowExecutionId)
        .toList();

    for (final id in toDelete) {
      await deleteExecution(id);
    }
    return toDelete.length;
  }
}
