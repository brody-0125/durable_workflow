import 'package:durable_workflow/durable_workflow.dart';
import 'package:meta/meta.dart';
import 'package:sqlite3/sqlite3.dart';

import 'migrations.dart';
import 'row_mappers.dart';
import 'transaction.dart';

/// Column lists for SELECT queries, kept in sync with schema.
const _workflowCols =
    'workflow_id, workflow_type, version, created_at';
const _executionCols =
    'workflow_execution_id, workflow_id, status, '
    'current_step, input_data, output_data, error_message, '
    'ttl_expires_at, guarantee, created_at, updated_at';
const _checkpointCols =
    'id, workflow_execution_id, step_index, '
    'step_name, status, input_data, output_data, '
    'error_message, attempt, idempotency_key, '
    'compensate_ref, started_at, completed_at';
const _timerCols =
    'workflow_timer_id, workflow_execution_id, '
    'step_name, fire_at, status, created_at';
const _signalCols =
    'workflow_signal_id, workflow_execution_id, '
    'signal_name, payload, status, created_at';

const _checkpointInsertSql = '''
  INSERT OR REPLACE INTO step_checkpoints
    (workflow_execution_id, step_index, step_name,
     status, input_data, output_data, error_message,
     attempt, idempotency_key, compensate_ref,
     started_at, completed_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
''';

List<Object?> _checkpointParams(StepCheckpoint checkpoint) => [
      checkpoint.workflowExecutionId,
      checkpoint.stepIndex,
      checkpoint.stepName,
      checkpoint.status.value,
      checkpoint.inputData,
      checkpoint.outputData,
      checkpoint.errorMessage,
      checkpoint.attempt,
      null, // idempotencyKey column preserved for schema compatibility
      checkpoint.compensateRef,
      checkpoint.startedAt,
      checkpoint.completedAt,
    ];

/// Result of a runtime schema validation check.
class SchemaValidationResult {
  final List<String> missingTables;
  final List<String> missingIndexes;
  final Map<String, String> pragmaIssues;

  SchemaValidationResult({
    required this.missingTables,
    required this.missingIndexes,
    required this.pragmaIssues,
  });

  bool get isValid =>
      missingTables.isEmpty &&
      missingIndexes.isEmpty &&
      pragmaIssues.isEmpty;
}

/// SQLite-backed implementation of [CheckpointStore].
///
/// Uses sqlite3 FFI for direct database access. Supports both
/// in-memory (`:memory:`) and file-based databases.
///
/// All write operations use `BEGIN IMMEDIATE` transactions for
/// consistency. Read operations benefit from WAL journal mode.
///
/// Prepared statements for fixed SQL queries are cached and
/// reused across calls to avoid repeated parsing overhead.
class SqliteCheckpointStore implements CheckpointStore {
  final Database _db;
  final Map<String, PreparedStatement> _stmtCache = {};

  /// Creates a store from an already-opened [Database].
  ///
  /// PRAGMAs and schema migration are applied automatically.
  SqliteCheckpointStore(this._db) {
    applyPragmas(_db);
    migrate(_db);
  }

  /// Opens an in-memory SQLite database.
  factory SqliteCheckpointStore.inMemory() {
    return SqliteCheckpointStore(sqlite3.openInMemory());
  }

  /// Opens a file-based SQLite database.
  factory SqliteCheckpointStore.file(String path) {
    return SqliteCheckpointStore(sqlite3.open(path));
  }

  void close() {
    for (final stmt in _stmtCache.values) {
      stmt.dispose();
    }
    _stmtCache.clear();
    _db.dispose();
  }

  /// Direct database access for testing only.
  @visibleForTesting
  Database get database => _db;

  /// Returns a cached [PreparedStatement] for the given [sql],
  /// creating and caching it on first use.
  PreparedStatement _cached(String sql) =>
      _stmtCache[sql] ??= _db.prepare(sql);

  /// Prepares a one-off statement for dynamic SQL, disposing
  /// it after use. Use [_cached] for fixed queries instead.
  T _withStmt<T>(String sql, T Function(PreparedStatement) use) {
    final stmt = _db.prepare(sql);
    try {
      return use(stmt);
    } finally {
      stmt.dispose();
    }
  }

