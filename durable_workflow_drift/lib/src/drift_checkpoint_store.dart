import 'package:drift/drift.dart' hide JsonKey;
import 'package:durable_workflow/durable_workflow.dart';

// Hide Drift-generated DataClasses that conflict with durable_workflow models.
import 'database.dart'
    hide
        Workflow,
        WorkflowExecution,
        StepCheckpoint,
        WorkflowTimer,
        WorkflowSignal;

/// Drift ORM-backed implementation of [CheckpointStore].
///
/// Uses Drift's type-safe query builder for all persistence operations.
/// Supports both in-memory and file-based databases via Drift's
/// [QueryExecutor] abstraction.
class DriftCheckpointStore implements CheckpointStore {
  final DurableWorkflowDatabase _db;

  DriftCheckpointStore(this._db);

  /// Provides direct access to the database for testing.
  DurableWorkflowDatabase get database => _db;

  /// Closes the underlying Drift database connection.
  Future<void> close() => _db.close();

  static const _executionCols =
      'workflow_execution_id, workflow_id, status, current_step, '
      'input_data, output_data, error_message, ttl_expires_at, '
      'guarantee, created_at, updated_at';

  static const _checkpointCols =
      'id, workflow_execution_id, step_index, step_name, status, '
      'input_data, output_data, error_message, attempt, '
      'idempotency_key, compensate_ref, started_at, completed_at';

  static const _timerCols =
      'workflow_timer_id, workflow_execution_id, step_name, '
      'fire_at, status, created_at';

  static const _signalCols =
      'workflow_signal_id, workflow_execution_id, signal_name, '
      'payload, status, created_at';

  static WorkflowExecution _rowToExecution(QueryRow row) {
    return WorkflowExecution(
      workflowExecutionId: row.read<String>('workflow_execution_id'),
      workflowId: row.read<String>('workflow_id'),
      status: ExecutionStatus.fromString(row.read<String>('status')),
      currentStep: row.read<int>('current_step'),
      inputData: row.readNullable<String>('input_data'),
      outputData: row.readNullable<String>('output_data'),
      errorMessage: row.readNullable<String>('error_message'),
      ttlExpiresAt: row.readNullable<String>('ttl_expires_at'),
      guarantee: WorkflowGuarantee.fromString(row.read<String>('guarantee')),
      createdAt: row.read<String>('created_at'),
      updatedAt: row.read<String>('updated_at'),
    );
  }

  static StepCheckpoint _rowToCheckpoint(QueryRow row) {
    return StepCheckpoint(
      id: row.read<int>('id'),
      workflowExecutionId: row.read<String>('workflow_execution_id'),
      stepIndex: row.read<int>('step_index'),
      stepName: row.read<String>('step_name'),
      status: StepStatus.fromString(row.read<String>('status')),
      inputData: row.readNullable<String>('input_data'),
      outputData: row.readNullable<String>('output_data'),
      errorMessage: row.readNullable<String>('error_message'),
      attempt: row.read<int>('attempt'),
      compensateRef: row.readNullable<String>('compensate_ref'),
      startedAt: row.readNullable<String>('started_at'),
      completedAt: row.readNullable<String>('completed_at'),
    );
  }

  static WorkflowTimer _rowToTimer(QueryRow row) {
    return WorkflowTimer(
      workflowTimerId: row.read<String>('workflow_timer_id'),
      workflowExecutionId: row.read<String>('workflow_execution_id'),
      stepName: row.read<String>('step_name'),
      fireAt: row.read<String>('fire_at'),
      status: TimerStatus.fromString(row.read<String>('status')),
      createdAt: row.read<String>('created_at'),
    );
  }

  static WorkflowSignal _rowToSignal(QueryRow row) {
    return WorkflowSignal(
      workflowSignalId: row.readNullable<int>('workflow_signal_id'),
      workflowExecutionId: row.read<String>('workflow_execution_id'),
      signalName: row.read<String>('signal_name'),
      payload: row.readNullable<String>('payload'),
      status: SignalStatus.fromString(row.read<String>('status')),
      createdAt: row.read<String>('created_at'),
    );
  }

  /// Ensures a workflow definition exists in the database.
  Future<void> saveWorkflow(Workflow workflow) async {
    await _db.customInsert(
      'INSERT OR REPLACE INTO workflows '
      '(workflow_id, workflow_type, version, created_at) '
      'VALUES (?, ?, ?, ?)',
      variables: [
        Variable.withString(workflow.workflowId),
        Variable.withString(workflow.workflowType),
        Variable.withInt(workflow.version),
        Variable.withString(workflow.createdAt),
      ],
      updates: {_db.workflows},
    );
  }

  /// Loads a workflow by its ID. Returns `null` if not found.
  Future<Workflow?> loadWorkflow(String workflowId) async {
    final rows = await _db.customSelect(
      'SELECT workflow_id, workflow_type, version, created_at '
      'FROM workflows WHERE workflow_id = ?',
      variables: [Variable.withString(workflowId)],
      readsFrom: {_db.workflows},
    ).get();

    if (rows.isEmpty) return null;
    final row = rows.first;
    return Workflow(
      workflowId: row.read<String>('workflow_id'),
      workflowType: row.read<String>('workflow_type'),
      version: row.read<int>('version'),
      createdAt: row.read<String>('created_at'),
    );
  }

