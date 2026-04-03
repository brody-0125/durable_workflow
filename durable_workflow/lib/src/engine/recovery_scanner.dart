import '../context/workflow_context.dart';
import '../model/execution_status.dart';
import '../model/workflow_execution.dart';
import '../persistence/checkpoint_store.dart';
import '../util/clock.dart';
import 'durable_engine_impl.dart';

/// Result of a recovery scan operation.
class RecoveryScanResult {
  /// Executions that were resumed.
  final List<String> resumed;

  /// Executions that were marked as FAILED due to TTL expiry.
  final List<String> expired;

  /// Creates a [RecoveryScanResult].
  const RecoveryScanResult({
    required this.resumed,
    required this.expired,
  });

  @override
  String toString() =>
      'RecoveryScanResult(resumed: ${resumed.length}, expired: ${expired.length})';
}

/// Scans for interrupted workflow executions and resumes or fails them.
///
/// On engine startup, the recovery scanner:
/// 1. Queries executions in RUNNING or SUSPENDED status
/// 2. Checks TTL expiry - marks expired ones as FAILED
/// 3. Restores pending timers and signals
/// 4. Resumes valid executions from their last completed step
class RecoveryScanner {
  final CheckpointStore _store;
  final DurableEngineImpl _engine;

  /// Creates a [RecoveryScanner].
  RecoveryScanner({
    required CheckpointStore store,
    required DurableEngineImpl engine,
  })  : _store = store,
        _engine = engine;

  /// Scans for and recovers interrupted executions.
  ///
  /// [workflowRegistry] maps workflow types to their body functions,
  /// enabling the scanner to re-execute workflows from their last checkpoint.
  ///
  /// Returns a [RecoveryScanResult] summarizing what happened.
  Future<RecoveryScanResult> scan({
    required Map<String, Future<dynamic> Function(WorkflowContext ctx)>
        workflowRegistry,
    void Function(String executionId, Object error)? onRecoveryError,
  }) async {
    // Restore pending timers from the store
    await _engine.timerManager.restorePendingTimers();

    final interrupted = await _store.loadExecutionsByStatus([
      const Running(),
      const Suspended(),
    ]);

    final resumed = <String>[];
    final expired = <String>[];

    for (final execution in interrupted) {
      if (_isTtlExpired(execution)) {
        // Mark as FAILED due to TTL expiry
        await _store.saveExecution(
          execution.copyWith(
            status: const Failed(),
            errorMessage: 'Workflow TTL expired',
            updatedAt: utcNow(),
          ),
        );
        expired.add(execution.workflowExecutionId);
        continue;
      }

      // Restore pending signals for this execution
      await _engine.signalManager
          .restorePendingSignals(execution.workflowExecutionId);

      // Find the workflow body from the registry
      final workflowType = _extractWorkflowType(execution.workflowId);
      final body = workflowRegistry[workflowType];

      if (body == null) {
        // Cannot resume without the workflow body
        await _store.saveExecution(
          execution.copyWith(
            status: const Failed(),
            errorMessage:
                'No registered workflow body for type: $workflowType',
            updatedAt: utcNow(),
          ),
        );
        expired.add(execution.workflowExecutionId);
        continue;
      }

      // Resume the execution (fire-and-forget for async workflows)
      try {
        await _engine.resume(execution.workflowExecutionId, body);
        resumed.add(execution.workflowExecutionId);
      } catch (e) {
        onRecoveryError?.call(execution.workflowExecutionId, e);
        expired.add(execution.workflowExecutionId);
      }
    }

    return RecoveryScanResult(resumed: resumed, expired: expired);
  }

  /// Checks if an execution's TTL has expired.
  bool _isTtlExpired(WorkflowExecution execution) {
    if (execution.ttlExpiresAt == null) return false;
    final expiresAt = DateTime.parse(execution.ttlExpiresAt!);
    return DateTime.now().toUtc().isAfter(expiresAt);
  }

  /// Extracts the workflow type from the workflow ID.
  ///
  /// Workflow IDs are formatted as "wf-{type}-{counter}".
  String _extractWorkflowType(String workflowId) {
    final parts = workflowId.split('-');
    if (parts.length >= 3) {
      // Join all parts except first ("wf") and last (counter)
      return parts.sublist(1, parts.length - 1).join('-');
    }
    return workflowId;
  }
}