  /// Validates that the expected schema (tables, indexes, PRAGMAs)
  /// is present in the database. Useful for startup diagnostics.
  SchemaValidationResult validateSchema() {
    const expectedTables = [
      'workflows',
      'workflow_executions',
      'step_checkpoints',
      'workflow_timers',
      'workflow_signals',
    ];
    const expectedIndexes = [
      'idx_wf_exec_status',
      'idx_wf_exec_workflow',
      'idx_step_cp_exec',
      'idx_wf_timer_fire',
      'idx_wf_signal_pending',
    ];
    const expectedPragmas = {
      'foreign_keys': '1',
      'synchronous': '1', // NORMAL = 1
      'cache_size': '-8000',
    };

    final masterRows = _db.select(
      "SELECT type, name FROM sqlite_master "
      "WHERE type IN ('table','index') "
      "AND name NOT LIKE 'sqlite_%'",
    );
    final tables = <String>{};
    final indexes = <String>{};
    for (final row in masterRows) {
      final type = row['type'] as String;
      final name = row['name'] as String;
      if (type == 'table') {
        tables.add(name);
      } else {
        indexes.add(name);
      }
    }

    final missingTables = expectedTables
        .where((t) => !tables.contains(t))
        .toList();
    final missingIndexes = expectedIndexes
        .where((i) => !indexes.contains(i))
        .toList();

    final pragmaIssues = <String, String>{};
    for (final entry in expectedPragmas.entries) {
      final result = _db.select('PRAGMA ${entry.key}');
      if (result.isEmpty) {
        pragmaIssues[entry.key] = 'not available';
        continue;
      }
      final actual = result.first.values.first.toString();
      if (actual != entry.value) {
        pragmaIssues[entry.key] =
            'expected ${entry.value}, got $actual';
      }
    }

    return SchemaValidationResult(
      missingTables: missingTables,
      missingIndexes: missingIndexes,
      pragmaIssues: pragmaIssues,
    );
  }

  Future<void> saveWorkflow(Workflow workflow) async {
    runInTransaction(_db, () {
      _cached('''
        INSERT OR REPLACE INTO workflows
          (workflow_id, workflow_type, version, created_at)
        VALUES (?, ?, ?, ?)
      ''').execute([
        workflow.workflowId,
        workflow.workflowType,
        workflow.version,
        workflow.createdAt,
      ]);
    });
  }

  Future<Workflow?> loadWorkflow(String workflowId) async {
    final result = _cached(
      'SELECT $_workflowCols FROM workflows WHERE workflow_id = ?',
    ).select([workflowId]);
    if (result.isEmpty) return null;
    return workflowFromRow(result.first);
  }

  @override
  Future<void> saveExecution(WorkflowExecution execution) async {
    runInTransaction(_db, () {
      _cached('''
        INSERT OR REPLACE INTO workflow_executions
          (workflow_execution_id, workflow_id, status,
           current_step, input_data, output_data,
           error_message, ttl_expires_at, guarantee,
           created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''').execute([
        execution.workflowExecutionId,
        execution.workflowId,
        execution.status.name,
        execution.currentStep,
        execution.inputData,
        execution.outputData,
        execution.errorMessage,
        execution.ttlExpiresAt,
        execution.guarantee.value,
        execution.createdAt,
        execution.updatedAt,
      ]);
    });
  }

  @override
  Future<WorkflowExecution?> loadExecution(
    String workflowExecutionId,
  ) async {
    final result = _cached(
      'SELECT $_executionCols FROM workflow_executions '
      'WHERE workflow_execution_id = ?',
    ).select([workflowExecutionId]);
    if (result.isEmpty) return null;
    return executionFromRow(result.first);
  }

  @override
  Future<List<WorkflowExecution>> loadExecutionsByStatus(
    List<ExecutionStatus> statuses,
  ) async {
    if (statuses.isEmpty) return [];

    final placeholders =
        List.filled(statuses.length, '?').join(', ');
    final params = statuses.map((s) => s.name).toList();

    return _withStmt(
      'SELECT $_executionCols FROM workflow_executions '
      'WHERE status IN ($placeholders) '
      'ORDER BY created_at ASC',
      (stmt) => stmt.select(params).map(executionFromRow).toList(),
    );
  }

  @override
  Future<void> saveCheckpoint(StepCheckpoint checkpoint) async {
    runInTransaction(_db, () {
      _cached(_checkpointInsertSql)
          .execute(_checkpointParams(checkpoint));
    });
  }