  @override

  /// Persists a workflow execution via INSERT OR REPLACE.
  Future<void> saveExecution(WorkflowExecution execution) async {
    await _db.customInsert(
      'INSERT OR REPLACE INTO workflow_executions '
      '($_executionCols) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(execution.workflowExecutionId),
        Variable.withString(execution.workflowId),
        Variable.withString(execution.status.name),
        Variable.withInt(execution.currentStep),
        Variable(execution.inputData),
        Variable(execution.outputData),
        Variable(execution.errorMessage),
        Variable(execution.ttlExpiresAt),
        Variable.withString(execution.guarantee.value),
        Variable.withString(execution.createdAt),
        Variable.withString(execution.updatedAt),
      ],
      updates: {_db.workflowExecutions},
    );
  }

  @override

  /// Loads a workflow execution by ID. Returns `null` if not found.
  Future<WorkflowExecution?> loadExecution(
    String workflowExecutionId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT $_executionCols '
      'FROM workflow_executions WHERE workflow_execution_id = ?',
      variables: [Variable.withString(workflowExecutionId)],
      readsFrom: {_db.workflowExecutions},
    ).get();

    if (rows.isEmpty) return null;
    return _rowToExecution(rows.first);
  }

  @override

  /// Persists a step checkpoint via INSERT OR REPLACE.
  Future<void> saveCheckpoint(StepCheckpoint checkpoint) async {
    await _db.customInsert(
      'INSERT OR REPLACE INTO step_checkpoints '
      '(workflow_execution_id, step_index, step_name, status, '
      'input_data, output_data, error_message, attempt, '
      'idempotency_key, compensate_ref, started_at, completed_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(checkpoint.workflowExecutionId),
        Variable.withInt(checkpoint.stepIndex),
        Variable.withString(checkpoint.stepName),
        Variable.withString(checkpoint.status.value),
        Variable(checkpoint.inputData),
        Variable(checkpoint.outputData),
        Variable(checkpoint.errorMessage),
        Variable.withInt(checkpoint.attempt),
        const Variable<String>(null), // idempotencyKey column preserved for schema compatibility
        Variable(checkpoint.compensateRef),
        Variable(checkpoint.startedAt),
        Variable(checkpoint.completedAt),
      ],
      updates: {_db.stepCheckpoints},
    );
  }

  @override

  /// Loads all checkpoints for an execution, ordered by step index.
  Future<List<StepCheckpoint>> loadCheckpoints(
    String workflowExecutionId,
  ) async {
    final rows = await _db.customSelect(
      'SELECT $_checkpointCols '
      'FROM step_checkpoints '
      'WHERE workflow_execution_id = ? '
      'ORDER BY step_index ASC',
      variables: [Variable.withString(workflowExecutionId)],
      readsFrom: {_db.stepCheckpoints},
    ).get();

    return rows.map(_rowToCheckpoint).toList();
  }

  @override

  /// Persists a workflow timer via INSERT OR REPLACE.
  Future<void> saveTimer(WorkflowTimer timer) async {
    await _db.customInsert(
      'INSERT OR REPLACE INTO workflow_timers '
      '($_timerCols) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(timer.workflowTimerId),
        Variable.withString(timer.workflowExecutionId),
        Variable.withString(timer.stepName),
        Variable.withString(timer.fireAt),
        Variable.withString(timer.status.value),
        Variable.withString(timer.createdAt),
      ],
      updates: {_db.workflowTimers},
    );
  }

  @override

  /// Loads all pending timers ordered by fire time.
  Future<List<WorkflowTimer>> loadPendingTimers() async {
    final rows = await _db.customSelect(
      'SELECT $_timerCols '
      'FROM workflow_timers '
      'WHERE status = ? '
      'ORDER BY fire_at ASC',
      variables: [Variable.withString(TimerStatus.pending.value)],
      readsFrom: {_db.workflowTimers},
    ).get();

    return rows.map(_rowToTimer).toList();
  }

  @override

  /// Persists a workflow signal via INSERT OR REPLACE.
  Future<void> saveSignal(WorkflowSignal signal) async {
    await _db.customInsert(
      'INSERT OR REPLACE INTO workflow_signals '
      '($_signalCols) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable(signal.workflowSignalId),
        Variable.withString(signal.workflowExecutionId),
        Variable.withString(signal.signalName),
        Variable(signal.payload),
        Variable.withString(signal.status.value),
        Variable.withString(signal.createdAt),
      ],
      updates: {_db.workflowSignals},
    );
  }

  @override

  /// Loads pending signals for an execution, optionally filtered by name.
  Future<List<WorkflowSignal>> loadPendingSignals(
    String workflowExecutionId, {
    String? signalName,
  }) async {
    final buffer = StringBuffer(
      'SELECT $_signalCols '
      'FROM workflow_signals '
      'WHERE workflow_execution_id = ? AND status = ?',
    );
    final variables = <Variable>[
      Variable.withString(workflowExecutionId),
      Variable.withString(SignalStatus.pending.value),
    ];

    if (signalName != null) {
      buffer.write(' AND signal_name = ?');
      variables.add(Variable.withString(signalName));
    }
    buffer.write(' ORDER BY created_at ASC');

    final rows = await _db.customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {_db.workflowSignals},
    ).get();

    return rows.map(_rowToSignal).toList();
  }

  @override

  /// Loads all executions matching any of the given [statuses].
  Future<List<WorkflowExecution>> loadExecutionsByStatus(
    List<ExecutionStatus> statuses,
  ) async {
    if (statuses.isEmpty) return [];
    final rows = await _statusQuery(statuses).get();
    return rows.map(_rowToExecution).toList();
  }

  /// Watches a single execution for reactive UI updates.
  Stream<WorkflowExecution?> watchExecution(String workflowExecutionId) {
    return _db.customSelect(
      'SELECT $_executionCols '
      'FROM workflow_executions WHERE workflow_execution_id = ?',
      variables: [Variable.withString(workflowExecutionId)],
      readsFrom: {_db.workflowExecutions},
    ).watch().map((rows) {
      if (rows.isEmpty) return null;
      return _rowToExecution(rows.first);
    });
  }

  /// Watches executions matching any of the given [statuses].
  Stream<List<WorkflowExecution>> watchExecutionsByStatus(
    List<ExecutionStatus> statuses,
  ) {
    if (statuses.isEmpty) return Stream.value([]);
    return _statusQuery(statuses)
        .watch()
        .map((rows) => rows.map(_rowToExecution).toList());
  }

  /// Watches checkpoints for an execution, ordered by step index.
  Stream<List<StepCheckpoint>> watchCheckpoints(
    String workflowExecutionId,
  ) {
    return _db.customSelect(
      'SELECT $_checkpointCols '
      'FROM step_checkpoints '
      'WHERE workflow_execution_id = ? '
      'ORDER BY step_index ASC',
      variables: [Variable.withString(workflowExecutionId)],
      readsFrom: {_db.stepCheckpoints},
    ).watch().map((rows) => rows.map(_rowToCheckpoint).toList());
  }

  @override
  Future<void> deleteExecution(String workflowExecutionId) async {
    await _db.transaction(() async {
      for (final table in [
        'step_checkpoints',
        'workflow_timers',
        'workflow_signals',
        'workflow_executions',
      ]) {
        await _db.customUpdate(
          'DELETE FROM $table WHERE workflow_execution_id = ?',
          variables: [Variable.withString(workflowExecutionId)],
          updates: {
            _db.stepCheckpoints,
            _db.workflowTimers,
            _db.workflowSignals,
            _db.workflowExecutions,
          },
        );
      }
    });
  }

  @override
  Future<int> deleteCompletedBefore(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();

    final rows = await _db.customSelect(
      'SELECT workflow_execution_id FROM workflow_executions '
      'WHERE status = ? AND updated_at < ?',
      variables: [
        Variable.withString('COMPLETED'),
        Variable.withString(cutoffStr),
      ],
      readsFrom: {_db.workflowExecutions},
    ).get();

    final ids = rows
        .map((row) => row.read<String>('workflow_execution_id'))
        .toList();

    for (final id in ids) {
      await deleteExecution(id);
    }
    return ids.length;
  }

  Selectable<QueryRow> _statusQuery(List<ExecutionStatus> statuses) {
    final placeholders = List.filled(statuses.length, '?').join(', ');
    final variables =
        statuses.map((s) => Variable.withString(s.name)).toList();
    return _db.customSelect(
      'SELECT $_executionCols '
      'FROM workflow_executions '
      'WHERE status IN ($placeholders) '
      'ORDER BY created_at ASC',
      variables: variables,
      readsFrom: {_db.workflowExecutions},
    );
  }

  @override
  Future<void> saveCheckpoints(List<StepCheckpoint> checkpoints) async {
    for (final checkpoint in checkpoints) {
      await saveCheckpoint(checkpoint);
    }
  }

  @override
  Future<int> deleteOldTimers(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();
    return await _db.customUpdate(
      'DELETE FROM workflow_timers '
      'WHERE status IN (?, ?) AND created_at < ?',
      variables: [
        Variable.withString('FIRED'),
        Variable.withString('CANCELLED'),
        Variable.withString(cutoffStr),
      ],
      updates: {_db.workflowTimers},
    );
  }

  @override
  Future<int> deleteOldSignals(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();
    return await _db.customUpdate(
      'DELETE FROM workflow_signals '
      'WHERE status IN (?, ?) AND created_at < ?',
      variables: [
        Variable.withString('DELIVERED'),
        Variable.withString('EXPIRED'),
        Variable.withString(cutoffStr),
      ],
      updates: {_db.workflowSignals},
    );
  }
}