  /// Saves multiple checkpoints in a single transaction.
  ///
  /// More efficient than calling [saveCheckpoint] repeatedly,
  /// as it reuses a single prepared statement and wraps all
  /// inserts in one transaction.
  @override
  Future<void> saveCheckpoints(List<StepCheckpoint> checkpoints) async {
    if (checkpoints.isEmpty) return;

    runInTransaction(_db, () {
      final stmt = _cached(_checkpointInsertSql);
      for (final checkpoint in checkpoints) {
        stmt.execute(_checkpointParams(checkpoint));
      }
    });
  }

  @override
  Future<List<StepCheckpoint>> loadCheckpoints(
    String workflowExecutionId,
  ) async {
    return _cached(
      'SELECT $_checkpointCols FROM step_checkpoints '
      'WHERE workflow_execution_id = ? '
      'ORDER BY step_index ASC',
    ).select([workflowExecutionId])
        .map(checkpointFromRow)
        .toList();
  }

  @override
  Future<void> saveTimer(WorkflowTimer timer) async {
    runInTransaction(_db, () {
      _cached('''
        INSERT OR REPLACE INTO workflow_timers
          (workflow_timer_id, workflow_execution_id,
           step_name, fire_at, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''').execute([
        timer.workflowTimerId,
        timer.workflowExecutionId,
        timer.stepName,
        timer.fireAt,
        timer.status.value,
        timer.createdAt,
      ]);
    });
  }

  @override
  Future<List<WorkflowTimer>> loadPendingTimers() async {
    return _cached(
      'SELECT $_timerCols FROM workflow_timers '
      'WHERE status = ? ORDER BY fire_at ASC',
    ).select([TimerStatus.pending.value])
        .map(timerFromRow)
        .toList();
  }

  @override
  Future<void> saveSignal(WorkflowSignal signal) async {
    runInTransaction(_db, () {
      _cached('''
        INSERT OR REPLACE INTO workflow_signals
          (workflow_signal_id, workflow_execution_id,
           signal_name, payload, status, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
      ''').execute([
        signal.workflowSignalId,
        signal.workflowExecutionId,
        signal.signalName,
        signal.payload,
        signal.status.value,
        signal.createdAt,
      ]);
    });
  }

  @override
  Future<List<WorkflowSignal>> loadPendingSignals(
    String workflowExecutionId, {
    String? signalName,
  }) async {
    final buffer = StringBuffer(
      'SELECT $_signalCols FROM workflow_signals '
      'WHERE workflow_execution_id = ? AND status = ?',
    );
    final params = <Object?>[
      workflowExecutionId,
      SignalStatus.pending.value,
    ];

    if (signalName != null) {
      buffer.write(' AND signal_name = ?');
      params.add(signalName);
    }
    buffer.write(' ORDER BY created_at ASC');

    return _withStmt(
      buffer.toString(),
      (stmt) =>
          stmt.select(params).map(signalFromRow).toList(),
    );
  }

  @override
  Future<void> deleteExecution(String workflowExecutionId) async {
    runInTransaction(_db, () {
      for (final table in [
        'step_checkpoints',
        'workflow_timers',
        'workflow_signals',
        'workflow_executions',
      ]) {
        _withStmt(
          'DELETE FROM $table WHERE workflow_execution_id = ?',
          (stmt) => stmt.execute([workflowExecutionId]),
        );
      }
    });
  }

  @override
  Future<int> deleteCompletedBefore(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();

    // Find completed executions before cutoff
    final ids = _withStmt(
      'SELECT workflow_execution_id FROM workflow_executions '
      'WHERE status = ? AND updated_at < ?',
      (stmt) => stmt
          .select(['COMPLETED', cutoffStr])
          .map((row) => row['workflow_execution_id'] as String)
          .toList(),
    );

    for (final id in ids) {
      await deleteExecution(id);
    }
    return ids.length;
  }

  @override
  Future<int> deleteOldTimers(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();
    return runInTransaction(_db, () {
      _db.execute(
        'DELETE FROM workflow_timers '
        'WHERE status IN (?, ?) AND created_at < ?',
        ['FIRED', 'CANCELLED', cutoffStr],
      );
      return _db.updatedRows;
    });
  }

  @override
  Future<int> deleteOldSignals(DateTime cutoff) async {
    final cutoffStr = cutoff.toUtc().toIso8601String();
    return runInTransaction(_db, () {
      _db.execute(
        'DELETE FROM workflow_signals '
        'WHERE status IN (?, ?) AND created_at < ?',
        ['DELIVERED', 'EXPIRED', cutoffStr],
      );
      return _db.updatedRows;
    });
  }
}
